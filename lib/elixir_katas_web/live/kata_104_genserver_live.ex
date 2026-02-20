defmodule ElixirKatasWeb.Kata104GenserverLive do
  use ElixirKatasWeb, :live_component
  alias ElixirKatas.Workers.JobQueue

  @topic "job_queue:updates"

  def update(%{info_msg: msg}, socket) do
    {:noreply, socket} = handle_info(msg, socket)
    {:ok, socket}
  end

  def update(assigns, socket) do
    if socket.assigns[:__initialized__] do
      {:ok, assign(socket, assigns)}
    else
      socket = assign(socket, assigns)
      socket = assign(socket, :__initialized__, true)

      # Subscribe to job queue updates
      if connected?(socket) do
        Phoenix.PubSub.subscribe(ElixirKatas.PubSub, @topic)
      end

      # Get initial queue status
      status = JobQueue.get_queue_status()

      socket =
        socket
        |> assign(active_tab: "notes")
        |> assign(:job_name, "")
        |> assign(:job_duration, "3")
        |> assign(:jobs, status.jobs)
        |> assign(:stats, status.stats)

      {:ok, socket}
    end
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-4xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Background job processing with GenServer. Demonstrates process isolation, state management, and real-time updates.
        </div>

        <!-- Stats Dashboard -->
        <div class="grid grid-cols-2 md:grid-cols-5 gap-4 mb-6">
          <div class="bg-white p-4 rounded-lg shadow-sm border text-center">
            <div class="text-2xl font-bold text-gray-900"><%= @stats.total %></div>
            <div class="text-xs text-gray-500">Total Jobs</div>
          </div>
          <div class="bg-white p-4 rounded-lg shadow-sm border text-center">
            <div class="text-2xl font-bold text-gray-400"><%= @stats.pending %></div>
            <div class="text-xs text-gray-500">Pending</div>
          </div>
          <div class="bg-white p-4 rounded-lg shadow-sm border text-center">
            <div class="text-2xl font-bold text-blue-600"><%= @stats.processing %></div>
            <div class="text-xs text-gray-500">Processing</div>
          </div>
          <div class="bg-white p-4 rounded-lg shadow-sm border text-center">
            <div class="text-2xl font-bold text-green-600"><%= @stats.completed %></div>
            <div class="text-xs text-gray-500">Completed</div>
          </div>
          <div class="bg-white p-4 rounded-lg shadow-sm border text-center">
            <div class="text-2xl font-bold text-red-600"><%= @stats.failed + @stats.cancelled %></div>
            <div class="text-xs text-gray-500">Failed/Cancelled</div>
          </div>
        </div>

        <!-- Add Job Form -->
        <div class="bg-white p-6 rounded-lg shadow-sm border mb-6">
          <h3 class="text-lg font-medium mb-4">Submit New Job</h3>
          <form phx-submit="add_job" phx-target={@myself} class="flex gap-4">
            <div class="flex-1">
              <input 
                type="text" 
                name="job_name" 
                value={@job_name}
                phx-change="update_job_name"
                phx-target={@myself}
                placeholder="Job name (e.g., Process Image #1)"
                class="w-full px-4 py-2 border rounded"
                required
              />
            </div>
            <div class="w-32">
              <input 
                type="number" 
                name="duration" 
                value={@job_duration}
                phx-change="update_duration"
                phx-target={@myself}
                placeholder="Duration"
                min="1"
                max="30"
                class="w-full px-4 py-2 border rounded"
                required
              />
            </div>
            <button type="submit" class="px-6 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700 whitespace-nowrap">
              Add Job
            </button>
          </form>
          <p class="text-xs text-gray-500 mt-2">Duration: number of seconds (1-30)</p>
        </div>

        <!-- Actions -->
        <div class="flex gap-2 mb-4">
          <button 
            phx-click="clear_completed" 
            phx-target={@myself}
            class="px-4 py-2 bg-gray-100 text-gray-700 rounded hover:bg-gray-200 text-sm"
          >
            Clear Completed
          </button>
        </div>

        <!-- Job Queue -->
        <div class="bg-white rounded-lg shadow-sm border">
          <div class="border-b p-4 bg-gray-50">
            <h3 class="text-lg font-medium">Job Queue</h3>
          </div>
          
          <div class="divide-y max-h-96 overflow-y-auto">
            <%= if Enum.empty?(@jobs) do %>
              <div class="p-8 text-center text-gray-400">
                <div class="text-4xl mb-2">📋</div>
                <div>No jobs in queue. Add a job to get started!</div>
              </div>
            <% else %>
              <%= for job <- Enum.sort_by(@jobs, & &1.id, :desc) do %>
                <div class="p-4 hover:bg-gray-50">
                  <div class="flex items-start justify-between">
                    <div class="flex-1">
                      <div class="flex items-center gap-3 mb-2">
                        <span class={[
                          "px-2 py-1 text-xs font-medium rounded",
                          status_class(job.status)
                        ]}>
                          <%= format_status(job.status) %>
                        </span>
                        <span class="font-medium text-gray-900">
                          #<%= job.id %> - <%= job.name %>
                        </span>
                      </div>
                      
                      <%= if job.status == :processing do %>
                        <div class="mb-2">
                          <div class="flex items-center justify-between text-xs text-gray-600 mb-1">
                            <span>Progress</span>
                            <span><%= job.progress %>%</span>
                          </div>
                          <div class="w-full bg-gray-200 rounded-full h-2">
                            <div 
                              class="bg-blue-600 h-2 rounded-full transition-all duration-300"
                              style={"width: #{job.progress}%"}
                            >
                            </div>
                          </div>
                        </div>
                      <% end %>
                      
                      <div class="text-xs text-gray-500">
                        Duration: <%= job.duration %>s
                        <%= if job.started_at do %>
                          | Started: <%= format_time(job.started_at) %>
                        <% end %>
                        <%= if job.completed_at do %>
                          | Completed: <%= format_time(job.completed_at) %>
                        <% end %>
                      </div>
                    </div>
                    
                    <%= if job.status in [:pending, :processing] do %>
                      <button 
                        phx-click="cancel_job" 
                        phx-value-id={job.id}
                        phx-target={@myself}
                        class="ml-4 px-3 py-1 text-xs bg-red-100 text-red-700 rounded hover:bg-red-200"
                      >
                        Cancel
                      </button>
                    <% end %>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>

        <div class="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
          <div class="flex items-start gap-2">
            <div class="text-blue-600 font-bold">💡</div>
            <div class="text-sm text-blue-900">
              <strong>Try this:</strong> Open this kata in multiple browser tabs and add jobs. Watch how all tabs update in real-time via PubSub!
            </div>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("update_job_name", %{"job_name" => name}, socket) do
    {:noreply, assign(socket, :job_name, name)}
  end

  def handle_event("update_duration", %{"duration" => duration}, socket) do
    {:noreply, assign(socket, :job_duration, duration)}
  end

  def handle_event("add_job", %{"job_name" => name, "duration" => duration}, socket) do
    duration_int = String.to_integer(duration)
    {:ok, _job_id} = JobQueue.add_job(name, duration_int)
    
    {:noreply, assign(socket, job_name: "", job_duration: "3")}
  end

  def handle_event("cancel_job", %{"id" => id}, socket) do
    JobQueue.cancel_job(String.to_integer(id))
    {:noreply, socket}
  end

  def handle_event("clear_completed", _, socket) do
    JobQueue.clear_completed()
    {:noreply, socket}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_info({:queue_updated, status}, socket) do
    {:noreply, assign(socket, jobs: status.jobs, stats: status.stats)}
  end

  # Helper functions

  defp status_class(:pending), do: "bg-gray-100 text-gray-700"
  defp status_class(:processing), do: "bg-blue-100 text-blue-700"
  defp status_class(:completed), do: "bg-green-100 text-green-700"
  defp status_class(:failed), do: "bg-red-100 text-red-700"
  defp status_class(:cancelled), do: "bg-orange-100 text-orange-700"

  defp format_status(status) do
    status |> Atom.to_string() |> String.upcase()
  end

  defp format_time(datetime) do
    Calendar.strftime(datetime, "%H:%M:%S")
  end
end
