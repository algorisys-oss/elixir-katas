defmodule ElixirKatasWeb.ElixirKata48StructValidationLive do
  use ElixirKatasWeb, :live_component

  @validation_patterns [
    %{
      id: "basic_new",
      title: "Basic Constructor",
      code: "defmodule Email do\n  @enforce_keys [:address]\n  defstruct [:address]\n\n  def new(address) when is_binary(address) do\n    if String.contains?(address, \"@\") do\n      {:ok, %Email{address: address}}\n    else\n      {:error, \"invalid email: missing @\"}\n    end\n  end\n\n  def new(_), do: {:error, \"address must be a string\"}\nend",
      usage: ~s[Email.new("alice@example.com")\n#=> {:ok, %Email{address: "alice@example.com"}}\n\nEmail.new("not-an-email")\n#=> {:error, "invalid email: missing @"}],
      explanation: "The new/1 constructor pattern returns {:ok, struct} or {:error, reason}. This makes invalid states unrepresentable."
    },
    %{
      id: "pipeline",
      title: "Validation Pipeline",
      code: "defmodule User do\n  @enforce_keys [:name, :email, :age]\n  defstruct [:name, :email, :age, role: :user]\n\n  def new(attrs) do\n    with {:ok, name} <- validate_name(attrs),\n         {:ok, email} <- validate_email(attrs),\n         {:ok, age} <- validate_age(attrs) do\n      {:ok, %User{name: name, email: email, age: age,\n                   role: Map.get(attrs, :role, :user)}}\n    end\n  end\n\n  defp validate_name(%{name: name}) when is_binary(name) and byte_size(name) > 0,\n    do: {:ok, name}\n  defp validate_name(_), do: {:error, \"name is required and must be non-empty\"}\n\n  defp validate_email(%{email: email}) when is_binary(email) do\n    if String.contains?(email, \"@\"), do: {:ok, email},\n      else: {:error, \"email must contain @\"}\n  end\n  defp validate_email(_), do: {:error, \"email is required\"}\n\n  defp validate_age(%{age: age}) when is_integer(age) and age > 0 and age < 150,\n    do: {:ok, age}\n  defp validate_age(_), do: {:error, \"age must be an integer between 1 and 149\"}\nend",
      usage: ~s[User.new(%{name: "Alice", email: "a@b.com", age: 30})\n#=> {:ok, %User{name: "Alice", ...}}\n\nUser.new(%{name: "", email: "a@b.com", age: 30})\n#=> {:error, "name is required and must be non-empty"}],
      explanation: "Using 'with' chains multiple validations. The first failure short-circuits and returns the error."
    },
    %{
      id: "bang",
      title: "Bang (!) Variant",
      code: "defmodule Money do\n  @enforce_keys [:amount, :currency]\n  defstruct [:amount, :currency]\n\n  def new(amount, currency) do\n    with {:ok, amount} <- validate_amount(amount),\n         {:ok, currency} <- validate_currency(currency) do\n      {:ok, %Money{amount: amount, currency: currency}}\n    end\n  end\n\n  def new!(amount, currency) do\n    case new(amount, currency) do\n      {:ok, money} -> money\n      {:error, reason} -> raise ArgumentError, reason\n    end\n  end\n\n  defp validate_amount(a) when is_number(a) and a >= 0, do: {:ok, a}\n  defp validate_amount(_), do: {:error, \"amount must be non-negative number\"}\n\n  defp validate_currency(c) when c in [:usd, :eur, :gbp], do: {:ok, c}\n  defp validate_currency(_), do: {:error, \"currency must be :usd, :eur, or :gbp\"}\nend",
      usage: ~s[Money.new(100, :usd)\n#=> {:ok, %Money{amount: 100, currency: :usd}}\n\nMoney.new!(100, :usd)\n#=> %Money{amount: 100, currency: :usd}\n\nMoney.new!(-5, :usd)\n#=> ** (ArgumentError) amount must be non-negative number],
      explanation: "The bang variant new!/1 raises on invalid input. Use new/1 when you want to handle errors, new!/1 when invalid input is a bug."
    },
    %{
      id: "multi_error",
      title: "Collecting All Errors",
      code: "defmodule Registration do\n  defstruct [:username, :email, :password]\n\n  def new(attrs) do\n    errors =\n      []\n      |> validate_username(attrs)\n      |> validate_email(attrs)\n      |> validate_password(attrs)\n\n    case errors do\n      [] ->\n        {:ok, %Registration{\n          username: attrs[:username],\n          email: attrs[:email],\n          password: attrs[:password]\n        }}\n      errors ->\n        {:error, Enum.reverse(errors)}\n    end\n  end\n\n  defp validate_username(errors, %{username: u})\n    when is_binary(u) and byte_size(u) >= 3, do: errors\n  defp validate_username(errors, _),\n    do: [\"username must be at least 3 chars\" | errors]\n\n  defp validate_email(errors, %{email: e}) when is_binary(e) do\n    if String.contains?(e, \"@\"), do: errors,\n      else: [\"email must contain @\" | errors]\n  end\n  defp validate_email(errors, _), do: [\"email is required\" | errors]\n\n  defp validate_password(errors, %{password: p})\n    when is_binary(p) and byte_size(p) >= 8, do: errors\n  defp validate_password(errors, _),\n    do: [\"password must be at least 8 chars\" | errors]\nend",
      usage: "Registration.new(%{username: \"ab\", email: \"bad\", password: \"short\"})\n#=> {:error, [\"username must be at least 3 chars\",\n#            \"email must contain @\",\n#            \"password must be at least 8 chars\"]}",
      explanation: "Sometimes you want ALL errors at once (like form validation). Accumulate errors in a list instead of short-circuiting."
    }
  ]

  @try_examples [
    {"Valid user", ~s|%{name: "Alice", email: "alice@example.com", age: 30}|},
    {"Missing name", ~s|%{name: "", email: "alice@example.com", age: 30}|},
    {"Bad email", ~s|%{name: "Bob", email: "no-at-sign", age: 25}|},
    {"Bad age", ~s|%{name: "Charlie", email: "c@d.com", age: -5}|},
    {"Missing fields", ~s|%{name: "Diana"}|}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_pattern, fn -> hd(@validation_patterns) end)
     |> assign_new(:try_input, fn -> "" end)
     |> assign_new(:try_result, fn -> nil end)
     |> assign_new(:show_enforce_keys, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Struct Validation</h2>
      <p class="text-sm opacity-70 mb-6">
        Raw <code class="font-mono bg-base-300 px-1 rounded">%MyStruct&lbrace;&rbrace;</code> creation has no runtime validation.
        Constructor patterns like <code class="font-mono bg-base-300 px-1 rounded">new/1</code> returning
        <code class="font-mono bg-base-300 px-1 rounded">&lbrace;:ok, struct&rbrace;</code> or
        <code class="font-mono bg-base-300 px-1 rounded">&lbrace;:error, reason&rbrace;</code> let you enforce invariants.
      </p>

      <!-- Pattern Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for pattern <- validation_patterns() do %>
          <button
            phx-click="select_pattern"
            phx-target={@myself}
            phx-value-id={pattern.id}
            class={"btn btn-sm " <> if(@active_pattern.id == pattern.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= pattern.title %>
          </button>
        <% end %>
      </div>

      <!-- Active Pattern -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2"><%= @active_pattern.title %></h3>

          <!-- Module Code -->
          <div class="bg-base-300 rounded-lg p-4 font-mono text-xs whitespace-pre-wrap mb-3"><%= @active_pattern.code %></div>

          <!-- Usage -->
          <div class="bg-base-100 rounded-lg p-3 mb-3">
            <div class="text-xs font-bold opacity-60 mb-1">Usage</div>
            <div class="font-mono text-xs whitespace-pre-wrap"><%= @active_pattern.usage %></div>
          </div>

          <!-- Explanation -->
          <div class="bg-info/10 border border-info/30 rounded-lg p-3">
            <div class="text-xs font-bold opacity-60 mb-1">Why this pattern?</div>
            <div class="text-sm"><%= @active_pattern.explanation %></div>
          </div>
        </div>
      </div>

      <!-- Interactive Validator -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try the Validation Pipeline</h3>
          <p class="text-xs opacity-60 mb-4">
            Enter a map with <code class="font-mono bg-base-300 px-1 rounded">:name</code>,
            <code class="font-mono bg-base-300 px-1 rounded">:email</code>, and
            <code class="font-mono bg-base-300 px-1 rounded">:age</code> fields to validate.
          </p>

          <form phx-submit="try_validate" phx-target={@myself} class="space-y-3">
            <div class="form-control">
              <input
                type="text"
                name="input"
                value={@try_input}
                placeholder={~s|%{name: "Alice", email: "alice@example.com", age: 30}|}
                class="input input-bordered input-sm font-mono"
                autocomplete="off"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-sm">Validate</button>
          </form>

          <!-- Quick Examples -->
          <div class="flex flex-wrap gap-2 mt-3 mb-3">
            <span class="text-xs opacity-50 self-center">Try:</span>
            <%= for {label, code} <- try_examples() do %>
              <button
                phx-click="quick_validate"
                phx-target={@myself}
                phx-value-code={code}
                class="btn btn-xs btn-outline"
              >
                <%= label %>
              </button>
            <% end %>
          </div>

          <%= if @try_result do %>
            <div class={"alert text-sm mt-3 " <> if(@try_result.ok, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="font-mono text-xs opacity-60"><%= @try_result.input %></div>
                <div class="font-mono font-bold mt-1 whitespace-pre-wrap"><%= @try_result.output %></div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- @enforce_keys Deep Dive -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">@enforce_keys Deep Dive</h3>
            <button
              phx-click="toggle_enforce_keys"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_enforce_keys, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_enforce_keys do %>
            <div class="space-y-4">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <!-- Without @enforce_keys -->
                <div class="bg-error/10 border border-error/30 rounded-lg p-4">
                  <h4 class="font-bold text-error text-sm mb-2">Without @enforce_keys</h4>
                  <div class="bg-base-100 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap">{loose_struct_code()}</div>
                  <div class="mt-2 text-xs text-error">Silently creates invalid structs with nil fields.</div>
                </div>

                <!-- With @enforce_keys -->
                <div class="bg-success/10 border border-success/30 rounded-lg p-4">
                  <h4 class="font-bold text-success text-sm mb-2">With @enforce_keys</h4>
                  <div class="bg-base-100 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap">{strict_struct_code()}</div>
                  <div class="mt-2 text-xs text-success">Catches missing required fields at compile time.</div>
                </div>
              </div>

              <div class="alert alert-info text-sm">
                <div>
                  <div class="font-bold">@enforce_keys vs new/1</div>
                  <span>@enforce_keys catches missing fields at compile time but cannot validate values.
                    Constructor functions like new/1 validate values at runtime. Use both together for maximum safety.</span>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Key Concepts -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Key Concepts</h3>
          <div class="space-y-3 text-sm">
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">1</span>
              <span>Constructor functions (<strong>new/1</strong>) return <code class="font-mono bg-base-100 px-1 rounded">&lbrace;:ok, struct&rbrace;</code> or <code class="font-mono bg-base-100 px-1 rounded">&lbrace;:error, reason&rbrace;</code> for safe creation.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span>Use <strong>with</strong> to chain validations -- the first failure short-circuits.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Bang variants</strong> (new!/1) raise on invalid input -- use when invalid data is a bug, not user error.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Accumulate errors</strong> when you need all validation failures at once (e.g., form validation).</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Combine <strong>@enforce_keys</strong> (compile-time) with <strong>new/1</strong> (runtime) for maximum type safety.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_pattern", %{"id" => id}, socket) do
    pattern = Enum.find(validation_patterns(), &(&1.id == id))
    {:noreply, assign(socket, active_pattern: pattern)}
  end

  def handle_event("try_validate", %{"input" => input}, socket) do
    result = run_validation(String.trim(input))

    {:noreply,
     socket
     |> assign(try_input: input)
     |> assign(try_result: result)}
  end

  def handle_event("quick_validate", %{"code" => code}, socket) do
    result = run_validation(code)

    {:noreply,
     socket
     |> assign(try_input: code)
     |> assign(try_result: result)}
  end

  def handle_event("toggle_enforce_keys", _params, socket) do
    {:noreply, assign(socket, show_enforce_keys: !socket.assigns.show_enforce_keys)}
  end

  # Helpers

  defp validation_patterns, do: @validation_patterns
  defp try_examples, do: @try_examples

  defp loose_struct_code do
    String.trim("""
    defmodule Loose do
      defstruct [:name, :email]
    end

    # This is allowed -- all fields are nil!
    %Loose{}
    #=> %Loose{name: nil, email: nil}
    """)
  end

  defp run_validation(input) do
    try do
      {attrs, _} = Code.eval_string(input)

      if is_map(attrs) do
        result = validate_user_attrs(attrs)

        case result do
          {:ok, msg} -> %{ok: true, input: input, output: msg}
          {:error, msg} -> %{ok: false, input: input, output: msg}
        end
      else
        %{ok: false, input: input, output: "Input must be a map"}
      end
    rescue
      e -> %{ok: false, input: input, output: "Error: #{Exception.message(e)}"}
    end
  end

  defp validate_user_attrs(attrs) do
    with {:ok, name} <- validate_name(attrs),
         {:ok, email} <- validate_email(attrs),
         {:ok, age} <- validate_age(attrs) do
      {:ok, "{:ok, %User{name: #{inspect(name)}, email: #{inspect(email)}, age: #{age}, role: #{inspect(Map.get(attrs, :role, :user))}}}"}
    else
      {:error, reason} -> {:error, "{:error, #{inspect(reason)}}"}
    end
  end

  defp validate_name(%{name: name}) when is_binary(name) and byte_size(name) > 0,
    do: {:ok, name}
  defp validate_name(_), do: {:error, "name is required and must be non-empty"}

  defp validate_email(%{email: email}) when is_binary(email) do
    if String.contains?(email, "@"), do: {:ok, email},
      else: {:error, "email must contain @"}
  end
  defp validate_email(_), do: {:error, "email is required"}

  defp validate_age(%{age: age}) when is_integer(age) and age > 0 and age < 150,
    do: {:ok, age}
  defp validate_age(_), do: {:error, "age must be an integer between 1 and 149"}

  defp strict_struct_code do
    String.trim("""
    defmodule Strict do
      @enforce_keys [:name, :email]
      defstruct [:name, :email]
    end

    # This raises at compile time!
    %Strict{}
    #=> ** (ArgumentError) the following
    #     keys must also be given when
    #     building struct Strict:
    #     [:name, :email]
    """)
  end
end
