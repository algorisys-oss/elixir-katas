defmodule ElixirKatasWeb.Kata37WizardLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:current_step, 1)
      |> assign(:wizard_data, %{"name" => "", "email" => "", "role" => "", "bio" => ""})
      |> assign(:submitted_data, nil)
      # Forms for each step
      |> assign(:step1_form, to_form(%{"name" => "", "email" => ""}))
      |> assign(:step2_form, to_form(%{"role" => "developer", "bio" => ""}))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-lg mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Step <%= @current_step %> of 3.
           A multi-step form that accumulates data.
        </div>
        
        <!-- Progress Bar -->
        <div class="w-full bg-gray-200 rounded-full h-2.5 mb-6">
          <div class="bg-indigo-600 h-2.5 rounded-full transition-all duration-300" style={"width: #{(@current_step / 3) * 100}%"}></div>
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <%= case @current_step do %>
            <% 1 -> %>
              <div class="space-y-4">
                <h3 class="text-lg font-medium">Step 1: Identity</h3>
                <.form for={@step1_form} phx-submit="next_step" class="space-y-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700">Name</label>
                    <input type="text" name="name" value={@step1_form[:name].value} required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm border p-2"/>
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700">Email</label>
                    <input type="email" name="email" value={@step1_form[:email].value} required class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm border p-2"/>
                  </div>
                  <div class="flex justify-end">
                    <button type="submit" class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700">Next</button>
                  </div>
                </.form>
              </div>

            <% 2 -> %>
              <div class="space-y-4">
                <h3 class="text-lg font-medium">Step 2: Profile</h3>
                <.form for={@step2_form} phx-submit="next_step" class="space-y-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700">Role</label>
                    <select name="role" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm border p-2">
                       <option value="developer" selected={@step2_form[:role].value == "developer"}>Developer</option>
                       <option value="designer" selected={@step2_form[:role].value == "designer"}>Designer</option>
                       <option value="manager" selected={@step2_form[:role].value == "manager"}>Manager</option>
                    </select>
                  </div>
                   <div>
                    <label class="block text-sm font-medium text-gray-700">Bio</label>
                    <textarea name="bio" rows="3" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm border p-2"><%= @step2_form[:bio].value %></textarea>
                  </div>
                  <div class="flex justify-between">
                    <button type="button" phx-click="prev_step" phx-target={@myself} class="bg-gray-200 text-gray-700 px-4 py-2 rounded-md hover:bg-gray-300">Back</button>
                    <button type="submit" class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700">Review</button>
                  </div>
                </.form>
              </div>

            <% 3 -> %>
              <div class="space-y-4">
                <h3 class="text-lg font-medium">Step 3: Review</h3>
                <div class="bg-gray-50 p-4 rounded text-sm space-y-2">
                  <p><strong>Name:</strong> <%= @wizard_data["name"] %></p>
                  <p><strong>Email:</strong> <%= @wizard_data["email"] %></p>
                  <p><strong>Role:</strong> <%= @wizard_data["role"] %></p>
                  <p><strong>Bio:</strong> <%= @wizard_data["bio"] %></p>
                </div>
                 <div class="flex justify-between">
                    <button type="button" phx-click="prev_step" phx-target={@myself} class="bg-gray-200 text-gray-700 px-4 py-2 rounded-md hover:bg-gray-300">Back</button>
                    <button type="button" phx-click="save" phx-target={@myself} class="bg-green-600 text-white px-4 py-2 rounded-md hover:bg-green-700">Confirm & Save</button>
                  </div>
              </div>
          <% end %>
        </div>

        <%= if @submitted_data do %>
          <div class="mt-8 p-4 bg-green-50 rounded text-sm border border-green-200">
             <p class="font-bold text-green-700 mb-2">Final Submission:</p>
             <pre class="text-xs text-green-800"><%= inspect(@submitted_data, pretty: true) %></pre>
          </div>
        <% end %>
      </div>
    
    """
  end

  def handle_event("next_step", params, socket) do
    # In a real app, validate step-specific params here first.
    
    current_step = socket.assigns.current_step
    # Merge existing wizard data with new params from this step
    updated_data = Map.merge(socket.assigns.wizard_data, params)
    
    # Update the specific form state so if we go back, it's populated
    socket = 
      case current_step do
        1 -> assign(socket, :step1_form, to_form(params))
        2 -> assign(socket, :step2_form, to_form(params))
        _ -> socket
      end

    {:noreply, 
     socket
     |> assign(:wizard_data, updated_data)
     |> assign(:current_step, current_step + 1)}
  end

  def handle_event("prev_step", _params, socket) do
    {:noreply, update(socket, :current_step, &(&1 - 1))}
  end
  
  def handle_event("save", _params, socket) do
    {:noreply, 
     socket
     |> put_flash(:info, "Wizard completed successfully!")
     |> assign(:submitted_data, socket.assigns.wizard_data)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
