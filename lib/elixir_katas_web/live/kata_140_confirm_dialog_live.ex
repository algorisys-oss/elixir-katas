defmodule ElixirKatasWeb.Kata140ConfirmDialogLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      |> assign(:form_data, %{"name" => "", "email" => "", "message" => ""})
      |> assign(:errors, %{})
      |> assign(:show_confirm_modal, false)
      |> assign(:pending_data, nil)
      |> assign(:submitted_data, nil)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""

      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Form with confirmation dialog. Review your data before final submission.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <h3 class="text-lg font-medium mb-4">Contact Form</h3>

          <form phx-submit="request_confirm" phx-target={@myself} class="space-y-4">
            <div>
              <label class="block text-sm font-medium mb-1">Name *</label>
              <input
                type="text"
                name="name"
                value={@form_data["name"]}
                class={"w-full px-4 py-2 border rounded " <> if(@errors["name"], do: "border-red-500", else: "border-gray-300")}
                placeholder="Your full name"
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
                class={"w-full px-4 py-2 border rounded " <> if(@errors["email"], do: "border-red-500", else: "border-gray-300")}
                placeholder="your@email.com"
              />
              <%= if @errors["email"] do %>
                <p class="text-red-500 text-sm mt-1"><%= @errors["email"] %></p>
              <% end %>
            </div>

            <div>
              <label class="block text-sm font-medium mb-1">Message *</label>
              <textarea
                name="message"
                rows="4"
                class={"w-full px-4 py-2 border rounded " <> if(@errors["message"], do: "border-red-500", else: "border-gray-300")}
                placeholder="Your message..."
              ><%= @form_data["message"] %></textarea>
              <%= if @errors["message"] do %>
                <p class="text-red-500 text-sm mt-1"><%= @errors["message"] %></p>
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
              <h4 class="font-medium text-green-800 mb-2">Submission Confirmed!</h4>
              <div class="text-sm text-gray-700">
                <p><strong>Name:</strong> <%= @submitted_data["name"] %></p>
                <p><strong>Email:</strong> <%= @submitted_data["email"] %></p>
                <p><strong>Message:</strong> <%= @submitted_data["message"] %></p>
              </div>
            </div>
          <% end %>
        </div>

        <!-- Confirmation Modal -->
        <%= if @show_confirm_modal do %>
          <div
            class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
            phx-click="reject"
            phx-target={@myself}
            phx-window-keydown="handle_keydown"
            phx-key="Escape"
          >
            <div
              class="bg-white rounded-lg p-6 max-w-md w-full mx-4 shadow-xl"
              phx-click="prevent_close"
              phx-target={@myself}
            >
              <h3 class="text-lg font-bold mb-4">Confirm Submission</h3>

              <p class="text-gray-600 mb-4">Please review your information before submitting:</p>

              <div class="bg-gray-50 p-4 rounded mb-6 space-y-2 text-sm">
                <p><strong>Name:</strong> <%= @pending_data["name"] %></p>
                <p><strong>Email:</strong> <%= @pending_data["email"] %></p>
                <p><strong>Message:</strong></p>
                <p class="text-gray-600 italic"><%= @pending_data["message"] %></p>
              </div>

              <div class="flex justify-end gap-3">
                <button
                  phx-click="reject"
                  phx-target={@myself}
                  class="px-4 py-2 bg-gray-200 text-gray-700 rounded hover:bg-gray-300"
                >
                  Go Back
                </button>
                <button
                  phx-click="accept"
                  phx-target={@myself}
                  class="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700"
                >
                  Confirm & Submit
                </button>
              </div>
            </div>
          </div>
        <% end %>
      </div>

    """
  end

  # Step 1: Validate form and show confirmation modal
  def handle_event("request_confirm", params, socket) do
    errors = validate_form(params)

    if Enum.empty?(errors) do
      # Valid - show confirmation modal with pending data
      {:noreply,
       socket
       |> assign(:pending_data, params)
       |> assign(:form_data, params)
       |> assign(:show_confirm_modal, true)
       |> assign(:errors, %{})}
    else
      # Invalid - show errors, stay on form
      {:noreply,
       socket
       |> assign(:errors, errors)
       |> assign(:form_data, params)}
    end
  end

  # Step 2a: User accepts - process the submission
  def handle_event("accept", _params, socket) do
    pending_data = socket.assigns.pending_data

    # Here you would typically:
    # - Save to database
    # - Send email
    # - Call external API
    # For demo, we just store in assigns

    {:noreply,
     socket
     |> assign(:submitted_data, pending_data)
     |> assign(:show_confirm_modal, false)
     |> assign(:pending_data, nil)
     |> assign(:form_data, %{"name" => "", "email" => "", "message" => ""})}
  end

  # Step 2b: User rejects - close modal, keep form data intact
  def handle_event("reject", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_confirm_modal, false)}
    # Note: pending_data remains, form_data unchanged, user can edit and resubmit
  end

  # Prevent modal close when clicking inside modal content
  def handle_event("prevent_close", _params, socket) do
    {:noreply, socket}
  end

  # Handle Escape key
  def handle_event("handle_keydown", %{"key" => "Escape"}, socket) do
    {:noreply, assign(socket, show_confirm_modal: false)}
  end

  def handle_event("handle_keydown", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  # Form validation
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
      if String.contains?(params["email"], "@") and String.contains?(params["email"], ".") do
        errors
      else
        Map.put(errors, "email", "Please enter a valid email address")
      end
    end

    # Validate message
    errors = if is_nil(params["message"]) or String.trim(params["message"]) == "" do
      Map.put(errors, "message", "Message is required")
    else
      if String.length(String.trim(params["message"])) < 10 do
        Map.put(errors, "message", "Message must be at least 10 characters")
      else
        errors
      end
    end

    errors
  end
end
