defmodule ElixirKatasWeb.PhoenixKata28HelpersAndAssignsLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    defmodule MyAppWeb.ProductLive.Index do
      use MyAppWeb, :live_view

      # Assigns — pass data to templates via assign/2
      def mount(_params, _session, socket) do
        {:ok,
         assign(socket,
           products: Catalog.list_products(),
           page: 1,
           sort: "name",
           page_title: "Products"
         )}
      end

      # handle_params — update assigns on URL changes
      def handle_params(params, _uri, socket) do
        page = to_int(params["page"], 1)
        sort = params["sort"] || "name"

        {:noreply,
         assign(socket,
           products: Catalog.list_products(page: page, sort: sort),
           page: page,
           sort: sort
         )}
      end

      def render(assigns) do
        ~H\"\"\"
        <h1>{@page_title}</h1>

        <%# patch — same LiveView, new URL/params %>
        <.link :for={sort <- ["name", "price", "newest"]}
          patch={~p"/products?\#{%{sort: sort, page: @page}}"}>
          {String.capitalize(sort)}
        </.link>

        <%# navigate — different LiveView, mounts fresh %>
        <div :for={product <- @products}>
          <.link navigate={~p"/products/\#{product}"}>
            {product.name}
          </.link>
        </div>

        <%# href — full page reload, non-GET methods %>
        <.link href={~p"/logout"} method="delete">Log out</.link>
        \"\"\"
      end

      defp to_int(nil, d), do: d
      defp to_int(s, d) do
        case Integer.parse(s) do
          {n, ""} -> n
          _ -> d
        end
      end
    end

    # Page title — in root layout:
    <.live_title suffix=" - MyApp">
      {assigns[:page_title] || "Home"}
    </.live_title>
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok, assign(socket, active_tab: "assigns", selected_topic: "controller")}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Helpers & Assigns</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Passing data to templates, navigation helpers, and verified routes.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["assigns", "links", "title", "code"]}
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab={tab}
          class={["px-4 py-2 text-sm font-medium rounded-t-lg transition-colors cursor-pointer",
            if(@active_tab == tab,
              do: "bg-teal-50 dark:bg-teal-900/30 text-teal-700 dark:text-teal-400 border-b-2 border-teal-600",
              else: "text-gray-500 hover:text-gray-700 dark:hover:text-gray-300")]}
        >
          {tab_label(tab)}
        </button>
      </div>

      <!-- Assigns -->
      <%= if @active_tab == "assigns" do %>
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            <button :for={topic <- ["controller", "liveview", "template"]}
              phx-click="select_topic"
              phx-target={@myself}
              phx-value-topic={topic}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_topic == topic,
                  do: "bg-teal-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {String.capitalize(topic)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{assigns_code(@selected_topic)}</div>
        </div>
      <% end %>

      <!-- Links -->
      <%= if @active_tab == "links" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Three types of links for different navigation patterns.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="p-4 rounded-lg border border-blue-200 dark:border-blue-800 bg-blue-50 dark:bg-blue-900/20">
              <h4 class="font-semibold text-blue-700 dark:text-blue-300 mb-2">navigate</h4>
              <p class="text-xs text-gray-600 dark:text-gray-300 mb-2">Client-side nav. Mounts new LiveView.</p>
              <div class="bg-gray-900 rounded p-2 font-mono text-xs text-green-400 whitespace-pre">{navigate_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-purple-200 dark:border-purple-800 bg-purple-50 dark:bg-purple-900/20">
              <h4 class="font-semibold text-purple-700 dark:text-purple-300 mb-2">patch</h4>
              <p class="text-xs text-gray-600 dark:text-gray-300 mb-2">Same LiveView, new URL/params.</p>
              <div class="bg-gray-900 rounded p-2 font-mono text-xs text-green-400 whitespace-pre">{patch_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-amber-200 dark:border-amber-800 bg-amber-50 dark:bg-amber-900/20">
              <h4 class="font-semibold text-amber-700 dark:text-amber-300 mb-2">href</h4>
              <p class="text-xs text-gray-600 dark:text-gray-300 mb-2">Full page reload. Non-GET methods.</p>
              <div class="bg-gray-900 rounded p-2 font-mono text-xs text-green-400 whitespace-pre">{href_code()}</div>
            </div>
          </div>

          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-1">When to use which?</p>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              <strong>navigate</strong>: Going to a different page/LiveView. <strong>patch</strong>: Changing params on the same page (pagination, filters, tabs). <strong>href</strong>: Links to non-LiveView pages, logout, external URLs.
            </p>
          </div>
        </div>
      <% end %>

      <!-- Page title -->
      <%= if @active_tab == "title" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Dynamic page titles update the browser tab without a full page reload.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Root Layout</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{title_layout_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Setting Title</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{title_setting_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Example</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{full_code()}</div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("select_topic", %{"topic" => topic}, socket) do
    {:noreply, assign(socket, selected_topic: topic)}
  end

  defp tab_label("assigns"), do: "Assigns"
  defp tab_label("links"), do: "Link Helpers"
  defp tab_label("title"), do: "Page Title"
  defp tab_label("code"), do: "Source Code"

  defp assigns_code("controller") do
    """
    # In controller — pass assigns to render:
    def show(conn, %{"id" => id}) do
      product = Catalog.get_product!(id)

      render(conn, :show,
        product: product,
        page_title: product.name,
        related: Catalog.related_products(product)
      )
    end

    # Or use assign/3:
    def index(conn, params) do
      conn
      |> assign(:products, Catalog.list_products())
      |> assign(:page_title, "All Products")
      |> render(:index)
    end

    # In template: @product, @page_title, @related\
    """
    |> String.trim()
  end

  defp assigns_code("liveview") do
    """
    # In LiveView — use assign/2 or assign/3:
    def mount(_params, _session, socket) do
      {:ok,
       assign(socket,
         products: Catalog.list_products(),
         page: 1,
         loading: false,
         page_title: "Products"
       )}
    end

    def handle_event("next_page", _, socket) do
      page = socket.assigns.page + 1
      {:noreply,
       assign(socket,
         page: page,
         products: Catalog.list_products(page: page)
       )}
    end

    # In template: @products, @page, @loading\
    """
    |> String.trim()
  end

  defp assigns_code("template") do
    """
    <%# Access assigns with @ shorthand: %>
    <h1>{@page_title}</h1>

    <div :for={product <- @products}>
      <h2>{product.name}</h2>
      <p>${product.price}</p>
    </div>

    <%# Check if assign exists: %>
    <p :if={assigns[:subtitle]}>{@subtitle}</p>

    <%# assigns[:key] returns nil if not set %>
    <%# @key raises if not set! %>\
    """
    |> String.trim()
  end

  defp navigate_code do
    """
    <%# New LiveView mount: %>
    <.link navigate={~p"/products"}>
      Products
    </.link>

    <.link navigate={~p"/products/\#{@product}"}>
      View
    </.link>\
    """
    |> String.trim()
  end

  defp patch_code do
    """
    <%# Same LiveView, new params: %>
    <.link patch={~p"/products?\#{%{page: 2}}"}>
      Page 2
    </.link>

    <.link patch={~p"/products?\#{%{sort: "price"}}"}>
      Sort by price
    </.link>\
    """
    |> String.trim()
  end

  defp href_code do
    """
    <%# Full page reload: %>
    <.link href={~p"/about"}>About</.link>

    <%# Non-GET methods: %>
    <.link href={~p"/logout"} method="delete">
      Log out
    </.link>

    <%# External: %>
    <.link href="https://example.com">
      External
    </.link>\
    """
    |> String.trim()
  end

  defp title_layout_code do
    """
    <%# In root.html.heex: %>
    <.live_title>
      {assigns[:page_title] || "MyApp"}
    </.live_title>

    <%# With suffix: %>
    <.live_title suffix=" - MyApp">
      {assigns[:page_title] || "Home"}
    </.live_title>
    <%# Result: "Products - MyApp" %>\
    """
    |> String.trim()
  end

  defp title_setting_code do
    """
    # In controller:
    render(conn, :show, page_title: product.name)

    # In LiveView mount:
    {:ok, assign(socket, page_title: "Products")}

    # In LiveView handle_params:
    def handle_params(%{"id" => id}, _uri, socket) do
      product = Catalog.get_product!(id)
      {:noreply, assign(socket,
        product: product,
        page_title: product.name
      )}
    end\
    """
    |> String.trim()
  end

  defp full_code do
    """
    defmodule MyAppWeb.ProductLive.Index do
      use MyAppWeb, :live_view

      def mount(_params, _session, socket) do
        {:ok,
         assign(socket,
           products: Catalog.list_products(),
           page: 1,
           sort: "name",
           page_title: "Products"
         )}
      end

      def handle_params(params, _uri, socket) do
        page = to_int(params["page"], 1)
        sort = params["sort"] || "name"

        {:noreply,
         assign(socket,
           products: Catalog.list_products(page: page, sort: sort),
           page: page,
           sort: sort
         )}
      end

      def render(assigns) do
        ~H\"\"\"
        <h1>{@page_title}</h1>

        <%# Sort links — use patch (same LiveView) %>
        <div class="flex gap-2 mb-4">
          <.link :for={sort <- ["name", "price", "newest"]}
            patch={~p"/products?\#{%{sort: sort, page: @page}}"}
            class={if @sort == sort, do: "font-bold", else: ""}>
            {String.capitalize(sort)}
          </.link>
        </div>

        <%# Product list %>
        <div :for={product <- @products} class="p-4 border-b">
          <.link navigate={~p"/products/\#{product}"} class="font-semibold">
            {product.name}
          </.link>
          <span class="text-gray-500">${product.price}</span>
        </div>

        <%# Pagination — use patch %>
        <nav class="flex gap-2 mt-4">
          <.link :if={@page > 1}
            patch={~p"/products?\#{%{page: @page - 1, sort: @sort}}"}
            class="px-3 py-1 rounded bg-gray-100">
            Prev
          </.link>
          <span class="px-3 py-1">Page {@page}</span>
          <.link patch={~p"/products?\#{%{page: @page + 1, sort: @sort}}"}
            class="px-3 py-1 rounded bg-gray-100">
            Next
          </.link>
        </nav>
        \"\"\"
      end

      defp to_int(nil, d), do: d
      defp to_int(s, d) do
        case Integer.parse(s) do
          {n, ""} -> n
          _ -> d
        end
      end
    end\
    """
    |> String.trim()
  end
end
