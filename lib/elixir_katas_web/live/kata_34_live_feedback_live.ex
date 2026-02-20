defmodule ElixirKatasWeb.Kata34LiveFeedbackLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:form, to_form(%{"username" => "", "email" => ""}))
      |> assign(:touched, MapSet.new()) # Track touched fields
      |> assign(:submitted_data, nil)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-lg mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Errors are only shown after you leave a field (blur) or try to submit.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-6">
            
            <!-- Username Input -->
            <div>
              <label for="username" class="block text-sm font-medium text-gray-700">Username (min 5 chars)</label>
              <div class="mt-1">
                <input
                  type="text"
                  name="username"
                  id="username"
                  phx-blur="blur" phx-target={@myself}
                  phx-value-field="username"
                  value={@form[:username].value}
                  class={"shadow-sm block w-full sm:text-sm rounded-md p-2 border " <> 
                         if(show_error?(@touched, "username", @form[:username].errors), do: "border-red-300 focus:ring-red-500 focus:border-red-500", else: "border-gray-300 focus:ring-indigo-500 focus:border-indigo-500")}
                />
              </div>
              <%= if show_error?(@touched, "username", @form[:username].errors) do %>
                 <p class="mt-2 text-sm text-red-600"><%= local_translate_error(List.first(@form[:username].errors)) %></p>
              <% end %>
            </div>

            <!-- Email Input -->
            <div>
              <label for="email" class="block text-sm font-medium text-gray-700">Email Address</label>
              <div class="mt-1">
                <input
                  type="text"
                  name="email"
                  id="email"
                  phx-blur="blur" phx-target={@myself}
                  phx-value-field="email"
                  value={@form[:email].value}
                  class={"shadow-sm block w-full sm:text-sm rounded-md p-2 border " <> 
                         if(show_error?(@touched, "email", @form[:email].errors), do: "border-red-300 focus:ring-red-500 focus:border-red-500", else: "border-gray-300 focus:ring-indigo-500 focus:border-indigo-500")}
                />
              </div>
              <%= if show_error?(@touched, "email", @form[:email].errors) do %>
                 <p class="mt-2 text-sm text-red-600"><%= local_translate_error(List.first(@form[:email].errors)) %></p>
              <% end %>
            </div>

            <div>
              <button
                type="submit"
                class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                Create Account
              </button>
            </div>
          </.form>
        </div>

        <div class="mt-8 grid grid-cols-2 gap-4">
          <div class="p-4 bg-gray-50 rounded text-sm">
             <p class="font-bold text-gray-700 mb-2">Detailed State:</p>
             <div class="text-xs text-gray-600">
               <p><strong>Touched:</strong> <%= inspect(MapSet.to_list(@touched)) %></p>
               <p class="mt-2"><strong>Params:</strong></p>
               <pre class="whitespace-pre-wrap"><%= inspect(@form.params, pretty: true) %></pre>
             </div>
          </div>
          
           <div class="p-4 bg-green-50 rounded text-sm border border-green-200">
             <p class="font-bold text-green-700 mb-2">Last Submitted:</p>
             <%= if @submitted_data do %>
                <pre class="text-xs text-green-800"><%= inspect(@submitted_data, pretty: true) %></pre>
             <% else %>
                <p class="text-gray-400 italic">Waiting for valid submit...</p>
             <% end %>
          </div>
        </div>
      </div>
    
    """
  end

  # Just validation logic, doesn't touch fields
  def handle_event("validate", params, socket) do
    {:noreply, assign(socket, :form, to_form(params, errors: validate(params)))}
  end
  
  # User leaves a field
  def handle_event("blur", %{"field" => field}, socket) do
    touched = MapSet.put(socket.assigns.touched, field)
    {:noreply, assign(socket, :touched, touched)}
  end

  def handle_event("save", params, socket) do
    errors = validate(params)
    
    if errors == [] do
      {:noreply, 
       socket
       |> put_flash(:info, "Account created!")
       |> assign(:submitted_data, params)
       # Reset form but maybe keep touched empty for fresh start
       |> assign(:form, to_form(%{"username" => "", "email" => ""})) 
       |> assign(:touched, MapSet.new())}
    else
      # Mark ALL as touched so errors show up
      touched = MapSet.new(["username", "email"])
      {:noreply, 
       socket
       |> put_flash(:error, "Please fix errors before submitting.")
       |> assign(:form, to_form(params, errors: errors))
       |> assign(:touched, touched)}
    end
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
  
  defp validate(%{"username" => username, "email" => email}) do
    errors = []
    errors = if String.length(username) < 5, do: [{:username, {"Min 5 chars", []}} | errors], else: errors
    errors = if !String.contains?(email, "@"), do: [{:email, {"Invalid email", []}} | errors], else: errors
    errors
  end

  defp show_error?(touched, field, errors) do
    MapSet.member?(touched, field) and errors != []
  end
    
  defp local_translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
