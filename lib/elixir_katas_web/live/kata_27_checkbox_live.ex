defmodule ElixirKatasWeb.Kata27CheckboxLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    # Initial state: Newsletter subscribed by default, Terms not accepted
    form_data = %{"newsletter" => true, "terms" => false}

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
           Handling boolean values with checkboxes.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <.form for={@form} phx-change="validate" phx-submit="save" phx-target={@myself} class="space-y-6">
            
            <div class="flex items-start">
              <div class="flex items-center h-5">
                <input
                  id="newsletter"
                  name="newsletter"
                  type="checkbox"
                  value="true"
                  checked={Phoenix.HTML.Form.normalize_value("checkbox", @form[:newsletter].value)}
                  class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded"
                />
                 <!-- Hidden input trick for "false" value if unchecked -->
                 <input name="newsletter" type="hidden" value="false" />
              </div>
              <div class="ml-3 text-sm">
                <label for="newsletter" class="font-medium text-gray-700">Subscribe to newsletter</label>
                <p class="text-gray-500">Get the latest news sent to your inbox.</p>
              </div>
            </div>

             <div class="flex items-start">
              <div class="flex items-center h-5">
                <input
                  id="terms"
                  name="terms"
                  type="checkbox"
                  value="true"
                  checked={Phoenix.HTML.Form.normalize_value("checkbox", @form[:terms].value)}
                  class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded"
                />
                <input name="terms" type="hidden" value="false" />
              </div>
              <div class="ml-3 text-sm">
                <label for="terms" class="font-medium text-gray-700">I agree to the Terms and Conditions</label>
              </div>
            </div>

            <div>
              <button
                type="submit"
                disabled={!is_truthy(@form[:terms].value)}
                class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:bg-gray-400 disabled:cursor-not-allowed"
              >
                Sign Up
              </button>
              <%= if !is_truthy(@form[:terms].value) do %>
                <p class="mt-2 text-xs text-red-500 text-center">You must agree to terms to proceed.</p>
              <% end %>
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
    # params comes in as %{"newsletter" => "true", "terms" => "false"} strings (or "true")
    # We need to respect the types in our form_data map for consistency if we aren't using Ecto.
    # However, to_form handles params as-is.
    
    # Let's clean up the simple map params for display purposes (convert string bools to real bools)
    # Note: In a real app, Ecto.Changeset.cast/3 does this.
    cleaned_params = %{
      "newsletter" => params["newsletter"] == "true",
      "terms" => params["terms"] == "true"
    }

    {:noreply, assign(socket, :form, to_form(cleaned_params))}
  end

  def handle_event("save", params, socket) do
     cleaned_params = %{
      "newsletter" => params["newsletter"] == "true",
      "terms" => params["terms"] == "true"
    }

    {:noreply, 
     socket
     |> put_flash(:info, "Preferences saved!")
     |> assign(:submitted_data, cleaned_params)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
  
  defp is_truthy(val), do: val == true or val == "true"
end
