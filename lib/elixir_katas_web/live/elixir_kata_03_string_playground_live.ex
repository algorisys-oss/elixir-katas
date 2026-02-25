defmodule ElixirKatasWeb.ElixirKata03StringPlaygroundLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign(active_tab: "notes")
     |> assign(input: "Hello, Elixir!")
     |> assign(second_input: " World")
     |> assign(search_term: "Elixir")}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <div class="max-w-4xl mx-auto">
        <!-- Header -->
        <div class="text-center mb-8">
          <h2 class="text-3xl font-bold mb-2">String Playground</h2>
          <p class="text-base-content/60">
            Type a string and see Elixir's <code>String</code> module functions applied in real time.
          </p>
        </div>

        <!-- Main Input -->
        <div class="card bg-base-200 shadow-xl mb-8">
          <div class="card-body">
            <h3 class="card-title">Input String</h3>
            <form phx-change="update_input" phx-target={@myself}>
              <input
                type="text"
                name="value"
                value={@input}
                placeholder="Type something..."
                class="input input-bordered input-lg w-full font-mono text-xl"
              />
            </form>
            <div class="mt-2 text-sm text-base-content/50 font-mono">
              Raw value: <code>{inspect(@input)}</code>
            </div>
          </div>
        </div>

        <!-- String Functions Dashboard -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8">
          <!-- String.length -->
          <div class="card bg-base-200 border border-base-300">
            <div class="card-body p-4">
              <div class="flex items-center justify-between">
                <code class="text-sm font-semibold text-blue-500">String.length/1</code>
                <div class="badge badge-info badge-lg font-mono">{String.length(@input)}</div>
              </div>
              <p class="text-xs text-base-content/50 mt-1">
                Returns the number of Unicode graphemes.
              </p>
            </div>
          </div>

          <!-- String.upcase -->
          <div class="card bg-base-200 border border-base-300">
            <div class="card-body p-4">
              <div class="flex items-center justify-between">
                <code class="text-sm font-semibold text-green-500">String.upcase/1</code>
              </div>
              <div class="font-mono bg-base-300 rounded px-3 py-2 mt-2 break-all">
                {String.upcase(@input)}
              </div>
            </div>
          </div>

          <!-- String.downcase -->
          <div class="card bg-base-200 border border-base-300">
            <div class="card-body p-4">
              <div class="flex items-center justify-between">
                <code class="text-sm font-semibold text-purple-500">String.downcase/1</code>
              </div>
              <div class="font-mono bg-base-300 rounded px-3 py-2 mt-2 break-all">
                {String.downcase(@input)}
              </div>
            </div>
          </div>

          <!-- String.reverse -->
          <div class="card bg-base-200 border border-base-300">
            <div class="card-body p-4">
              <div class="flex items-center justify-between">
                <code class="text-sm font-semibold text-rose-500">String.reverse/1</code>
              </div>
              <div class="font-mono bg-base-300 rounded px-3 py-2 mt-2 break-all">
                {String.reverse(@input)}
              </div>
            </div>
          </div>

          <!-- String.trim -->
          <div class="card bg-base-200 border border-base-300">
            <div class="card-body p-4">
              <div class="flex items-center justify-between">
                <code class="text-sm font-semibold text-amber-500">String.trim/1</code>
              </div>
              <div class="font-mono bg-base-300 rounded px-3 py-2 mt-2 break-all">
                "<span class="text-amber-500">{String.trim(@input)}</span>"
              </div>
              <p class="text-xs text-base-content/50 mt-1">
                Try adding spaces at the start or end of your input.
              </p>
            </div>
          </div>

          <!-- String.first -->
          <div class="card bg-base-200 border border-base-300">
            <div class="card-body p-4">
              <div class="flex items-center justify-between">
                <code class="text-sm font-semibold text-cyan-500">String.first/1</code>
                <div class="badge badge-accent badge-lg font-mono">
                  {if @input == "", do: "nil", else: inspect(String.first(@input))}
                </div>
              </div>
              <p class="text-xs text-base-content/50 mt-1">
                Returns the first Unicode grapheme, or nil for empty strings.
              </p>
            </div>
          </div>

          <!-- String.split -->
          <div class="card bg-base-200 border border-base-300 md:col-span-2">
            <div class="card-body p-4">
              <div class="flex items-center justify-between">
                <code class="text-sm font-semibold text-emerald-500">String.split/1</code>
              </div>
              <div class="flex flex-wrap gap-2 mt-2">
                <span
                  :for={word <- String.split(@input)}
                  class="badge badge-outline badge-lg font-mono"
                >
                  "{word}"
                </span>
                <span :if={@input == ""} class="text-sm text-base-content/40 italic">
                  (empty string produces [""])
                </span>
              </div>
              <p class="text-xs text-base-content/50 mt-2">
                Splits on whitespace by default. Returns a list of strings.
              </p>
            </div>
          </div>

          <!-- String.capitalize -->
          <div class="card bg-base-200 border border-base-300">
            <div class="card-body p-4">
              <div class="flex items-center justify-between">
                <code class="text-sm font-semibold text-pink-500">String.capitalize/1</code>
              </div>
              <div class="font-mono bg-base-300 rounded px-3 py-2 mt-2 break-all">
                {String.capitalize(@input)}
              </div>
            </div>
          </div>

          <!-- String.duplicate -->
          <div class="card bg-base-200 border border-base-300">
            <div class="card-body p-4">
              <div class="flex items-center justify-between">
                <code class="text-sm font-semibold text-indigo-500">String.duplicate/2</code>
              </div>
              <div class="font-mono bg-base-300 rounded px-3 py-2 mt-2 break-all text-sm">
                {String.duplicate(String.first(@input) || "", 5)}
              </div>
              <p class="text-xs text-base-content/50 mt-1">
                Duplicating the first character 5 times.
              </p>
            </div>
          </div>
        </div>

        <!-- Contains Check -->
        <div class="card bg-base-200 shadow-xl mb-8">
          <div class="card-body">
            <h3 class="card-title">String.contains?/2</h3>
            <form phx-change="update_search" phx-target={@myself} class="flex gap-4 items-end">
              <div class="form-control flex-1">
                <label class="label">
                  <span class="label-text">Search for substring</span>
                </label>
                <input
                  type="text"
                  name="search"
                  value={@search_term}
                  placeholder="Search term..."
                  class="input input-bordered font-mono"
                />
              </div>
            </form>
            <div class="mt-4 flex items-center gap-3">
              <code class="text-sm">
                String.contains?({inspect(@input)}, {inspect(@search_term)})
              </code>
              <span class="text-lg">=</span>
              <span class={[
                "badge badge-lg font-bold",
                if(String.contains?(@input, @search_term), do: "badge-success", else: "badge-error")
              ]}>
                {inspect(String.contains?(@input, @search_term))}
              </span>
            </div>
          </div>
        </div>

        <!-- Concatenation Section -->
        <div class="card bg-base-200 shadow-xl mb-8">
          <div class="card-body">
            <h3 class="card-title">String Concatenation with <code>&lt;&gt;</code></h3>
            <form phx-change="update_concat" phx-target={@myself}>
              <div class="flex flex-col sm:flex-row gap-4 items-end">
                <div class="form-control flex-1">
                  <label class="label">
                    <span class="label-text">First string</span>
                  </label>
                  <input
                    type="text"
                    name="first"
                    value={@input}
                    class="input input-bordered font-mono"
                    readonly
                  />
                </div>
                <div class="flex items-center">
                  <span class="text-2xl font-bold text-primary">&lt;&gt;</span>
                </div>
                <div class="form-control flex-1">
                  <label class="label">
                    <span class="label-text">Second string</span>
                  </label>
                  <input
                    type="text"
                    name="second"
                    value={@second_input}
                    class="input input-bordered font-mono"
                    placeholder="Second string..."
                  />
                </div>
              </div>
            </form>
            <div class="mt-4 p-4 bg-base-300 rounded-lg">
              <div class="text-sm text-base-content/60 mb-1">Result:</div>
              <div class="font-mono text-xl text-primary font-bold break-all">
                "{@input <> @second_input}"
              </div>
              <div class="text-xs text-base-content/50 mt-2 font-mono">
                {inspect(@input)} &lt;&gt; {inspect(@second_input)} = {inspect(@input <> @second_input)}
              </div>
            </div>
          </div>
        </div>

        <!-- Interpolation Section -->
        <div class="card bg-base-200 shadow-xl mb-8">
          <div class="card-body">
            <h3 class="card-title">String Interpolation</h3>
            <p class="text-sm text-base-content/60 mb-3">
              Elixir supports string interpolation with <code>#&#123;expression&#125;</code> inside double-quoted strings.
            </p>
            <div class="bg-base-300 rounded-lg p-4 font-mono">
              <div class="text-sm text-base-content/50 mb-2">Template:</div>
              <code>"The string has #&#123;String.length(input)&#125; characters"</code>
              <div class="divider my-2"></div>
              <div class="text-sm text-base-content/50 mb-2">Output:</div>
              <span class="text-primary font-bold">
                "The string has {String.length(@input)} characters"
              </span>
            </div>
          </div>
        </div>

        <!-- Key Insight -->
        <div class="alert alert-info">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-6 h-6">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          <div>
            <h4 class="font-bold">Key Insight</h4>
            <p class="text-sm">
              Elixir strings are UTF-8 encoded binaries. That is why <code>is_binary("hello")</code> returns <code>true</code>.
              <code>String.length/1</code> counts graphemes (user-perceived characters), while
              <code>byte_size/1</code> counts bytes. For ASCII they are the same, but for
              multibyte characters like emoji they differ.
              Your input is <strong>{String.length(@input)}</strong> graphemes and <strong>{byte_size(@input)}</strong> bytes.
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("update_input", %{"value" => value}, socket) do
    {:noreply, assign(socket, input: value)}
  end

  def handle_event("update_search", %{"search" => search}, socket) do
    {:noreply, assign(socket, search_term: search)}
  end

  def handle_event("update_concat", %{"second" => second}, socket) do
    {:noreply, assign(socket, second_input: second)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
