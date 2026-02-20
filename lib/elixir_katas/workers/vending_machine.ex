defmodule ElixirKatas.Workers.VendingMachine do
  @moduledoc """
  A state machine simulating a Vending Machine using :gen_statem.
  
  Demonstrates:
  - Complex state transitions with :gen_statem
  - Data persistence across transitions
  - PubSub integration for real-time UI updates
  - Timeout and state-enter events
  """
  
  @behaviour :gen_statem
  
  @topic "vending_machine:updates"
  @idle_timeout 15_000 # 15 seconds to return change if idle
  
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  # API
  
  def start_link(_opts) do
    :gen_statem.start_link({:local, __MODULE__}, __MODULE__, [], [])
  end
  
  def insert_coin(amount) when amount > 0 do
    :gen_statem.cast(__MODULE__, {:insert_coin, amount})
  end
  
  def select_item(item_id) do
    :gen_statem.cast(__MODULE__, {:select_item, item_id})
  end
  
  def cancel() do
    :gen_statem.cast(__MODULE__, :cancel)
  end
  
  def get_status() do
    :gen_statem.call(__MODULE__, :get_status)
  end

  # Callbacks

  @impl true
  def callback_mode, do: [:handle_event_function, :state_enter]

  @impl true
  def init(_) do
    data = %{
      balance: 0,
      items: %{
        1 => %{name: "Soda", price: 100, stock: 5},
        2 => %{name: "Chips", price: 75, stock: 10},
        3 => %{name: "Candy", price: 50, stock: 20}
      },
      message: "Welcome! Insert coins."
    }
    {:ok, :idle, data}
  end

  # State: IDLE
  
  @impl true
  def handle_event(:enter, _old_state, :idle, data) do
    broadcast_update(:idle, %{data | message: "Welcome! Insert coins."})
    :keep_state_and_data
  end

  def handle_event(:cast, {:insert_coin, amount}, :idle, data) do
    new_data = %{data | balance: data.balance + amount, message: "Balance: #{data.balance + amount}"}
    {:next_state, :ready, new_data}
  end

  # State: READY

  @impl true
  def handle_event(:enter, _old_state, :ready, data) do
    broadcast_update(:ready, data)
    # Set a timeout to return change if user walks away
    {:keep_state, data, [{:state_timeout, @idle_timeout, :cancel}]}
  end

  def handle_event(:cast, {:insert_coin, amount}, :ready, data) do
    new_data = %{data | balance: data.balance + amount, message: "Balance: #{data.balance + amount}"}
    {:keep_state, new_data, [{:state_timeout, @idle_timeout, :cancel}]}
  end

  def handle_event(:cast, {:select_item, item_id}, :ready, data) do
    case Map.get(data.items, item_id) do
      nil ->
        {:keep_state, %{data | message: "Invalid selection."}, [{:state_timeout, @idle_timeout, :cancel}]}
        
      %{stock: 0} ->
        {:keep_state, %{data | message: "Out of stock!"}, [{:state_timeout, @idle_timeout, :cancel}]}
        
      %{price: price} when data.balance >= price ->
        new_data = %{data | balance: data.balance - price}
        {:next_state, :dispensing, new_data, [{:next_event, :internal, {:dispense, item_id}}]}
        
      %{price: price} ->
        {:keep_state, %{data | message: "Need #{price - data.balance} more."}, [{:state_timeout, @idle_timeout, :cancel}]}
    end
  end

  def handle_event(:state_timeout, :cancel, :ready, data) do
    message = if data.balance > 0, do: "Timeout! Returning #{data.balance}", else: "Ready."
    {:next_state, :idle, %{data | balance: 0, message: message}}
  end

  def handle_event(:cast, :cancel, :ready, data) do
    {:next_state, :idle, %{data | balance: 0, message: "Cancelled. Returned #{data.balance}"}}
  end

  # State: DISPENSING

  @impl true
  def handle_event(:enter, _old_state, :dispensing, data) do
    broadcast_update(:dispensing, data)
    :keep_state_and_data
  end

  def handle_event(:internal, {:dispense, item_id}, :dispensing, data) do
    # Simulate dispensing time
    Process.sleep(1000)
    
    new_data = update_in(data, [:items, item_id, :stock], &(&1 - 1))
    item_name = data.items[item_id].name
    
    {:next_state, :idle, %{new_data | message: "Enjoy your #{item_name}!"}}
  end

  # Common Events (applicable in any state)

  def handle_event({:call, from}, :get_status, state, data) do
    {:keep_state_and_data, [{:reply, from, {state, data}}]}
  end

  # Helper Functions

  defp broadcast_update(state, data) do
    Phoenix.PubSub.broadcast(ElixirKatas.PubSub, @topic, {:vending_machine_updated, state, data})
  end
end
