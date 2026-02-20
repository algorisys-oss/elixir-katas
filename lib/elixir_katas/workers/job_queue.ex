defmodule ElixirKatas.Workers.JobQueue do
  @moduledoc """
  A GenServer that manages a queue of background jobs.
  
  Demonstrates:
  - GenServer state management
  - Background job processing
  - PubSub for real-time updates
  - Process isolation and supervision
  """
  use GenServer
  require Logger

  @topic "job_queue:updates"

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Adds a new job to the queue.
  """
  def add_job(name, duration_seconds) do
    GenServer.call(__MODULE__, {:add_job, name, duration_seconds})
  end

  @doc """
  Returns the current queue status.
  """
  def get_queue_status do
    GenServer.call(__MODULE__, :get_queue_status)
  end

  @doc """
  Cancels a pending or processing job.
  """
  def cancel_job(job_id) do
    GenServer.call(__MODULE__, {:cancel_job, job_id})
  end

  @doc """
  Clears all completed jobs from the queue.
  """
  def clear_completed do
    GenServer.call(__MODULE__, :clear_completed)
  end

  # Server Callbacks

  @impl true
  def init(_) do
    state = %{
      jobs: %{},
      queue: [],
      processing: nil,
      next_id: 1
    }
    
    {:ok, state}
  end

  @impl true
  def handle_call({:add_job, name, duration}, _from, state) do
    job_id = state.next_id
    
    job = %{
      id: job_id,
      name: name,
      duration: duration,
      status: :pending,
      progress: 0,
      started_at: nil,
      completed_at: nil,
      created_at: DateTime.utc_now()
    }
    
    new_state = 
      state
      |> put_in([:jobs, job_id], job)
      |> update_in([:queue], &(&1 ++ [job_id]))
      |> Map.put(:next_id, job_id + 1)
    
    # Broadcast update
    broadcast_update(new_state)
    
    # Try to process next job if not currently processing
    new_state = maybe_process_next(new_state)
    
    {:reply, {:ok, job_id}, new_state}
  end

  @impl true
  def handle_call(:get_queue_status, _from, state) do
    status = %{
      jobs: Map.values(state.jobs),
      stats: %{
        total: map_size(state.jobs),
        pending: count_by_status(state.jobs, :pending),
        processing: count_by_status(state.jobs, :processing),
        completed: count_by_status(state.jobs, :completed),
        failed: count_by_status(state.jobs, :failed),
        cancelled: count_by_status(state.jobs, :cancelled)
      }
    }
    
    {:reply, status, state}
  end

  @impl true
  def handle_call({:cancel_job, job_id}, _from, state) do
    case get_in(state, [:jobs, job_id]) do
      nil ->
        {:reply, {:error, :not_found}, state}
      
      job when job.status in [:pending, :processing] ->
        new_state = 
          state
          |> put_in([:jobs, job_id, :status], :cancelled)
          |> update_in([:queue], &List.delete(&1, job_id))
        
        # If we cancelled the processing job, start next one
        new_state = 
          if state.processing == job_id do
            new_state
            |> Map.put(:processing, nil)
            |> maybe_process_next()
          else
            new_state
          end
        
        broadcast_update(new_state)
        {:reply, :ok, new_state}
      
      _job ->
        {:reply, {:error, :already_finished}, state}
    end
  end

  @impl true
  def handle_call(:clear_completed, _from, state) do
    completed_ids = 
      state.jobs
      |> Enum.filter(fn {_id, job} -> job.status in [:completed, :failed, :cancelled] end)
      |> Enum.map(fn {id, _job} -> id end)
    
    new_state = update_in(state, [:jobs], &Map.drop(&1, completed_ids))
    
    broadcast_update(new_state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_info({:job_progress, job_id, progress}, state) do
    new_state = put_in(state, [:jobs, job_id, :progress], progress)
    broadcast_update(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_info({:job_complete, job_id, result}, state) do
    {status, new_state} = 
      case result do
        :ok ->
          {:completed, 
           state
           |> put_in([:jobs, job_id, :status], :completed)
           |> put_in([:jobs, job_id, :progress], 100)
           |> put_in([:jobs, job_id, :completed_at], DateTime.utc_now())}
        
        {:error, _reason} ->
          {:failed,
           state
           |> put_in([:jobs, job_id, :status], :failed)
           |> put_in([:jobs, job_id, :completed_at], DateTime.utc_now())}
      end
    
    # Clear processing and start next job
    new_state = 
      new_state
      |> Map.put(:processing, nil)
      |> maybe_process_next()
    
    broadcast_update(new_state)
    Logger.info("Job #{job_id} finished with status: #{status}")
    
    {:noreply, new_state}
  end

  # Private Functions

  defp maybe_process_next(%{processing: nil, queue: [next_id | rest]} = state) do
    job = state.jobs[next_id]
    
    # Only process if job is still pending (not cancelled)
    if job && job.status == :pending do
      # Mark as processing
      new_state = 
        state
        |> put_in([:jobs, next_id, :status], :processing)
        |> put_in([:jobs, next_id, :started_at], DateTime.utc_now())
        |> Map.put(:processing, next_id)
        |> Map.put(:queue, rest)
      
      # Start async job
      spawn_job_worker(next_id, job.duration)
      
      broadcast_update(new_state)
      new_state
    else
      # Skip this job and try next
      maybe_process_next(%{state | queue: rest})
    end
  end

  defp maybe_process_next(state), do: state

  defp spawn_job_worker(job_id, duration) do
    parent = self()
    
    spawn(fn ->
      # Simulate job progress
      steps = 10
      step_duration = trunc(duration * 1000 / steps)
      
      Enum.each(1..steps, fn step ->
        Process.sleep(step_duration)
        progress = trunc(step * 100 / steps)
        send(parent, {:job_progress, job_id, progress})
      end)
      
      # Simulate potential failure (5% chance)
      result = if :rand.uniform(100) > 95, do: {:error, :random_failure}, else: :ok
      
      send(parent, {:job_complete, job_id, result})
    end)
  end

  defp count_by_status(jobs, status) do
    jobs
    |> Enum.count(fn {_id, job} -> job.status == status end)
  end

  defp broadcast_update(state) do
    status = %{
      jobs: Map.values(state.jobs),
      stats: %{
        total: map_size(state.jobs),
        pending: count_by_status(state.jobs, :pending),
        processing: count_by_status(state.jobs, :processing),
        completed: count_by_status(state.jobs, :completed),
        failed: count_by_status(state.jobs, :failed),
        cancelled: count_by_status(state.jobs, :cancelled)
      }
    }
    
    Phoenix.PubSub.broadcast(ElixirKatas.PubSub, @topic, {:queue_updated, status})
  end
end
