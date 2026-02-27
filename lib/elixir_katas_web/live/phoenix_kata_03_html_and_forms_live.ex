defmodule ElixirKatasWeb.PhoenixKata03HtmlAndFormsLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    # HTML Forms & HTTP Encoding

    # A simple HTML form:
    <form action="/login" method="POST">
      <label>Username</label>
      <input type="text" name="username" />

      <label>Password</label>
      <input type="password" name="password" />

      <label>
        <input type="checkbox" name="remember" value="true" />
        Remember me
      </label>

      <button type="submit">Submit</button>
    </form>

    # GET: Data goes in the URL as query parameters
    # GET /login?username=alice&password=secret123&remember=true HTTP/1.1
    # Host: example.com
    # Accept: text/html

    # POST: Data goes in the request body (hidden from URL)
    # POST /login HTTP/1.1
    # Host: example.com
    # Content-Type: application/x-www-form-urlencoded
    # Content-Length: 45
    #
    # username=alice&password=secret123&remember=true

    # In your Phoenix controller, both arrive the same way:
    def login(conn, params) do
      # params = %{
      #   "username" => "alice",
      #   "password" => "secret123",
      #   "remember" => "true"
      # }
    end

    # GET vs POST:
    # GET  → data in URL, visible, bookmarkable, ~2KB limit (search, filters)
    # POST → data in body, hidden, not bookmarkable, no limit (login, create)
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok,
     assign(socket,
       form_method: "GET",
       fields: [
         %{name: "username", type: "text", value: "alice"},
         %{name: "password", type: "password", value: "secret123"},
         %{name: "remember", type: "checkbox", value: "true"}
       ],
       submitted: false,
       raw_request: nil
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">HTML Forms Explorer</h2>
      <p class="text-gray-600 dark:text-gray-300">
        See how HTML forms encode data and send it to the server via GET or POST.
      </p>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Form Preview -->
        <div class="space-y-4">
          <h3 class="text-lg font-semibold text-amber-700 dark:text-amber-400">The Form</h3>

          <div class="flex gap-3 mb-4">
            <button
              phx-click="set_form_method"
              phx-target={@myself}
              phx-value-method="GET"
              class={[
                "px-4 py-2 rounded-lg font-medium transition-colors cursor-pointer",
                if(@form_method == "GET", do: "bg-amber-600 text-white", else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300")
              ]}
            >
              GET
            </button>
            <button
              phx-click="set_form_method"
              phx-target={@myself}
              phx-value-method="POST"
              class={[
                "px-4 py-2 rounded-lg font-medium transition-colors cursor-pointer",
                if(@form_method == "POST", do: "bg-amber-600 text-white", else: "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300")
              ]}
            >
              POST
            </button>
          </div>

          <div class="p-6 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 space-y-4">
            <div class="text-sm text-gray-500 dark:text-gray-400 font-mono mb-2">
              &lt;form action="/login" method="{@form_method}"&gt;
            </div>

            <%= for field <- @fields do %>
              <div class="space-y-1">
                <label class="text-sm font-medium text-gray-700 dark:text-gray-300">{field.name}</label>
                <%= if field.type == "checkbox" do %>
                  <div class="flex items-center gap-2">
                    <input type="checkbox" checked class="rounded" disabled />
                    <span class="text-sm text-gray-600 dark:text-gray-400">Remember me</span>
                  </div>
                <% else %>
                  <input
                    type={field.type}
                    value={field.value}
                    disabled
                    class="w-full px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 text-gray-900 dark:text-gray-100"
                  />
                <% end %>
              </div>
            <% end %>

            <div class="text-sm text-gray-500 dark:text-gray-400 font-mono">
              &lt;/form&gt;
            </div>

            <button
              phx-click="submit_form"
              phx-target={@myself}
              class="px-4 py-2 bg-amber-600 hover:bg-amber-700 text-white rounded-lg font-medium transition-colors cursor-pointer"
            >
              Submit Form
            </button>
          </div>

          <!-- HTML Source -->
          <div>
            <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">HTML Source</h4>
            <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-gray-300 overflow-x-auto whitespace-pre">{html_source(@form_method, @fields)}</div>
          </div>
        </div>

        <!-- What Gets Sent -->
        <div class="space-y-4">
          <h3 class="text-lg font-semibold text-amber-700 dark:text-amber-400">What Gets Sent</h3>

          <%= if @submitted do %>
            <%= if @form_method == "GET" do %>
              <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
                <h4 class="font-semibold text-blue-700 dark:text-blue-400 mb-2">GET: Data in the URL</h4>
                <p class="text-sm text-gray-600 dark:text-gray-300 mb-2">
                  With GET, form data is appended to the URL as query parameters:
                </p>
                <code class="text-sm font-mono text-blue-800 dark:text-blue-300 break-all">
                  /login?{encode_fields(@fields)}
                </code>
              </div>
            <% else %>
              <div class="p-4 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
                <h4 class="font-semibold text-green-700 dark:text-green-400 mb-2">POST: Data in the Body</h4>
                <p class="text-sm text-gray-600 dark:text-gray-300 mb-2">
                  With POST, form data is sent in the request body (hidden from the URL):
                </p>
              </div>
            <% end %>

            <!-- Raw HTTP -->
            <div>
              <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">Raw HTTP Request</h4>
              <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 whitespace-pre overflow-x-auto">{raw_http(@form_method, @fields)}</div>
            </div>

            <!-- Phoenix params -->
            <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
              <h4 class="font-semibold text-amber-700 dark:text-amber-400 mb-2">In Phoenix Controller</h4>
              <pre class="text-sm font-mono text-gray-800 dark:text-gray-200 overflow-x-auto">{phoenix_params(@fields)}</pre>
            </div>
          <% else %>
            <div class="flex items-center justify-center h-48 text-gray-400 dark:text-gray-500">
              <p>Click "Submit Form" to see what gets sent</p>
            </div>
          <% end %>

          <!-- GET vs POST comparison -->
          <div class="mt-4">
            <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">GET vs POST</h4>
            <div class="space-y-3">
              <div class="grid grid-cols-3 gap-2 text-sm">
                <div class="font-semibold text-gray-700 dark:text-gray-300"></div>
                <div class="font-semibold text-blue-700 dark:text-blue-400 text-center">GET</div>
                <div class="font-semibold text-green-700 dark:text-green-400 text-center">POST</div>

                <div class="text-gray-600 dark:text-gray-400">Data location</div>
                <div class="text-center">URL</div>
                <div class="text-center">Body</div>

                <div class="text-gray-600 dark:text-gray-400">Visible?</div>
                <div class="text-center">Yes (in URL bar)</div>
                <div class="text-center">No (hidden)</div>

                <div class="text-gray-600 dark:text-gray-400">Bookmarkable?</div>
                <div class="text-center">Yes</div>
                <div class="text-center">No</div>

                <div class="text-gray-600 dark:text-gray-400">Size limit</div>
                <div class="text-center">~2KB (URL length)</div>
                <div class="text-center">No limit</div>

                <div class="text-gray-600 dark:text-gray-400">Use for</div>
                <div class="text-center">Search, filters</div>
                <div class="text-center">Login, create data</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("set_form_method", %{"method" => method}, socket) do
    {:noreply, assign(socket, form_method: method, submitted: false)}
  end

  def handle_event("submit_form", _, socket) do
    {:noreply, assign(socket, submitted: true)}
  end

  defp encode_fields(fields) do
    fields
    |> Enum.map(fn f -> "#{f.name}=#{URI.encode(f.value)}" end)
    |> Enum.join("&")
  end

  defp html_source(method, fields) do
    field_html =
      fields
      |> Enum.map(fn f ->
        case f.type do
          "checkbox" ->
            "  <label>\n    <input type=\"checkbox\" name=\"#{f.name}\" value=\"#{f.value}\" />\n    Remember me\n  </label>"
          _ ->
            "  <label>#{String.capitalize(f.name)}</label>\n  <input type=\"#{f.type}\" name=\"#{f.name}\" />"
        end
      end)
      |> Enum.join("\n\n")

    "<form action=\"/login\" method=\"#{method}\">\n\n#{field_html}\n\n  <button type=\"submit\">Submit</button>\n</form>"
  end

  defp raw_http("GET", fields) do
    encoded = encode_fields(fields)

    """
    GET /login?#{encoded} HTTP/1.1
    Host: example.com
    Accept: text/html
    """
    |> String.trim()
  end

  defp raw_http("POST", fields) do
    encoded = encode_fields(fields)

    """
    POST /login HTTP/1.1
    Host: example.com
    Content-Type: application/x-www-form-urlencoded
    Content-Length: #{byte_size(encoded)}

    #{encoded}\
    """
    |> String.trim()
  end

  defp phoenix_params(fields) do
    params =
      fields
      |> Enum.map(fn f -> "  \"#{f.name}\" => \"#{f.value}\"" end)
      |> Enum.join(",\n")

    "# In your controller action:\ndef login(conn, params) do\n  # params = %{\n#{params}\n  # }\nend"
  end
end
