defmodule ElixirKatasWeb.Kata31DependentInputsLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    # Initial Data
    countries = ["USA", "Germany", "Japan"]
    
    # State
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:countries, countries)
      |> assign(:cities, []) # Empty initially until country selected
      |> assign(:city_disabled, true)
      |> assign(:form, to_form(%{"country" => "", "city" => ""}))
      |> assign(:submitted_data, nil)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-lg mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Select a Country to populate the City dropdown.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <.form for={@form} phx-change="validate" phx-submit="save" phx-target={@myself} class="space-y-6">
            
            <!-- Parent Input -->
            <div>
              <label for="country" class="block text-sm font-medium text-gray-700">Country</label>
              <select
                id="country"
                name="country"
                class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
              >
                <option value="">Select a country</option>
                <%= Phoenix.HTML.Form.options_for_select(@countries, @form[:country].value) %>
              </select>
            </div>

            <!-- Child Input -->
            <div>
              <label for="city" class="block text-sm font-medium text-gray-700">City</label>
              <select
                id="city"
                name="city"
                disabled={@city_disabled}
                class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md disabled:bg-gray-100 disabled:text-gray-400"
              >
                <option value="">Select a city</option>
                <%= Phoenix.HTML.Form.options_for_select(@cities, @form[:city].value) %>
              </select>
              <%= if @city_disabled do %>
                 <p class="mt-1 text-xs text-gray-400">Please select a country first.</p>
              <% end %>
            </div>

            <div>
              <button
                type="submit"
                disabled={@form[:city].value == "" || @form[:city].value == nil}
                class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:bg-gray-300 disabled:cursor-not-allowed"
              >
                Confirm Location
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
    country = params["country"] || ""
    current_country = socket.assigns.form[:country].value || ""
    
    # 1. Update list of cities based on selected country
    cities = get_cities(country)
    
    # 2. Check if we should reset the city selection
    # (If country changed, the old city is likely invalid)
    new_params = 
      if country != current_country do
         Map.put(params, "city", "")
      else
         params
      end
      
    # 3. Calculate disabled state
    disabled = country == ""
    
    {:noreply, 
     socket
     |> assign(:cities, cities)
     |> assign(:city_disabled, disabled)
     |> assign(:form, to_form(new_params))}
  end

  def handle_event("save", params, socket) do
    {:noreply, 
     socket
     |> put_flash(:info, "Location saved: #{params["city"]}, #{params["country"]}")
     |> assign(:submitted_data, params)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
  
  defp get_cities("USA"), do: ["New York", "San Francisco", "Austin", "Chicago"]
  defp get_cities("Germany"), do: ["Berlin", "Munich", "Hamburg", "Frankfurt"]
  defp get_cities("Japan"), do: ["Tokyo", "Osaka", "Kyoto", "Sapporo"]
  defp get_cities(_), do: []
end
