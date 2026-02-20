defmodule ElixirKatasWeb.Kata91MaskedInputLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:form, to_form(%{"phone" => "", "card" => "", "date" => ""}))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Input masking for Phone, Credit Card, and Date using JS Hooks
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <h3 class="text-lg font-medium mb-6">Masked Inputs</h3>
          
          <.form for={@form} phx-change="validate" phx-submit="save" phx-target={@myself} class="space-y-6">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Phone Number (US)</label>
              <.input 
                field={@form[:phone]} 
                type="text" 
                phx-hook="InputMask" 
                data-mask="phone"
                placeholder="(123) 456-7890" 
                class="w-full" 
              />
              <p class="mt-1 text-xs text-gray-500">Format: (XXX) XXX-XXXX</p>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Credit Card</label>
              <.input 
                field={@form[:card]} 
                type="text" 
                phx-hook="InputMask" 
                data-mask="credit-card"
                placeholder="0000 0000 0000 0000" 
                class="w-full" 
              />
              <p class="mt-1 text-xs text-gray-500">Format: XXXX XXXX XXXX XXXX</p>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Date</label>
              <.input 
                field={@form[:date]} 
                type="text" 
                phx-hook="InputMask" 
                data-mask="date"
                placeholder="MM/DD/YYYY" 
                class="w-full" 
              />
              <p class="mt-1 text-xs text-gray-500">Format: MM/DD/YYYY</p>
            </div>
            
            <div class="pt-4 border-t">
              <h4 class="text-xs font-semibold text-gray-500 uppercase mb-2">Current Values (Server Side)</h4>
              <dl class="grid grid-cols-3 gap-4 text-sm">
                <div>
                  <dt class="text-gray-500">Phone</dt>
                  <dd class="font-mono text-indigo-600"><%= @form[:phone].value %></dd>
                </div>
                <div>
                  <dt class="text-gray-500">Card</dt>
                  <dd class="font-mono text-indigo-600"><%= @form[:card].value %></dd>
                </div>
                <div>
                  <dt class="text-gray-500">Date</dt>
                  <dd class="font-mono text-indigo-600"><%= @form[:date].value %></dd>
                </div>
              </dl>
            </div>
          </.form>
        </div>
      </div>
    
    """
  end

  def handle_event("validate", params, socket) do
    {:noreply, assign(socket, :form, to_form(params))}
  end

  def handle_event("save", params, socket) do
    # Just update the form with submitted values
    {:noreply, assign(socket, :form, to_form(params))}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
