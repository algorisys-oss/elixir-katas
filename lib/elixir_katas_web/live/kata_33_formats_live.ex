defmodule ElixirKatasWeb.Kata33FormatsLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:form, to_form(%{"email" => "", "phone" => ""}))
      |> assign(:submitted_data, nil)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-lg mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Validating input formats (Email & Phone) using Regex.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <.form for={@form} phx-change="validate" phx-submit="save" phx-target={@myself} class="space-y-6">
            
            <!-- Email Input -->
            <div>
              <label for="email" class="block text-sm font-medium text-gray-700">Email Address</label>
              <div class="mt-1">
                <input
                  type="text"
                  name="email"
                  id="email"
                  value={@form[:email].value}
                  class={"shadow-sm block w-full sm:text-sm rounded-md p-2 border " <> 
                         if(@form[:email].errors != [], do: "border-red-300 focus:ring-red-500 focus:border-red-500", else: "border-gray-300 focus:ring-indigo-500 focus:border-indigo-500")}
                  placeholder="you@example.com"
                />
              </div>
              <%= for error <- @form[:email].errors do %>
                 <p class="mt-2 text-sm text-red-600"><%= local_translate_error(error) %></p>
              <% end %>
            </div>

            <!-- Phone Input -->
            <div>
              <label for="phone" class="block text-sm font-medium text-gray-700">Phone Number (XXX-XXX-XXXX)</label>
              <div class="mt-1">
                <input
                  type="text"
                  name="phone"
                  id="phone"
                  value={@form[:phone].value}
                   class={"shadow-sm block w-full sm:text-sm rounded-md p-2 border " <> 
                         if(@form[:phone].errors != [], do: "border-red-300 focus:ring-red-500 focus:border-red-500", else: "border-gray-300 focus:ring-indigo-500 focus:border-indigo-500")}
                  placeholder="555-123-4567"
                />
              </div>
              <%= for error <- @form[:phone].errors do %>
                 <p class="mt-2 text-sm text-red-600"><%= local_translate_error(error) %></p>
              <% end %>
            </div>

            <div>
              <button
                type="submit"
                disabled={@form.errors != [] || @form[:email].value == "" || @form[:phone].value == ""}
                class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:bg-gray-300 disabled:cursor-not-allowed"
              >
                Save Contact
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
    email = params["email"]
    phone = params["phone"]
    
    # Regex Patterns
    email_regex = ~r/^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/
    phone_regex = ~r/^\d{3}-\d{3}-\d{4}$/

    errors = []
    
    errors = if email != "" and !String.match?(email, email_regex), do: [{:email, {"Invalid email format", []}} | errors], else: errors
    errors = if phone != "" and !String.match?(phone, phone_regex), do: [{:phone, {"Format must be XXX-XXX-XXXX", []}} | errors], else: errors

    {:noreply, assign(socket, :form, to_form(params, errors: errors))}
  end

  def handle_event("save", params, socket) do
    {:noreply, 
     socket
     |> put_flash(:info, "Contact info saved!")
     |> assign(:submitted_data, params)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
  
  defp local_translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
