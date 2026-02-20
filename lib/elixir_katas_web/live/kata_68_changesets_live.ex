defmodule ElixirKatasWeb.Kata68ChangesetsLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:form_data, %{"name" => "", "email" => "", "age" => ""})
      |> assign(:errors, %{})
      |> assign(:submitted_data, nil)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Schema-less changesets for form validation without database schemas.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <h3 class="text-lg font-medium mb-4">User Registration Form</h3>
          
          <form phx-submit="submit_form" phx-target={@myself} class="space-y-4">
            <div>
              <label class="block text-sm font-medium mb-1">Name *</label>
              <input 
                type="text" 
                name="name" 
                value={@form_data["name"]}
                class={"w-full px-4 py-2 border rounded " <> if @errors["name"], do: "border-red-500", else: "border-gray-300"}
                placeholder="Enter your name"
              />
              <%= if @errors["name"] do %>
                <p class="text-red-500 text-sm mt-1"><%= @errors["name"] %></p>
              <% end %>
            </div>

            <div>
              <label class="block text-sm font-medium mb-1">Email *</label>
              <input 
                type="email" 
                name="email" 
                value={@form_data["email"]}
                class={"w-full px-4 py-2 border rounded " <> if @errors["email"], do: "border-red-500", else: "border-gray-300"}
                placeholder="your@email.com"
              />
              <%= if @errors["email"] do %>
                <p class="text-red-500 text-sm mt-1"><%= @errors["email"] %></p>
              <% end %>
            </div>

            <div>
              <label class="block text-sm font-medium mb-1">Age *</label>
              <input 
                type="number" 
                name="age" 
                value={@form_data["age"]}
                class={"w-full px-4 py-2 border rounded " <> if @errors["age"], do: "border-red-500", else: "border-gray-300"}
                placeholder="Must be 18 or older"
              />
              <%= if @errors["age"] do %>
                <p class="text-red-500 text-sm mt-1"><%= @errors["age"] %></p>
              <% end %>
            </div>

            <button 
              type="submit" 
              class="w-full px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700"
            >
              Submit
            </button>
          </form>

          <%= if @submitted_data do %>
            <div class="mt-6 p-4 bg-green-50 border border-green-200 rounded">
              <h4 class="font-medium text-green-800 mb-2">✓ Form Submitted Successfully!</h4>
              <div class="text-sm text-gray-700">
                <p><strong>Name:</strong> <%= @submitted_data["name"] %></p>
                <p><strong>Email:</strong> <%= @submitted_data["email"] %></p>
                <p><strong>Age:</strong> <%= @submitted_data["age"] %></p>
              </div>
            </div>
          <% end %>

          <div class="mt-6 p-4 bg-blue-50 border border-blue-200 rounded text-sm">
            <h4 class="font-medium text-blue-800 mb-2">Changeset Validation Rules:</h4>
            <ul class="list-disc list-inside text-gray-700 space-y-1">
              <li>Name: Required, minimum 2 characters</li>
              <li>Email: Required, must be valid email format</li>
              <li>Age: Required, must be 18 or older</li>
            </ul>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("submit_form", params, socket) do
    # Simulate changeset validation
    errors = validate_form(params)
    
    if Enum.empty?(errors) do
      # Valid - show success
      {:noreply, 
       socket
       |> assign(:submitted_data, params)
       |> assign(:errors, %{})
       |> assign(:form_data, params)}
    else
      # Invalid - show errors
      {:noreply, 
       socket
       |> assign(:errors, errors)
       |> assign(:submitted_data, nil)
       |> assign(:form_data, params)}
    end
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  # Simulate Ecto.Changeset validation
  defp validate_form(params) do
    errors = %{}
    
    # Validate name
    errors = if is_nil(params["name"]) or String.trim(params["name"]) == "" do
      Map.put(errors, "name", "Name is required")
    else
      if String.length(String.trim(params["name"])) < 2 do
        Map.put(errors, "name", "Name must be at least 2 characters")
      else
        errors
      end
    end
    
    # Validate email
    errors = if is_nil(params["email"]) or String.trim(params["email"]) == "" do
      Map.put(errors, "email", "Email is required")
    else
      if String.contains?(params["email"], "@") do
        errors
      else
        Map.put(errors, "email", "Email must be a valid email address")
      end
    end
    
    # Validate age
    errors = if is_nil(params["age"]) or params["age"] == "" do
      Map.put(errors, "age", "Age is required")
    else
      case Integer.parse(params["age"]) do
        {age, _} when age >= 18 -> errors
        {age, _} when age < 18 -> Map.put(errors, "age", "You must be 18 or older")
        :error -> Map.put(errors, "age", "Age must be a valid number")
      end
    end
    
    errors
  end
end
