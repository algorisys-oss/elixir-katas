defmodule ElixirKatasWeb.Kata28RadioButtonsLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    # Default plan
    form_data = %{"plan" => "starter"}

    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:form, to_form(form_data))
      |> assign(:submitted_data, nil)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-lg mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Handling mutually exclusive choices.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <.form for={@form} phx-change="validate" phx-submit="save" phx-target={@myself} class="space-y-6">
            
            <fieldset>
              <legend class="text-base font-medium text-gray-900">Select a Plan</legend>
              <div class="mt-4 space-y-4">
                
                <!-- Option 1 -->
                <div class="flex items-center">
                  <input
                    id="plan_starter"
                    name="plan"
                    type="radio"
                    value="starter"
                    checked={@form[:plan].value == "starter"}
                    class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300"
                  />
                  <label for="plan_starter" class="ml-3 block text-sm font-medium text-gray-700">
                    Starter <span class="text-gray-500 font-normal">($0/mo)</span>
                  </label>
                </div>

                <!-- Option 2 -->
                <div class="flex items-center">
                  <input
                    id="plan_pro"
                    name="plan"
                    type="radio"
                    value="pro"
                    checked={@form[:plan].value == "pro"}
                    class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300"
                  />
                  <label for="plan_pro" class="ml-3 block text-sm font-medium text-gray-700">
                    Pro <span class="text-gray-500 font-normal">($10/mo)</span>
                  </label>
                </div>

                <!-- Option 3 -->
                <div class="flex items-center">
                  <input
                    id="plan_enterprise"
                    name="plan"
                    type="radio"
                    value="enterprise"
                    checked={@form[:plan].value == "enterprise"}
                    class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300"
                  />
                  <label for="plan_enterprise" class="ml-3 block text-sm font-medium text-gray-700">
                    Enterprise <span class="text-gray-500 font-normal">($99/mo)</span>
                  </label>
                </div>

              </div>
            </fieldset>

            <div>
              <button
                type="submit"
                class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                Confirm Plan
              </button>
            </div>
          </.form>
        </div>

        <div class="mt-8 grid grid-cols-2 gap-4">
          <div class="p-4 bg-gray-50 rounded text-sm">
             <p class="font-bold text-gray-700 mb-2">Live State (@form):</p>
            <pre class="whitespace-pre-wrap text-xs text-gray-600"><%= inspect(@form.params, pretty: true) %></pre>
          </div>
          
           <div class="p-4 bg-green-50 rounded text-sm border border-green-200">
             <p class="font-bold text-green-700 mb-2">Last Submitted:</p>
             <%= if @submitted_data do %>
                <pre class="text-xs text-green-800"><%= inspect(@submitted_data, pretty: true) %></pre>
             <% else %>
                <p class="text-gray-400 italic">Waiting for submit...</p>
             <% end %>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("validate", params, socket) do
    # params: %{"plan" => "starter/pro/enterprise"}
    {:noreply, assign(socket, :form, to_form(params))}
  end

  def handle_event("save", params, socket) do
    {:noreply, 
     socket
     |> put_flash(:info, "Plan selected: #{params["plan"]}")
     |> assign(:submitted_data, params)}
  end
  
  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
