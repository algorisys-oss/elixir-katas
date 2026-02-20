defmodule ElixirKatasWeb.Kata25TreeLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    # Simulating a nested structure
    tree_data = [
      %{
        id: 1, 
        label: "Root Folder", 
        children: [
          %{id: 11, label: "Documents", children: [
             %{id: 111, label: "Resume.pdf", children: []},
             %{id: 112, label: "Budget.xlsx", children: []}
          ]},
          %{id: 12, label: "Images", children: [
             %{id: 121, label: "Vacation", children: [
                %{id: 1211, label: "Beach.png", children: []},
                %{id: 1212, label: "Mountain.jpg", children: []}
             ]},
             %{id: 122, label: "Profile.png", children: []}
          ]}
        ]
      }
    ]

    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:tree, tree_data)
      |> assign(:expanded_ids, MapSet.new([1, 12])) # Start with some expanded

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-lg mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Recursive rendering of nested structures
        </div>

        <div class="mt-6 p-4 bg-white border rounded-lg shadow-sm">
          <ul class="space-y-1">
            <%= for node <- @tree do %>
              <.tree_node node={node} expanded_ids={@expanded_ids} myself={@myself} />
            <% end %>
          </ul>
        </div>

         <div class="mt-12 bg-gray-50 p-4 rounded-lg border text-sm text-gray-600">
          <h3 class="font-bold mb-2">How it works:</h3>
          <p>
            We use a functional component <code>.tree_node</code> that recursively calls itself if the node has children and is expanded.
            The state <code>expanded_ids</code> tracks which folders are open.
          </p>
          <p class="mt-2 text-xs text-blue-600 bg-blue-50 p-2 rounded">
            <strong>Note:</strong> We must pass <code>myself={@myself}</code> to the recursive component so that the toggle buttons can target the parent LiveComponent correctly.
          </p>
        </div>
      </div>
    
    """
  end
  
  # Recursive component
  attr :node, :map, required: true
  attr :expanded_ids, MapSet, required: true
  
  attr :myself, :any, required: true
  
  def tree_node(assigns) do
    ~H"""
    <li>
      <div class="flex items-center gap-2 group">
        <%= if length(@node.children) > 0 do %>
            <button 
              phx-click="toggle" phx-target={@myself} 
              phx-value-id={@node.id}
              class="p-1 rounded hover:bg-gray-100 text-gray-500"
            >
              <%= if MapSet.member?(@expanded_ids, @node.id) do %>
                <.icon name="hero-chevron-down" class="w-4 h-4" />
              <% else %>
                <.icon name="hero-chevron-right" class="w-4 h-4" />
              <% end %>
            </button>
        <% else %>
            <span class="w-6"></span> <!-- Indent spacer for leaves -->
        <% end %>
        
        <span class={"text-sm " <> if(length(@node.children) > 0, do: "font-medium text-gray-800", else: "text-gray-600")}>
           <%= if length(@node.children) > 0 do %>
             <.icon name="hero-folder" class="w-4 h-4 text-yellow-500 mr-1 inline-block" />
           <% else %>
             <.icon name="hero-document" class="w-4 h-4 text-gray-400 mr-1 inline-block" />
           <% end %>
           <%= @node.label %>
        </span>
      </div>
      
      <%= if MapSet.member?(@expanded_ids, @node.id) and length(@node.children) > 0 do %>
        <ul class="ml-6 mt-1 border-l pl-2 space-y-1">
          <%= for child <- @node.children do %>
            <.tree_node node={child} expanded_ids={@expanded_ids} myself={@myself} />
          <% end %>
        </ul>
      <% end %>
    </li>
    """
  end

  def handle_event("toggle", %{"id" => id}, socket) do
    id = String.to_integer(id)
    expanded = socket.assigns.expanded_ids
    
    new_expanded =
      if MapSet.member?(expanded, id) do
        MapSet.delete(expanded, id)
      else
        MapSet.put(expanded, id)
      end

    {:noreply, assign(socket, :expanded_ids, new_expanded)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
