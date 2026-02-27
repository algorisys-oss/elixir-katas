defmodule ElixirKatasWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use ElixirKatasWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  def app(assigns) do
    assigns = assign(assigns, :lv_sections, ElixirKatasWeb.LiveviewKataData.sections())
    current_kata_id = assigns[:kata_id]
    assigns = assign(assigns, :current_kata_id, current_kata_id)

    ~H"""
    <div class="flex h-full bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-gray-100 font-sans">
      <!-- Sidebar -->
      <div id="sidebar" class="w-64 flex-shrink-0 bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700 flex flex-col transition-all duration-300 ease-in-out" data-layout-source="custom-app">
        <div class="flex-1 overflow-y-auto p-4" phx-hook="ScrollPosition" data-scroll-key="sidebar-nav" id="sidebar-nav">
          <nav class="space-y-1">
            <%= for section <- @lv_sections do %>
              <div class="mt-6">
                <h3 class="px-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">
                  {section.title}
                </h3>
                <div class="mt-2 space-y-1 pl-2">
                  <%= for kata <- section.katas do %>
                    <.link
                      navigate={"/liveview-katas/#{kata.slug}"}
                      class={[
                        "group flex items-center px-4 py-2 text-sm font-medium rounded-md",
                        if(kata.num == @current_kata_id,
                          do: "bg-indigo-50 dark:bg-indigo-900/20 text-indigo-700 dark:text-indigo-300 font-semibold",
                          else: "text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700/50 hover:text-gray-900 dark:hover:text-white"
                        )
                      ]}
                    >
                      <span class={["w-2 h-2 mr-3 rounded-full", kata.color]}></span>
                      {kata.label}
                    </.link>
                  <% end %>
                </div>
              </div>
            <% end %>
          </nav>
        </div>
        <div class="p-4 border-t border-gray-200 dark:border-gray-700">
             <div class="flex justify-center">
                <.theme_toggle />
             </div>
        </div>
      </div>

      <!-- Main Content -->
      <div class="flex-1 flex flex-col overflow-hidden relative">
        <div class="flex items-center h-8 px-2 bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
          <button
            id="sidebar-toggle"
            class="p-1 rounded-md hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
            onclick="toggleSidebar()"
            aria-label="Toggle sidebar"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path>
            </svg>
          </button>
        </div>

        <main class="flex-1 overflow-y-auto bg-gray-50 dark:bg-gray-900 p-4 sm:p-6 lg:p-8">
           <.flash_group flash={@flash} />
           <div class="mx-auto max-w-5xl">
             {@inner_content}
           </div>
        </main>
      </div>
    </div>
    <script>
      function toggleSidebar() {
        const sidebar = document.getElementById('sidebar');
        const isHidden = sidebar.classList.contains('-ml-64');
        
        if (isHidden) {
          sidebar.classList.remove('-ml-64');
        } else {
          sidebar.classList.add('-ml-64');
        }
      }
    </script>
    """
  end

  @doc """
  Renders the Elixir Katas layout with a dedicated sidebar.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  def elixir_app(assigns) do
    assigns = assign(assigns, :sections, ElixirKatasWeb.ElixirKataData.sections())
    current_kata_id = assigns[:kata_id]
    assigns = assign(assigns, :current_kata_id, current_kata_id)

    ~H"""
    <div class="flex h-full bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-gray-100 font-sans">
      <!-- Sidebar -->
      <div id="sidebar" class="w-64 flex-shrink-0 bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700 flex flex-col transition-all duration-300 ease-in-out" data-layout-source="elixir-app">
        <div class="flex-1 overflow-y-auto p-4" phx-hook="ScrollPosition" data-scroll-key="elixir-sidebar-nav" id="elixir-sidebar-nav">
          <nav class="space-y-1">
            <%= for section <- @sections do %>
              <div class="mt-6">
                <h3 class="px-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">
                  {section.title}
                </h3>
                <div class="mt-2 space-y-1 pl-2">
                  <%= for kata <- section.katas do %>
                    <.link
                      navigate={"/elixir-katas/#{kata.slug}"}
                      class={[
                        "group flex items-center px-4 py-2 text-sm font-medium rounded-md",
                        if(kata.num == @current_kata_id,
                          do: "bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-300 font-semibold",
                          else: "text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700/50 hover:text-gray-900 dark:hover:text-white"
                        )
                      ]}
                    >
                      <span class={["w-2 h-2 mr-3 rounded-full", kata.color]}></span>
                      {kata.label}
                    </.link>
                  <% end %>
                </div>
              </div>
            <% end %>
          </nav>
        </div>
        <div class="p-4 border-t border-gray-200 dark:border-gray-700">
          <div class="flex justify-center">
            <.theme_toggle />
          </div>
        </div>
      </div>

      <!-- Main Content -->
      <div class="flex-1 flex flex-col overflow-hidden relative">
        <div class="flex items-center h-8 px-2 bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
          <button
            id="elixir-sidebar-toggle"
            class="p-1 rounded-md hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
            onclick="toggleElixirSidebar()"
            aria-label="Toggle sidebar"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path>
            </svg>
          </button>
        </div>

        <main class="flex-1 overflow-y-auto bg-gray-50 dark:bg-gray-900 p-4 sm:p-6 lg:p-8">
          <.flash_group flash={@flash} />
          <div class="mx-auto max-w-5xl">
            {@inner_content}
          </div>
        </main>
      </div>
    </div>
    <script>
      function toggleElixirSidebar() {
        const sidebar = document.getElementById('sidebar');
        const isHidden = sidebar.classList.contains('-ml-64');

        if (isHidden) {
          sidebar.classList.remove('-ml-64');
        } else {
          sidebar.classList.add('-ml-64');
        }
      }
    </script>
    """
  end

  @doc """
  Renders the Phoenix Web Katas layout with a dedicated sidebar.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  def phoenix_app(assigns) do
    assigns = assign(assigns, :sections, ElixirKatasWeb.PhoenixKataData.sections())
    current_kata_id = assigns[:kata_id]
    assigns = assign(assigns, :current_kata_id, current_kata_id)

    implemented =
      Path.wildcard("lib/elixir_katas_web/live/phoenix_kata_*_live.ex")
      |> Enum.map(fn f ->
        case Regex.run(~r/phoenix_kata_(\d+)_/, f) do
          [_, num] -> num
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> MapSet.new()

    assigns = assign(assigns, :implemented, implemented)

    ~H"""
    <div class="flex h-full bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-gray-100 font-sans">
      <!-- Sidebar -->
      <div id="sidebar" class="w-64 flex-shrink-0 bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700 flex flex-col transition-all duration-300 ease-in-out" data-layout-source="phoenix-app">
        <div class="flex-1 overflow-y-auto p-4" phx-hook="ScrollPosition" data-scroll-key="phoenix-sidebar-nav" id="phoenix-sidebar-nav">
          <nav class="space-y-1">
            <%= for section <- @sections do %>
              <div class="mt-6">
                <h3 class="px-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">
                  {section.title}
                </h3>
                <div class="mt-2 space-y-1 pl-2">
                  <%= for kata <- section.katas do %>
                    <%= if MapSet.member?(@implemented, kata.num) do %>
                      <.link
                        navigate={"/phoenix-katas/#{kata.slug}"}
                        class={[
                          "group flex items-center px-4 py-2 text-sm font-medium rounded-md",
                          if(kata.num == @current_kata_id,
                            do: "bg-amber-50 dark:bg-amber-900/20 text-amber-700 dark:text-amber-300 font-semibold",
                            else: "text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700/50 hover:text-gray-900 dark:hover:text-white"
                          )
                        ]}
                      >
                        <span class={["w-2 h-2 mr-3 rounded-full", kata.color]}></span>
                        {kata.label}
                      </.link>
                    <% else %>
                      <span class="group flex items-center px-4 py-2 text-sm font-medium rounded-md text-gray-400 dark:text-gray-600 cursor-not-allowed">
                        <span class="w-2 h-2 mr-3 rounded-full bg-gray-300 dark:bg-gray-600"></span>
                        {kata.label}
                      </span>
                    <% end %>
                  <% end %>
                </div>
              </div>
            <% end %>
          </nav>
        </div>
        <div class="p-4 border-t border-gray-200 dark:border-gray-700">
          <div class="flex justify-center">
            <.theme_toggle />
          </div>
        </div>
      </div>

      <!-- Main Content -->
      <div class="flex-1 flex flex-col overflow-hidden relative">
        <div class="flex items-center h-8 px-2 bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
          <button
            id="phoenix-sidebar-toggle"
            class="p-1 rounded-md hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
            onclick="togglePhoenixSidebar()"
            aria-label="Toggle sidebar"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path>
            </svg>
          </button>
        </div>

        <main class="flex-1 overflow-y-auto bg-gray-50 dark:bg-gray-900 p-4 sm:p-6 lg:p-8">
          <.flash_group flash={@flash} />
          <div class="mx-auto max-w-5xl">
            {@inner_content}
          </div>
        </main>
      </div>
    </div>
    <script>
      function togglePhoenixSidebar() {
        const sidebar = document.getElementById('sidebar');
        const isHidden = sidebar.classList.contains('-ml-64');

        if (isHidden) {
          sidebar.classList.remove('-ml-64');
        } else {
          sidebar.classList.add('-ml-64');
        }
      }
    </script>
    """
  end

  @doc """
  Renders the Phoenix API Katas layout with a dedicated sidebar.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  def phoenix_api_app(assigns) do
    assigns = assign(assigns, :sections, ElixirKatasWeb.PhoenixApiKataData.sections())
    current_kata_id = assigns[:kata_id]
    assigns = assign(assigns, :current_kata_id, current_kata_id)

    implemented =
      Path.wildcard("lib/elixir_katas_web/live/phoenix_api_kata_*_live.ex")
      |> Enum.map(fn f ->
        case Regex.run(~r/phoenix_api_kata_(\d+)_/, f) do
          [_, num] -> num
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> MapSet.new()

    assigns = assign(assigns, :implemented, implemented)

    ~H"""
    <div class="flex h-full bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-gray-100 font-sans">
      <!-- Sidebar -->
      <div id="sidebar" class="w-64 flex-shrink-0 bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700 flex flex-col transition-all duration-300 ease-in-out" data-layout-source="phoenix-api-app">
        <div class="flex-1 overflow-y-auto p-4" phx-hook="ScrollPosition" data-scroll-key="phoenix-api-sidebar-nav" id="phoenix-api-sidebar-nav">
          <nav class="space-y-1">
            <%= for section <- @sections do %>
              <div class="mt-6">
                <h3 class="px-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">
                  {section.title}
                </h3>
                <div class="mt-2 space-y-1 pl-2">
                  <%= for kata <- section.katas do %>
                    <%= if MapSet.member?(@implemented, kata.num) do %>
                      <.link
                        navigate={"/phoenix-api-katas/#{kata.slug}"}
                        class={[
                          "group flex items-center px-4 py-2 text-sm font-medium rounded-md",
                          if(kata.num == @current_kata_id,
                            do: "bg-rose-50 dark:bg-rose-900/20 text-rose-700 dark:text-rose-300 font-semibold",
                            else: "text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700/50 hover:text-gray-900 dark:hover:text-white"
                          )
                        ]}
                      >
                        <span class={["w-2 h-2 mr-3 rounded-full", kata.color]}></span>
                        {kata.label}
                      </.link>
                    <% else %>
                      <span class="group flex items-center px-4 py-2 text-sm font-medium rounded-md text-gray-400 dark:text-gray-600 cursor-not-allowed">
                        <span class="w-2 h-2 mr-3 rounded-full bg-gray-300 dark:bg-gray-600"></span>
                        {kata.label}
                      </span>
                    <% end %>
                  <% end %>
                </div>
              </div>
            <% end %>
          </nav>
        </div>
        <div class="p-4 border-t border-gray-200 dark:border-gray-700">
          <div class="flex justify-center">
            <.theme_toggle />
          </div>
        </div>
      </div>

      <!-- Main Content -->
      <div class="flex-1 flex flex-col overflow-hidden relative">
        <div class="flex items-center h-8 px-2 bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
          <button
            id="phoenix-api-sidebar-toggle"
            class="p-1 rounded-md hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
            onclick="togglePhoenixApiSidebar()"
            aria-label="Toggle sidebar"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path>
            </svg>
          </button>
        </div>

        <main class="flex-1 overflow-y-auto bg-gray-50 dark:bg-gray-900 p-4 sm:p-6 lg:p-8">
          <.flash_group flash={@flash} />
          <div class="mx-auto max-w-5xl">
            {@inner_content}
          </div>
        </main>
      </div>
    </div>
    <script>
      function togglePhoenixApiSidebar() {
        const sidebar = document.getElementById('sidebar');
        const isHidden = sidebar.classList.contains('-ml-64');

        if (isHidden) {
          sidebar.classList.remove('-ml-64');
        } else {
          sidebar.classList.add('-ml-64');
        }
      }
    </script>
    """
  end

  @doc """
  Renders a simple layout for use cases without the katas sidebar.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  def use_case(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={get_csrf_token()} />
        <.live_title suffix=" · Phoenix LiveView Katas">
          {assigns[:page_title] || "Phoenix LiveView Katas"}
        </.live_title>
        <link rel="preconnect" href="https://fonts.googleapis.com">
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
        <link phx-track-static rel="stylesheet" href={~p"/assets/css/app.css"} />
        <style>
          body { font-family: 'Inter', sans-serif; }
        </style>
        <script defer phx-track-static type="text/javascript" src={~p"/assets/js/app.js"}>
        </script>
        <script>
          (() => {
            const setTheme = (theme) => {
              if (theme === "system") {
                localStorage.removeItem("phx:theme");
                document.documentElement.removeAttribute("data-theme");
              } else {
                localStorage.setItem("phx:theme", theme);
                document.documentElement.setAttribute("data-theme", theme);
              }
            };
            if (!document.documentElement.hasAttribute("data-theme")) {
              setTheme(localStorage.getItem("phx:theme") || "system");
            }
            window.addEventListener("storage", (e) => e.key === "phx:theme" && setTheme(e.newValue || "system"));
            
            window.addEventListener("phx:set-theme", (e) => setTheme(e.target.dataset.phxTheme));
          })();
        </script>
      </head>
      <body>
        <div class="min-h-screen bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-gray-100">
          <!-- Header -->
          <header class="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
              <div class="flex items-center space-x-4">
                <.link navigate="/" class="text-xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-purple-600 to-pink-600">
                  Phoenix LiveView Katas
                </.link>
                <span class="text-gray-400">|</span>
                <.link navigate="/usecases" class="text-sm text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white">
                  ← Back to Use Cases
                </.link>
              </div>
              <div class="flex items-center space-x-4">
                <%= if assigns[:current_scope] && assigns.current_scope.user do %>
                  <span class="text-sm text-gray-600 dark:text-gray-300"><%= assigns.current_scope.user.email %></span>
                  <.link href="/users/log-out" method="delete" class="text-sm text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white">
                    Log out
                  </.link>
                <% else %>
                  <.link navigate="/users/log-in" class="text-sm text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white">
                    Log in
                  </.link>
                <% end %>
              </div>
            </div>
          </header>

          <!-- Main Content -->
          <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
            <.flash_group flash={@flash} />
            {@inner_content}
          </main>
        </div>
      </body>
    </html>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
        title="System"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
        title="Light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
        title="Dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
