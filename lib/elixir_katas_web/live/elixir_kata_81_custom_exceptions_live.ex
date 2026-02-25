defmodule ElixirKatasWeb.ElixirKata81CustomExceptionsLive do
  use ElixirKatasWeb, :live_component

  @builtin_exceptions [
    %{
      id: "argument",
      title: "ArgumentError",
      code: ~s|raise ArgumentError, message: "expected a positive integer"|,
      description: "Raised when a function receives an argument of the wrong type or with an invalid value."
    },
    %{
      id: "runtime",
      title: "RuntimeError",
      code: ~s|raise "something went wrong"|,
      description: "The default exception type when using raise/1 with a string. A general-purpose runtime error."
    },
    %{
      id: "key",
      title: "KeyError",
      code: ~s|map = %{name: "Alice"}\ntry do\n  Map.fetch!(map, :age)\nrescue\n  e in KeyError -> "Caught: " <> Exception.message(e)\nend|,
      description: "Raised when a key is not found in a map or keyword list (e.g., Map.fetch!, Access.key!)."
    },
    %{
      id: "function_clause",
      title: "FunctionClauseError",
      code: ~s|defmodule TempCheck do\n  def check(n) when is_integer(n) and n > 0, do: "positive"\nend\ntry do\n  TempCheck.check(-1)\nrescue\n  e in FunctionClauseError -> "Caught: " <> Exception.message(e)\nend|,
      description: "Raised when no function clause matches the given arguments. Common with guards."
    },
    %{
      id: "arithmetic",
      title: "ArithmeticError",
      code: ~s|try do\n  1 / 0\nrescue\n  e in ArithmeticError -> "Caught: " <> Exception.message(e)\nend|,
      description: "Raised on invalid arithmetic operations like division by zero."
    },
    %{
      id: "enum_empty",
      title: "Enum.EmptyError",
      code: ~s|try do\n  Enum.fetch!([], 0)\nrescue\n  e -> "Caught: " <> Exception.message(e)\nend|,
      description: "Raised when an Enum function expects a non-empty enumerable but receives an empty one."
    }
  ]

  @custom_exception_examples [
    %{
      id: "basic",
      title: "Basic defexception",
      code: ~s|defmodule ValidationError do\n  defexception message: "validation failed"\nend\n\ntry do\n  raise ValidationError\nrescue\n  e in ValidationError -> Exception.message(e)\nend|,
      note: "The simplest custom exception. The :message field is the only required field."
    },
    %{
      id: "custom_message",
      title: "Custom message",
      code: ~s|defmodule ValidationError2 do\n  defexception message: "validation failed"\nend\n\ntry do\n  raise ValidationError2, message: "email is invalid"\nrescue\n  e -> Exception.message(e)\nend|,
      note: "Override the default message when raising."
    },
    %{
      id: "custom_fields",
      title: "Custom fields",
      code: ~s|defmodule ApiError do\n  defexception [:message, :status_code, :endpoint]\n\n  @impl true\n  def exception(opts) do\n    status = Keyword.get(opts, :status_code, 500)\n    endpoint = Keyword.get(opts, :endpoint, "unknown")\n    msg = "API error \#{status} at \#{endpoint}"\n    %__MODULE__{message: msg, status_code: status, endpoint: endpoint}\n  end\nend\n\ntry do\n  raise ApiError, status_code: 404, endpoint: "/users/99"\nrescue\n  e in ApiError -> {e.status_code, e.endpoint, Exception.message(e)}\nend|,
      note: "Custom fields provide structured error data. The exception/1 callback builds the struct."
    },
    %{
      id: "message_callback",
      title: "message/1 callback",
      code: ~s|defmodule InsufficientFundsError do\n  defexception [:balance, :amount]\n\n  @impl true\n  def message(%{balance: balance, amount: amount}) do\n    "Cannot withdraw \#{amount}: only \#{balance} available"\n  end\nend\n\ntry do\n  raise InsufficientFundsError, balance: 50, amount: 100\nrescue\n  e -> Exception.message(e)\nend|,
      note: "The message/1 callback computes the message dynamically from the exception fields."
    }
  ]

  @rescue_patterns [
    %{
      id: "single",
      title: "Single rescue",
      code: ~s|try do\n  String.to_integer("not_a_number")\nrescue\n  ArgumentError -> "Invalid argument"\nend|,
      note: "Rescue a specific exception type without binding to a variable."
    },
    %{
      id: "bind",
      title: "Bind to variable",
      code: ~s|try do\n  String.to_integer("abc")\nrescue\n  e in ArgumentError -> "Error: " <> Exception.message(e)\nend|,
      note: "Use 'e in ExceptionType' to bind the exception and access its fields."
    },
    %{
      id: "multiple",
      title: "Multiple rescue clauses",
      code: ~s|try do\n  map = %{a: 1}\n  Map.fetch!(map, :b)\nrescue\n  e in KeyError -> "Missing key: " <> Exception.message(e)\n  e in ArgumentError -> "Bad argument: " <> Exception.message(e)\n  _ -> "Some other error"\nend|,
      note: "Multiple rescue clauses are matched top-to-bottom, like case clauses."
    },
    %{
      id: "after",
      title: "try/rescue/after",
      code: ~s|result = try do\n  1 + 1\nrescue\n  _ -> "error"\nafter\n  IO.puts("cleanup runs always")\nend\nresult|,
      note: "The 'after' block always runs, but its return value is NOT the result of the try expression."
    },
    %{
      id: "reraise",
      title: "reraise/3",
      code: ~s|try do\n  try do\n    raise "original error"\n  rescue\n    e ->\n      # Log or wrap, then reraise with original stacktrace\n      reraise e, __STACKTRACE__\n  end\nrescue\n  e -> "Reraised: " <> Exception.message(e)\nend|,
      note: "reraise/3 preserves the original stacktrace. Use it when you catch, log, and re-throw."
    }
  ]

  @comparison_items [
    %{
      aspect: "Use case",
      exception: "Unexpected, truly exceptional failures",
      tagged: "Expected, recoverable outcomes"
    },
    %{
      aspect: "Control flow",
      exception: "Interrupts normal flow (non-local return)",
      tagged: "Normal return value, caller decides"
    },
    %{
      aspect: "Caller obligation",
      exception: "Must use try/rescue or crash",
      tagged: "Must pattern match on result"
    },
    %{
      aspect: "Idiomatic in Elixir?",
      exception: "Rare, reserved for bugs / unexpected states",
      tagged: "Very common, the default approach"
    },
    %{
      aspect: "Example: file read",
      exception: "File.read!/1 raises on error",
      tagged: "File.read/1 returns {:ok, _} / {:error, _}"
    },
    %{
      aspect: "Example: parsing",
      exception: "String.to_integer/1 raises on bad input",
      tagged: "Integer.parse/1 returns {:ok, _} or :error"
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_builtin, fn -> hd(@builtin_exceptions) end)
     |> assign_new(:builtin_result, fn -> nil end)
     |> assign_new(:active_custom, fn -> hd(@custom_exception_examples) end)
     |> assign_new(:custom_result, fn -> nil end)
     |> assign_new(:active_rescue, fn -> hd(@rescue_patterns) end)
     |> assign_new(:rescue_result, fn -> nil end)
     |> assign_new(:show_comparison, fn -> false end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Custom Exceptions</h2>
      <p class="text-sm opacity-70 mb-6">
        Elixir uses <code class="font-mono bg-base-300 px-1 rounded">defexception</code> to define
        custom exception types with structured fields. While Elixir favors
        <strong>tagged tuples</strong> (&lbrace;:ok, value&rbrace; / &lbrace;:error, reason&rbrace;) for expected errors,
        exceptions are the right tool for <strong>truly exceptional</strong> situations.
      </p>

      <!-- Section 1: Built-in Exceptions -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Built-in Exceptions</h3>

          <div class="flex flex-wrap gap-2 mb-4">
            <%= for ex <- builtin_exceptions() do %>
              <button
                phx-click="select_builtin"
                phx-target={@myself}
                phx-value-id={ex.id}
                class={"btn btn-sm " <> if(@active_builtin.id == ex.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= ex.title %>
              </button>
            <% end %>
          </div>

          <div class="bg-info/10 border border-info/30 rounded-lg p-3 text-sm mb-3">
            <%= @active_builtin.description %>
          </div>

          <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap mb-3"><%= @active_builtin.code %></div>

          <button
            phx-click="run_builtin"
            phx-target={@myself}
            class="btn btn-primary btn-sm"
          >
            Run Example
          </button>

          <%= if @builtin_result do %>
            <div class={"alert text-sm mt-3 " <> if(@builtin_result.ok, do: "alert-success", else: "alert-error")}>
              <div class="font-mono text-xs whitespace-pre-wrap"><%= @builtin_result.output %></div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Section 2: Creating Custom Exceptions -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Creating Custom Exceptions</h3>
          <p class="text-xs opacity-70 mb-4">
            Use <code class="font-mono bg-base-300 px-1 rounded">defexception</code> to define custom
            exception structs with custom fields, default messages, and the
            <code class="font-mono bg-base-300 px-1 rounded">exception/1</code> and
            <code class="font-mono bg-base-300 px-1 rounded">message/1</code> callbacks.
          </p>

          <div class="flex flex-wrap gap-2 mb-4">
            <%= for ce <- custom_exception_examples() do %>
              <button
                phx-click="select_custom"
                phx-target={@myself}
                phx-value-id={ce.id}
                class={"btn btn-sm " <> if(@active_custom.id == ce.id, do: "btn-accent", else: "btn-outline")}
              >
                <%= ce.title %>
              </button>
            <% end %>
          </div>

          <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap mb-3"><%= @active_custom.code %></div>
          <div class="text-xs opacity-70 mb-3"><%= @active_custom.note %></div>

          <button
            phx-click="run_custom"
            phx-target={@myself}
            class="btn btn-primary btn-sm"
          >
            Run Example
          </button>

          <%= if @custom_result do %>
            <div class={"alert text-sm mt-3 " <> if(@custom_result.ok, do: "alert-success", else: "alert-error")}>
              <div class="font-mono text-xs whitespace-pre-wrap"><%= @custom_result.output %></div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Section 3: Rescue Patterns -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Rescue Patterns</h3>

          <div class="flex flex-wrap gap-2 mb-4">
            <%= for rp <- rescue_patterns() do %>
              <button
                phx-click="select_rescue"
                phx-target={@myself}
                phx-value-id={rp.id}
                class={"btn btn-sm " <> if(@active_rescue.id == rp.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= rp.title %>
              </button>
            <% end %>
          </div>

          <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap mb-3"><%= @active_rescue.code %></div>
          <div class="text-xs opacity-70 mb-3"><%= @active_rescue.note %></div>

          <button
            phx-click="run_rescue"
            phx-target={@myself}
            class="btn btn-primary btn-sm"
          >
            Run Example
          </button>

          <%= if @rescue_result do %>
            <div class={"alert text-sm mt-3 " <> if(@rescue_result.ok, do: "alert-success", else: "alert-error")}>
              <div class="font-mono text-xs whitespace-pre-wrap"><%= @rescue_result.output %></div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Section 4: Exceptions vs Tagged Tuples -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Exceptions vs Tagged Tuples</h3>
            <button
              phx-click="toggle_comparison"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_comparison, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_comparison do %>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <div>
                <div class="text-xs font-bold text-error mb-2">Exception Style (bang functions)</div>
                <div class="bg-base-300 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap"><%= exception_style_code() %></div>
              </div>
              <div>
                <div class="text-xs font-bold text-success mb-2">Tagged Tuple Style (idiomatic)</div>
                <div class="bg-base-300 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap"><%= tagged_tuple_style_code() %></div>
              </div>
            </div>

            <div class="overflow-x-auto mb-4">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Aspect</th>
                    <th class="text-error">Exceptions</th>
                    <th class="text-success">Tagged Tuples</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for item <- comparison_items() do %>
                    <tr>
                      <td class="font-bold"><%= item.aspect %></td>
                      <td><%= item.exception %></td>
                      <td><%= item.tagged %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>

            <div class="alert alert-info text-sm">
              <div>
                <strong>Elixir convention:</strong> Use tagged tuples for expected errors. Use exceptions only for
                bugs, broken invariants, or when you want to crash (let it crash philosophy). Most stdlib functions
                offer both: <code class="font-mono">File.read/1</code> (tagged) and <code class="font-mono">File.read!/1</code> (exception).
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Section 5: Try Your Own -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try It</h3>
          <form phx-submit="run_sandbox" phx-target={@myself} class="space-y-3">
            <textarea
              name="code"
              rows="6"
              class="textarea textarea-bordered font-mono text-sm w-full"
              placeholder={sandbox_placeholder()}
              autocomplete="off"
            ><%= @sandbox_code %></textarea>
            <button type="submit" class="btn btn-primary btn-sm">Evaluate</button>
          </form>

          <div class="flex flex-wrap gap-2 mt-3 mb-3">
            <span class="text-xs opacity-50 self-center">Examples:</span>
            <%= for {label, code} <- sandbox_examples() do %>
              <button
                phx-click="quick_sandbox"
                phx-target={@myself}
                phx-value-code={code}
                class="btn btn-xs btn-outline"
              >
                <%= label %>
              </button>
            <% end %>
          </div>

          <%= if @sandbox_result do %>
            <div class={"alert text-sm mt-3 " <> if(@sandbox_result.ok, do: "alert-success", else: "alert-error")}>
              <div class="font-mono text-xs whitespace-pre-wrap"><%= @sandbox_result.output %></div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Section 6: Key Concepts -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Key Concepts</h3>
          <div class="space-y-3 text-sm">
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">1</span>
              <span><strong>defexception</strong> creates a struct with a :message field. Implement <code class="font-mono bg-base-100 px-1 rounded">exception/1</code> and <code class="font-mono bg-base-100 px-1 rounded">message/1</code> callbacks for custom construction and formatting.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>try/rescue</strong> catches exceptions by type. Use <code class="font-mono bg-base-100 px-1 rounded">e in ExceptionType</code> to bind and inspect the exception struct.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>reraise/3</strong> preserves the original stacktrace when you need to catch, log, and re-throw an exception.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Tagged tuples</strong> (&lbrace;:ok, value&rbrace; / &lbrace;:error, reason&rbrace;) are the idiomatic way to handle expected errors in Elixir. Exceptions are for truly unexpected failures.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span><strong>"Let it crash"</strong> means you don't need to rescue every possible error. Let supervisors handle process failures &mdash; only rescue when you have a meaningful recovery strategy.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_builtin", %{"id" => id}, socket) do
    ex = Enum.find(builtin_exceptions(), &(&1.id == id))
    {:noreply, assign(socket, active_builtin: ex, builtin_result: nil)}
  end

  def handle_event("run_builtin", _params, socket) do
    result = evaluate_code(socket.assigns.active_builtin.code)
    {:noreply, assign(socket, builtin_result: result)}
  end

  def handle_event("select_custom", %{"id" => id}, socket) do
    ce = Enum.find(custom_exception_examples(), &(&1.id == id))
    {:noreply, assign(socket, active_custom: ce, custom_result: nil)}
  end

  def handle_event("run_custom", _params, socket) do
    result = evaluate_code(socket.assigns.active_custom.code)
    {:noreply, assign(socket, custom_result: result)}
  end

  def handle_event("select_rescue", %{"id" => id}, socket) do
    rp = Enum.find(rescue_patterns(), &(&1.id == id))
    {:noreply, assign(socket, active_rescue: rp, rescue_result: nil)}
  end

  def handle_event("run_rescue", _params, socket) do
    result = evaluate_code(socket.assigns.active_rescue.code)
    {:noreply, assign(socket, rescue_result: result)}
  end

  def handle_event("toggle_comparison", _params, socket) do
    {:noreply, assign(socket, show_comparison: !socket.assigns.show_comparison)}
  end

  def handle_event("run_sandbox", %{"code" => code}, socket) do
    result = evaluate_code(String.trim(code))
    {:noreply, assign(socket, sandbox_code: code, sandbox_result: result)}
  end

  def handle_event("quick_sandbox", %{"code" => code}, socket) do
    result = evaluate_code(code)
    {:noreply, assign(socket, sandbox_code: code, sandbox_result: result)}
  end

  # Helpers

  defp builtin_exceptions, do: @builtin_exceptions
  defp custom_exception_examples, do: @custom_exception_examples
  defp rescue_patterns, do: @rescue_patterns
  defp comparison_items, do: @comparison_items

  defp exception_style_code do
    """
    # Raises on error - must wrap in try/rescue
    try do
      content = File.read!("/nonexistent")
      data = Jason.decode!(content)
      Map.fetch!(data, "key")
    rescue
      e in File.Error -> "File: " <> Exception.message(e)
      e in Jason.DecodeError -> "JSON: " <> Exception.message(e)
      e in KeyError -> "Key: " <> Exception.message(e)
    end\
    """
  end

  defp tagged_tuple_style_code do
    """
    # Returns tagged tuples - handle with case/with
    with {:ok, content} <- File.read("/some/path"),
         {:ok, data} <- Jason.decode(content),
         {:ok, value} <- Map.fetch(data, "key") do
      value
    else
      {:error, reason} -> "Error: \#{inspect(reason)}"
      :error -> "Key not found"
    end\
    """
  end

  defp sandbox_placeholder do
    "defmodule MyError do\n  defexception message: \"something went wrong\"\nend\n\ntry do\n  raise MyError\nrescue\n  e -> Exception.message(e)\nend"
  end

  defp sandbox_examples do
    [
      {"raise string",
       ~s|try do\n  raise "boom!"\nrescue\n  e in RuntimeError -> "Caught RuntimeError: " <> e.message\nend|},
      {"custom fields",
       ~s|defmodule HttpError do\n  defexception [:message, :status]\n\n  @impl true\n  def exception(opts) do\n    status = Keyword.get(opts, :status, 500)\n    msg = "HTTP \#{status}"\n    %__MODULE__{message: msg, status: status}\n  end\nend\n\ntry do\n  raise HttpError, status: 422\nrescue\n  e in HttpError -> {e.status, e.message}\nend|},
      {"rescue + after",
       ~s|try do\n  1 / 0\nrescue\n  ArithmeticError -> "division by zero"\nafter\n  IO.puts("cleanup!")\nend|},
      {"tagged tuples",
       ~s|case Integer.parse("abc") do\n  {n, ""} -> {:ok, n}\n  {_, rest} -> {:error, "trailing: \#{rest}"}\n  :error -> {:error, "not a number"}\nend|}
    ]
  end

  defp evaluate_code(code) do
    try do
      {result, _bindings} = Code.eval_string(code)
      %{ok: true, output: inspect(result, pretty: true, limit: 50)}
    rescue
      e -> %{ok: false, output: "Error: #{Exception.message(e)}"}
    end
  end
end
