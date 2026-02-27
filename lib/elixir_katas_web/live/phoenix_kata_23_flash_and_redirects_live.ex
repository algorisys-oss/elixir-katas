defmodule ElixirKatasWeb.PhoenixKata23FlashAndRedirectsLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    defmodule MyAppWeb.ProductController do
      use MyAppWeb, :controller

      def create(conn, %{"product" => params}) do
        case Catalog.create_product(params) do
          {:ok, product} ->
            conn
            |> put_flash(:info, "Product created!")
            |> redirect(to: ~p"/products/\#{product}")

          {:error, changeset} ->
            # Don't redirect on failure — re-render with errors
            render(conn, :new, changeset: changeset)
        end
      end

      def update(conn, %{"id" => id, "product" => params}) do
        product = Catalog.get_product!(id)

        case Catalog.update_product(product, params) do
          {:ok, product} ->
            conn
            |> put_flash(:info, "Product updated!")
            |> redirect(to: ~p"/products/\#{product}")

          {:error, changeset} ->
            render(conn, :edit, product: product, changeset: changeset)
        end
      end

      def delete(conn, %{"id" => id}) do
        product = Catalog.get_product!(id)
        {:ok, _} = Catalog.delete_product(product)

        conn
        |> put_flash(:info, "Product deleted.")
        |> redirect(to: ~p"/products")
      end
    end

    # In LiveView — use socket, not conn:
    def handle_event("save", %{"product" => params}, socket) do
      case Catalog.create_product(params) do
        {:ok, product} ->
          {:noreply,
           socket
           |> put_flash(:info, "Saved!")
           |> push_navigate(to: ~p"/products/\#{product}")}

        {:error, changeset} ->
          {:noreply,
           socket
           |> put_flash(:error, "Could not save.")
           |> assign(:changeset, changeset)}
      end
    end
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok,
     assign(socket,
       active_tab: "flash",
       selected_pattern: "create_success",
       prg_step: 0
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Flash Messages & Redirects</h2>
      <p class="text-gray-600 dark:text-gray-300">
        One-time notifications and the Post/Redirect/Get pattern for safe form handling.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["flash", "prg", "patterns", "code"]}
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

      <!-- Flash messages -->
      <%= if @active_tab == "flash" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Flash messages display once after an action and are automatically cleared.
          </p>

          <!-- Flash preview -->
          <div class="space-y-3">
            <div class="p-3 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 flex items-center gap-3">
              <span class="text-green-600 dark:text-green-400 text-lg font-bold">i</span>
              <p class="text-sm text-green-700 dark:text-green-300">Product created successfully!</p>
              <span class="ml-auto text-xs px-2 py-0.5 rounded bg-green-100 dark:bg-green-900 text-green-600 dark:text-green-400">:info</span>
            </div>
            <div class="p-3 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 flex items-center gap-3">
              <span class="text-red-600 dark:text-red-400 text-lg font-bold">!</span>
              <p class="text-sm text-red-700 dark:text-red-300">Could not create product. Please fix the errors below.</p>
              <span class="ml-auto text-xs px-2 py-0.5 rounded bg-red-100 dark:bg-red-900 text-red-600 dark:text-red-400">:error</span>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Setting Flash</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{set_flash_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Displaying Flash</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{display_flash_code()}</div>
            </div>
          </div>

          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-1">Flash lifecycle</p>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              Flash data is stored in the session. After one request reads and displays it, it's automatically cleared.
              That's why it "survives" a redirect but disappears after the next page load.
            </p>
          </div>
        </div>
      <% end %>

      <!-- PRG Pattern -->
      <%= if @active_tab == "prg" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            <strong>Post/Redirect/Get</strong> prevents duplicate form submissions. Step through to see why.
          </p>

          <div class="flex gap-2">
            <button phx-click="prg_step" phx-target={@myself}
              class="px-4 py-2 rounded-lg text-sm font-medium bg-teal-600 text-white hover:bg-teal-700 cursor-pointer disabled:opacity-50"
              disabled={@prg_step >= 4}>
              Next Step
            </button>
            <button phx-click="prg_reset" phx-target={@myself}
              class="px-4 py-2 rounded-lg text-sm font-medium bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 cursor-pointer">
              Reset
            </button>
          </div>

          <!-- PRG flow diagram -->
          <div class="space-y-1 max-w-lg">
            <.prg_step num={1} title="User submits form" detail="POST /products" current={@prg_step} />
            <.prg_arrow />
            <.prg_step num={2} title="Server creates record" detail="Catalog.create_product(params)" current={@prg_step} />
            <.prg_arrow />
            <.prg_step num={3} title="Server sends 302 redirect" detail="redirect(conn, to: /products/42)" current={@prg_step} />
            <.prg_arrow />
            <.prg_step num={4} title="Browser follows redirect" detail="GET /products/42 — safe to refresh!" current={@prg_step} />
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
            <div class="p-4 rounded-lg border-2 border-red-200 dark:border-red-800 bg-red-50 dark:bg-red-900/10">
              <h4 class="font-semibold text-red-700 dark:text-red-300 mb-2">Without PRG</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{without_prg_code()}</div>
              <p class="text-xs text-red-600 dark:text-red-400 mt-2">Refresh = re-submit POST = duplicate record!</p>
            </div>
            <div class="p-4 rounded-lg border-2 border-green-200 dark:border-green-800 bg-green-50 dark:bg-green-900/10">
              <h4 class="font-semibold text-green-700 dark:text-green-300 mb-2">With PRG</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{with_prg_code()}</div>
              <p class="text-xs text-green-600 dark:text-green-400 mt-2">Refresh = re-GET = safe!</p>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Common patterns -->
      <%= if @active_tab == "patterns" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Common flash + redirect patterns for different scenarios.
          </p>

          <div class="flex flex-wrap gap-2">
            <button :for={pattern <- ["create_success", "update_success", "delete", "validation_fail", "liveview", "redirect_back"]}
              phx-click="select_pattern"
              phx-target={@myself}
              phx-value-pattern={pattern}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_pattern == pattern,
                  do: "bg-teal-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {pattern_label(pattern)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{pattern_code(@selected_pattern)}</div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Controller with Flash & Redirects</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{full_code()}</div>
        </div>
      <% end %>
    </div>
    """
  end

  attr :num, :integer, required: true
  attr :title, :string, required: true
  attr :detail, :string, required: true
  attr :current, :integer, required: true

  defp prg_step(assigns) do
    ~H"""
    <div class={["flex items-start gap-3 p-3 rounded-lg transition-all",
      cond do
        @num < @current -> "bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800"
        @num == @current -> "bg-teal-50 dark:bg-teal-900/20 border-2 border-teal-400 ring-2 ring-teal-200"
        true -> "bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700"
      end]}>
      <span class={["w-6 h-6 rounded-full flex items-center justify-center text-xs flex-shrink-0",
        cond do
          @num < @current -> "bg-green-500 text-white"
          @num == @current -> "bg-teal-500 text-white"
          true -> "bg-gray-300 dark:bg-gray-600 text-gray-500"
        end]}>{@num}</span>
      <div>
        <p class="font-semibold text-sm text-gray-800 dark:text-gray-200">{@title}</p>
        <p class="text-xs text-gray-500 font-mono">{@detail}</p>
      </div>
    </div>
    """
  end

  defp prg_arrow(assigns) do
    ~H"""
    <div class="text-center text-gray-300 dark:text-gray-600 text-xs ml-5">|</div>
    """
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("prg_step", _params, socket) do
    {:noreply, assign(socket, prg_step: min(socket.assigns.prg_step + 1, 4))}
  end

  def handle_event("prg_reset", _params, socket) do
    {:noreply, assign(socket, prg_step: 0)}
  end

  def handle_event("select_pattern", %{"pattern" => pattern}, socket) do
    {:noreply, assign(socket, selected_pattern: pattern)}
  end

  defp tab_label("flash"), do: "Flash Messages"
  defp tab_label("prg"), do: "PRG Pattern"
  defp tab_label("patterns"), do: "Patterns"
  defp tab_label("code"), do: "Source Code"

  defp pattern_label("create_success"), do: "Create"
  defp pattern_label("update_success"), do: "Update"
  defp pattern_label("delete"), do: "Delete"
  defp pattern_label("validation_fail"), do: "Validation Fail"
  defp pattern_label("liveview"), do: "LiveView"
  defp pattern_label("redirect_back"), do: "Redirect Back"

  defp set_flash_code do
    """
    # In controller:
    conn
    |> put_flash(:info, "Success!")
    |> redirect(to: ~p"/products")

    conn
    |> put_flash(:error, "Something went wrong.")
    |> render(:new, changeset: changeset)\
    """
    |> String.trim()
  end

  defp display_flash_code do
    """
    <%# In layout — auto-generated: %>
    <.flash_group flash={@flash} />

    <%# Or manual: %>
    <%= if info = Phoenix.Flash.get(@flash, :info) do %>
      <div class="alert-info"><%= info %></div>
    <% end %>

    <%= if error = Phoenix.Flash.get(@flash, :error) do %>
      <div class="alert-error"><%= error %></div>
    <% end %>\
    """
    |> String.trim()
  end

  defp without_prg_code do
    """
    # BAD: render after POST
    def create(conn, params) do
      product = Catalog.create_product!(params)
      render(conn, :show, product: product)
      # URL is still POST /products
      # Refresh → POST again → duplicate!
    end\
    """
    |> String.trim()
  end

  defp with_prg_code do
    """
    # GOOD: redirect after POST (PRG)
    def create(conn, params) do
      product = Catalog.create_product!(params)
      conn
      |> put_flash(:info, "Created!")
      |> redirect(to: ~p"/products/\#{product}")
      # URL changes to GET /products/42
      # Refresh → GET again → safe!
    end\
    """
    |> String.trim()
  end

  defp pattern_code("create_success") do
    """
    def create(conn, %{"product" => params}) do
      case Catalog.create_product(params) do
        {:ok, product} ->
          conn
          |> put_flash(:info, "Product created successfully!")
          |> redirect(to: ~p"/products/\#{product}")

        {:error, changeset} ->
          # Don't redirect — re-render form with errors
          render(conn, :new, changeset: changeset)
      end
    end\
    """
    |> String.trim()
  end

  defp pattern_code("update_success") do
    """
    def update(conn, %{"id" => id, "product" => params}) do
      product = Catalog.get_product!(id)

      case Catalog.update_product(product, params) do
        {:ok, product} ->
          conn
          |> put_flash(:info, "Product updated!")
          |> redirect(to: ~p"/products/\#{product}")

        {:error, changeset} ->
          render(conn, :edit, product: product, changeset: changeset)
      end
    end\
    """
    |> String.trim()
  end

  defp pattern_code("delete") do
    """
    def delete(conn, %{"id" => id}) do
      product = Catalog.get_product!(id)
      {:ok, _} = Catalog.delete_product(product)

      conn
      |> put_flash(:info, "Product deleted.")
      |> redirect(to: ~p"/products")
    end\
    """
    |> String.trim()
  end

  defp pattern_code("validation_fail") do
    """
    # DON'T redirect on validation failure!
    # Re-render the form so errors are displayed.

    def create(conn, %{"product" => params}) do
      case Catalog.create_product(params) do
        {:ok, product} ->
          redirect(conn, to: ~p"/products/\#{product}")

        {:error, changeset} ->
          # Flash is optional here — the form shows field errors
          conn
          |> put_flash(:error, "Please fix the errors below.")
          |> render(:new, changeset: changeset)
          # User sees the form again with error messages
          # They can fix and re-submit
      end
    end\
    """
    |> String.trim()
  end

  defp pattern_code("liveview") do
    """
    # In LiveView — use socket, not conn:
    def handle_event("save", %{"product" => params}, socket) do
      case Catalog.create_product(params) do
        {:ok, product} ->
          {:noreply,
           socket
           |> put_flash(:info, "Saved!")
           |> push_navigate(to: ~p"/products/\#{product}")}

        {:error, changeset} ->
          {:noreply,
           socket
           |> put_flash(:error, "Could not save.")
           |> assign(:changeset, changeset)}
      end
    end

    # Clear flash manually:
    clear_flash(socket)        # Clear all
    clear_flash(socket, :info) # Clear specific\
    """
    |> String.trim()
  end

  defp pattern_code("redirect_back") do
    """
    # Store the "return to" path in session:
    def new(conn, _params) do
      return_to = conn.request_path
      conn
      |> put_session(:return_to, return_to)
      |> render(:new)
    end

    def create(conn, %{"product" => params}) do
      {:ok, _product} = Catalog.create_product(params)
      return_to = get_session(conn, :return_to) || ~p"/products"

      conn
      |> delete_session(:return_to)
      |> put_flash(:info, "Created!")
      |> redirect(to: return_to)
    end\
    """
    |> String.trim()
  end

  defp full_code do
    """
    defmodule MyAppWeb.ProductController do
      use MyAppWeb, :controller

      def index(conn, _params) do
        products = Catalog.list_products()
        render(conn, :index, products: products)
      end

      def new(conn, _params) do
        changeset = Catalog.change_product(%Product{})
        render(conn, :new, changeset: changeset)
      end

      def create(conn, %{"product" => params}) do
        case Catalog.create_product(params) do
          {:ok, product} ->
            conn
            |> put_flash(:info, "Product created!")
            |> redirect(to: ~p"/products/\#{product}")

          {:error, changeset} ->
            render(conn, :new, changeset: changeset)
        end
      end

      def edit(conn, %{"id" => id}) do
        product = Catalog.get_product!(id)
        changeset = Catalog.change_product(product)
        render(conn, :edit, product: product, changeset: changeset)
      end

      def update(conn, %{"id" => id, "product" => params}) do
        product = Catalog.get_product!(id)

        case Catalog.update_product(product, params) do
          {:ok, product} ->
            conn
            |> put_flash(:info, "Product updated!")
            |> redirect(to: ~p"/products/\#{product}")

          {:error, changeset} ->
            render(conn, :edit, product: product, changeset: changeset)
        end
      end

      def delete(conn, %{"id" => id}) do
        product = Catalog.get_product!(id)
        {:ok, _} = Catalog.delete_product(product)

        conn
        |> put_flash(:info, "Product deleted.")
        |> redirect(to: ~p"/products")
      end
    end\
    """
    |> String.trim()
  end
end
