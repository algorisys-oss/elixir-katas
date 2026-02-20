defmodule ElixirKatasWeb.Kata20SorterLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    items = [
      %{id: 1, name: "Alice", age: 28, role: "Admin"},
      %{id: 2, name: "Bob", age: 34, role: "User"},
      %{id: 3, name: "Charlie", age: 22, role: "Editor"},
      %{id: 4, name: "Diana", age: 28, role: "Admin"},
      %{id: 5, name: "Eve", age: 45, role: "User"}
    ]

    {:ok, 
     socket
     |> assign(active_tab: "notes")
     
     
     |> assign(items: items)
     |> assign(sort_by: :id)
     |> assign(sort_order: :asc)}
  end

  def render(assigns) do
    ~H"""
    
      <div class="flex flex-col items-center p-8 gap-8">
        <div class="overflow-x-auto w-full max-w-lg">
          <table class="table w-full">
            <thead>
              <tr class="bg-base-200">
                <th 
                  class="cursor-pointer hover:bg-base-300 transition-colors"
                  phx-click="sort" 
                  phx-target={@myself}
                  phx-value-field="id"
                >
                  ID {sort_indicator(@sort_by, @sort_order, :id)}
                </th>
                <th 
                  class="cursor-pointer hover:bg-base-300 transition-colors"
                  phx-click="sort" 
                  phx-target={@myself}
                  phx-value-field="name"
                >
                  Name {sort_indicator(@sort_by, @sort_order, :name)}
                </th>
                <th 
                  class="cursor-pointer hover:bg-base-300 transition-colors"
                  phx-click="sort" 
                  phx-target={@myself}
                  phx-value-field="age"
                >
                  Age {sort_indicator(@sort_by, @sort_order, :age)}
                </th>
                <th 
                  class="cursor-pointer hover:bg-base-300 transition-colors"
                  phx-click="sort" 
                  phx-target={@myself}
                  phx-value-field="role"
                >
                  Role {sort_indicator(@sort_by, @sort_order, :role)}
                </th>
              </tr>
            </thead>
            <tbody>
              <%= for item <- sorted_items(@items, @sort_by, @sort_order) do %>
                <tr class="hover">
                  <th>{item.id}</th>
                  <td>{item.name}</td>
                  <td>{item.age}</td>
                  <td>{item.role}</td>
                </tr>
              <% end %>
            </tbody>
          </table>
          <div class="mt-4 text-xs text-center text-gray-500">
            Click headers to sort. Click again to toggle order.
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("sort", %{"field" => field_str}, socket) do
    field = String.to_existing_atom(field_str)
    
    new_order = 
      if socket.assigns.sort_by == field and socket.assigns.sort_order == :asc do
        :desc
      else
        :asc
      end

    {:noreply, assign(socket, sort_by: field, sort_order: new_order)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    if tab in ["interactive", "source", "notes"] do
       {:noreply, assign(socket, active_tab: tab)}
    else 
       {:noreply, socket}
    end
  end

  defp sorted_items(items, field, order) do
    Enum.sort_by(items, fn item -> Map.get(item, field) end, order)
  end

  defp sort_indicator(current_field, current_order, target_field) do
    if current_field == target_field do
      if current_order == :asc, do: "▲", else: "▼"
    else
      ""
    end
  end
end
