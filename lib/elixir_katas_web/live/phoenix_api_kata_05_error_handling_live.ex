defmodule ElixirKatasWeb.PhoenixApiKata05ErrorHandlingLive do
  use ElixirKatasWeb, :live_component

  @scenarios [
    %{
      id: "validation",
      label: "Validation Error",
      icon: "!",
      desc: "User submits invalid data (empty name, bad email)",
      steps: [
        %{label: "Controller", module: "UserController.create/2", color: "blue",
          detail: "Calls Accounts.create_user(params)"},
        %{label: "Context", module: "Accounts.create_user/1", color: "purple",
          detail: "Runs changeset validations, returns {:error, changeset}"},
        %{label: "Controller", module: "Pattern match {:error, changeset}", color: "blue",
          detail: "Returns {:error, changeset} — triggers action_fallback"},
        %{label: "Fallback", module: "FallbackController.call/2", color: "rose",
          detail: "Matches {:error, %Ecto.Changeset{}} clause"},
        %{label: "Response", module: "ErrorJSON.render(\"422.json\", ...)", color: "amber",
          detail: "Formats changeset errors as JSON map"},
        %{label: "Client", module: "422 Unprocessable Entity", color: "red",
          detail: ~s|{"errors": {"name": ["can't be blank"], "email": ["is invalid"]}}|}
      ]
    },
    %{
      id: "not_found",
      label: "Not Found",
      icon: "?",
      desc: "Client requests a resource that doesn't exist",
      steps: [
        %{label: "Controller", module: "UserController.show/2", color: "blue",
          detail: "Calls Accounts.get_user(id)"},
        %{label: "Context", module: "Accounts.get_user/1", color: "purple",
          detail: "Returns nil (no matching record)"},
        %{label: "Controller", module: "Returns {:error, :not_found}", color: "blue",
          detail: "Wraps nil in error tuple — triggers action_fallback"},
        %{label: "Fallback", module: "FallbackController.call/2", color: "rose",
          detail: "Matches {:error, :not_found} clause"},
        %{label: "Response", module: "ErrorJSON.render(\"404.json\", ...)", color: "amber",
          detail: "Returns standard not-found error"},
        %{label: "Client", module: "404 Not Found", color: "red",
          detail: ~s|{"errors": {"detail": "Not Found"}}|}
      ]
    },
    %{
      id: "unauthorized",
      label: "Unauthorized",
      icon: "X",
      desc: "Request has missing or invalid authentication token",
      steps: [
        %{label: "Plug", module: "VerifyApiToken plug runs", color: "cyan",
          detail: "Checks Authorization header for valid Bearer token"},
        %{label: "Plug", module: "Token invalid or missing", color: "cyan",
          detail: "Halts the connection before reaching the controller"},
        %{label: "Plug", module: "put_status(:unauthorized) |> json(error)", color: "rose",
          detail: "Sends 401 response directly from the plug"},
        %{label: "Client", module: "401 Unauthorized", color: "red",
          detail: ~s|{"errors": {"detail": "Missing or invalid token"}}|}
      ]
    },
    %{
      id: "server_error",
      label: "Server Error",
      icon: "!!",
      desc: "Unhandled exception crashes the controller action",
      steps: [
        %{label: "Controller", module: "UserController.index/2", color: "blue",
          detail: "Calls Accounts.list_users() — but DB is down!"},
        %{label: "Exception", module: "** (DBConnection.ConnectionError)", color: "red",
          detail: "Unhandled exception raised in the action"},
        %{label: "Phoenix", module: "Phoenix.Endpoint.RenderErrors", color: "rose",
          detail: "Catches the exception, logs the error"},
        %{label: "Response", module: "ErrorJSON.render(\"500.json\", ...)", color: "amber",
          detail: "Returns generic server error (never expose internals!)"},
        %{label: "Client", module: "500 Internal Server Error", color: "red",
          detail: ~s|{"errors": {"detail": "Internal Server Error"}}|}
      ]
    }
  ]

  def phoenix_source do
    """
    # Error Handling & Fallback Controllers
    #
    # Phoenix uses action_fallback to handle error tuples from controllers.
    # The fallback controller converts error tuples into proper JSON responses.

    # 1. Controller with action_fallback
    defmodule MyAppWeb.Api.UserController do
      use MyAppWeb, :controller

      # Tell Phoenix: if my action returns {:error, _}, call FallbackController
      action_fallback MyAppWeb.FallbackController

      def show(conn, %{"id" => id) do
        # with chains success tuples; any non-match triggers fallback
        with {:ok, user} <- Accounts.fetch_user(id) do
          json(conn, %{data: user})
        end
        # If fetch_user returns {:error, :not_found},
        # FallbackController.call(conn, {:error, :not_found}) is invoked
      end

      def create(conn, %{"user" => params}) do
        with {:ok, user} <- Accounts.create_user(params) do
          conn
          |> put_status(:created)
          |> json(%{data: user})
        end
        # If create_user returns {:error, %Ecto.Changeset{}},
        # FallbackController handles it automatically
      end
    end

    # 2. FallbackController — handles all error tuples
    defmodule MyAppWeb.FallbackController do
      use MyAppWeb, :controller

      # Changeset validation errors → 422
      def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(json: MyAppWeb.ErrorJSON)
        |> render(:error, changeset: changeset)
      end

      # Not found → 404
      def call(conn, {:error, :not_found}) do
        conn
        |> put_status(:not_found)
        |> put_view(json: MyAppWeb.ErrorJSON)
        |> render(:"404")
      end

      # Unauthorized → 401
      def call(conn, {:error, :unauthorized}) do
        conn
        |> put_status(:unauthorized)
        |> put_view(json: MyAppWeb.ErrorJSON)
        |> render(:"401")
      end
    end

    # 3. ErrorJSON — renders error responses
    defmodule MyAppWeb.ErrorJSON do
      # Render changeset errors as a map
      def render("error.json", %{changeset: changeset}) do
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Regex.replace(~r"%{(\\w+)}", msg, fn _, key ->
              opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
            end)
          end)

        %{errors: errors}
      end

      # Catch-all for status code errors (404.json, 500.json, etc.)
      def render(template, _assigns) do
        %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
      end
    end
    """
    |> String.trim()
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(id: assigns.id)
     |> assign(scenarios: @scenarios)
     |> assign(selected_scenario: nil)
     |> assign(current_step: 0)
     |> assign(auto_playing: false)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Error Handling & Fallback Controllers</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Pick an error scenario and step through the chain:
        <strong>Controller -> Fallback Controller -> ErrorJSON -> JSON Response</strong>.
      </p>

      <!-- Scenario Picker -->
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <%= for scenario <- @scenarios do %>
          <button
            phx-click="select_scenario"
            phx-value-id={scenario.id}
            phx-target={@myself}
            class={["p-4 rounded-lg border-2 text-left transition-all cursor-pointer",
              if(@selected_scenario && @selected_scenario.id == scenario.id,
                do: "border-rose-500 bg-rose-50 dark:bg-rose-900/20 shadow-md",
                else: "border-gray-200 dark:border-gray-700 hover:border-rose-300 dark:hover:border-rose-700 bg-white dark:bg-gray-800")
            ]}
          >
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-full bg-rose-100 dark:bg-rose-900/30 flex items-center justify-center text-rose-600 dark:text-rose-400 font-bold text-sm">
                {scenario.icon}
              </div>
              <div>
                <div class="font-semibold text-gray-900 dark:text-white">{scenario.label}</div>
                <div class="text-sm text-gray-500 dark:text-gray-400">{scenario.desc}</div>
              </div>
            </div>
          </button>
        <% end %>
      </div>

      <!-- Error Flow Visualization -->
      <%= if @selected_scenario do %>
        <div class="border-t border-gray-200 dark:border-gray-700 pt-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
              Error Flow: {@selected_scenario.label}
            </h3>
            <div class="flex gap-2">
              <button
                phx-click="reset_steps"
                phx-target={@myself}
                class="px-3 py-1.5 text-sm bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors cursor-pointer"
              >
                Reset
              </button>
              <button
                phx-click="next_step"
                phx-target={@myself}
                disabled={@current_step >= length(@selected_scenario.steps)}
                class={["px-4 py-1.5 text-sm rounded-lg font-medium transition-colors cursor-pointer",
                  if(@current_step >= length(@selected_scenario.steps),
                    do: "bg-gray-300 dark:bg-gray-700 text-gray-500 cursor-not-allowed",
                    else: "bg-rose-600 hover:bg-rose-700 text-white")
                ]}
              >
                <%= if @current_step == 0, do: "Start Flow", else: "Next Step" %>
              </button>
            </div>
          </div>

          <!-- Steps -->
          <div class="space-y-3">
            <%= for {step, i} <- Enum.with_index(@selected_scenario.steps) do %>
              <div class={["flex items-start gap-4 p-4 rounded-lg transition-all duration-300",
                cond do
                  i < @current_step -> "bg-gray-50 dark:bg-gray-800 opacity-100"
                  i == @current_step -> "bg-#{step.color}-50 dark:bg-#{step.color}-900/20 border-2 border-#{step.color}-300 dark:border-#{step.color}-700 shadow-md"
                  true -> "bg-gray-50 dark:bg-gray-800 opacity-30"
                end
              ]}>
                <!-- Step Number -->
                <div class={["flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm",
                  if(i <= @current_step,
                    do: "bg-#{step.color}-100 dark:bg-#{step.color}-900/30 text-#{step.color}-600 dark:text-#{step.color}-400",
                    else: "bg-gray-200 dark:bg-gray-700 text-gray-400")
                ]}>
                  <%= if i < @current_step do %>
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                    </svg>
                  <% else %>
                    {i + 1}
                  <% end %>
                </div>

                <!-- Step Content -->
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2 mb-0.5">
                    <span class={"text-xs font-semibold uppercase tracking-wide text-#{step.color}-600 dark:text-#{step.color}-400"}>
                      {step.label}
                    </span>
                  </div>
                  <div class="font-mono text-sm text-gray-900 dark:text-white">{step.module}</div>
                  <%= if i <= @current_step do %>
                    <div class="text-sm text-gray-600 dark:text-gray-400 mt-1">{step.detail}</div>
                  <% end %>
                </div>

                <!-- Arrow (not on last) -->
                <%= if i < length(@selected_scenario.steps) - 1 do %>
                  <div class={["flex-shrink-0 text-gray-300 dark:text-gray-600",
                    if(i < @current_step, do: "text-#{step.color}-400 dark:text-#{step.color}-500", else: "")
                  ]}>
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3" />
                    </svg>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>

          <!-- Final Result -->
          <%= if @current_step >= length(@selected_scenario.steps) do %>
            <div class="mt-4 p-4 bg-gray-900 rounded-lg">
              <div class="text-gray-400 font-mono text-sm mb-2"># Final JSON response sent to client:</div>
              <pre class="text-rose-400 font-mono text-sm whitespace-pre-wrap"><%= final_response(@selected_scenario.id) %></pre>
            </div>
          <% end %>
        </div>
      <% end %>

      <!-- Architecture Overview -->
      <div class="border-t border-gray-200 dark:border-gray-700 pt-6">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">The Error Handling Chain</h3>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
            <h4 class="font-semibold text-blue-800 dark:text-blue-300 mb-2">1. Controller</h4>
            <p class="text-sm text-blue-700 dark:text-blue-400">
              Returns <code>{"{:error, reason}"}</code> instead of handling errors inline.
              Uses <code>action_fallback</code> to delegate error handling.
            </p>
          </div>
          <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
            <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-2">2. FallbackController</h4>
            <p class="text-sm text-rose-700 dark:text-rose-400">
              Pattern matches on error tuples. Converts each error type to the correct status code and view.
              One place for all error-to-response logic.
            </p>
          </div>
          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <h4 class="font-semibold text-amber-800 dark:text-amber-300 mb-2">3. ErrorJSON</h4>
            <p class="text-sm text-amber-700 dark:text-amber-400">
              Renders the actual JSON body. Handles changeset errors, status-code templates (404.json, 500.json),
              and custom error formats.
            </p>
          </div>
        </div>
      </div>

      <!-- Key Insight -->
      <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
        <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-1">Why This Pattern?</h4>
        <p class="text-sm text-rose-700 dark:text-rose-400">
          Without <code>action_fallback</code>, every controller action would need its own error handling code.
          The fallback pattern centralizes it: controllers stay focused on the happy path, and the FallbackController
          handles all error scenarios consistently across your entire API.
        </p>
      </div>
    </div>
    """
  end

  defp final_response("validation") do
    """
    HTTP/1.1 422 Unprocessable Entity
    Content-Type: application/json

    {
      "errors": {
        "name": ["can't be blank"],
        "email": ["is invalid"]
      }
    }
    """
    |> String.trim()
  end

  defp final_response("not_found") do
    """
    HTTP/1.1 404 Not Found
    Content-Type: application/json

    {
      "errors": {
        "detail": "Not Found"
      }
    }
    """
    |> String.trim()
  end

  defp final_response("unauthorized") do
    """
    HTTP/1.1 401 Unauthorized
    Content-Type: application/json

    {
      "errors": {
        "detail": "Missing or invalid token"
      }
    }
    """
    |> String.trim()
  end

  defp final_response("server_error") do
    """
    HTTP/1.1 500 Internal Server Error
    Content-Type: application/json

    {
      "errors": {
        "detail": "Internal Server Error"
      }
    }
    """
    |> String.trim()
  end

  defp final_response(_), do: ""

  def handle_event("select_scenario", %{"id" => id}, socket) do
    scenario = Enum.find(@scenarios, &(&1.id == id))
    {:noreply, assign(socket, selected_scenario: scenario, current_step: 0)}
  end

  def handle_event("next_step", _params, socket) do
    max = length(socket.assigns.selected_scenario.steps)
    new_step = min(socket.assigns.current_step + 1, max)
    {:noreply, assign(socket, current_step: new_step)}
  end

  def handle_event("reset_steps", _params, socket) do
    {:noreply, assign(socket, current_step: 0)}
  end
end
