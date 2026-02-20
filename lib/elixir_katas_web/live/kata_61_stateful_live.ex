defmodule ElixirKatasWeb.Kata61StatefulLive do
  use ElixirKatasWeb, :live_component

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
      socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:count, 0)
      {:ok, socket}
    end

  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Interactive stateful component demonstration.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">

          <div class="space-y-4">
            <div class="text-center">
              <div class="text-4xl font-bold text-indigo-600"><%= @count %></div>
              <div class="text-sm text-gray-500">Counter (LiveComponent state)</div>
            </div>
            <div class="flex gap-2 justify-center">
              <button phx-click="decrement" phx-target={@myself} class="px-4 py-2 bg-gray-200 rounded">-</button>
              <button phx-click="increment" phx-target={@myself} class="px-4 py-2 bg-indigo-600 text-white rounded">+</button>
            </div>
          </div>
    
        </div>
      </div>
    
    """
  end

  def handle_event("increment", _, socket), do: {:noreply, update(socket, :count, &(&1 + 1))}
  def handle_event("decrement", _, socket), do: {:noreply, update(socket, :count, &(&1 - 1))}
  def handle_event("add_item", _, socket), do: {:noreply, update(socket, :items, &(&1 ++ ["New item"]))}
  def handle_event("remove_item", %{"idx" => idx}, socket) do
    idx = String.to_integer(idx)
    {:noreply, update(socket, :items, &List.delete_at(&1, idx))}
  end
  def handle_event("update_message", %{"value" => val}, socket), do: {:noreply, assign(socket, :message, val)}
  def handle_event("self_click", _, socket), do: {:noreply, update(socket, :clicks, &(&1 + 1))}
  def handle_event("send_to_parent", _, socket), do: {:noreply, assign(socket, :child_message, "Hello from child!")}
  def handle_event("sibling_a_send", _, socket), do: {:noreply, assign(socket, :sibling_data, "Data from A")}
  def handle_event("load_component", _, socket), do: {:noreply, assign(socket, :loaded, true)}
  def handle_event("submit_form", params, socket), do: {:noreply, assign(socket, :form_data, params)}
  def handle_event("create_item", _, socket), do: {:noreply, update(socket, :items, &(&1 ++ ["New item"]))}
  def handle_event("delete_item", %{"idx" => idx}, socket) do
    idx = String.to_integer(idx)
    {:noreply, update(socket, :items, &List.delete_at(&1, idx))}
  end
  def handle_event("save_optimistic", _, socket) do
    socket = assign(socket, :saving, true)
    Process.send_after(self(), :save_complete, 1000)
    {:noreply, socket}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_info(:save_complete, socket) do
    {:noreply, assign(socket, :saving, false)}
  end
end
