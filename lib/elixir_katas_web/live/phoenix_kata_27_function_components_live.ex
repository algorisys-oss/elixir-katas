defmodule ElixirKatasWeb.PhoenixKata27FunctionComponentsLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    defmodule MyAppWeb.CoreComponents do
      use Phoenix.Component

      # --- Badge with typed attributes ---
      attr :label, :string, required: true
      attr :variant, :string, default: "info", values: ~w(info success warning danger)

      def badge(assigns) do
        ~H\"\"\"
        <span class={["px-2 py-1 rounded-full text-xs font-bold", variant_class(@variant)]}>
          {@label}
        </span>
        \"\"\"
      end

      # --- Button with slots and global attrs ---
      attr :type, :string, default: "button"
      attr :rest, :global
      slot :inner_block, required: true

      def button(assigns) do
        ~H\"\"\"
        <button type={@type} class="px-4 py-2 rounded font-medium" {@rest}>
          {render_slot(@inner_block)}
        </button>
        \"\"\"
      end

      # --- Card with named slots ---
      slot :title
      slot :actions
      slot :inner_block, required: true

      def card(assigns) do
        ~H\"\"\"
        <div class="rounded-lg border bg-white shadow">
          <div :if={@title != []} class="px-4 py-3 border-b flex justify-between">
            <h3 class="font-semibold">{render_slot(@title)}</h3>
            <div :if={@actions != []}>{render_slot(@actions)}</div>
          </div>
          <div class="p-4">{render_slot(@inner_block)}</div>
        </div>
        \"\"\"
      end

      # --- Table with slot arguments ---
      attr :rows, :list, required: true
      slot :col, required: true do
        attr :label, :string, required: true
      end

      def table(assigns) do
        ~H\"\"\"
        <table>
          <thead>
            <tr>
              <th :for={col <- @col}>{col.label}</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={row <- @rows}>
              <td :for={col <- @col}>{render_slot(col, row)}</td>
            </tr>
          </tbody>
        </table>
        \"\"\"
      end

      # Usage:
      # <.badge label="New" />
      # <.button>Click me</.button>
      # <.card><:title>Hello</:title>Content</.card>
      # <.table rows={@products}>
      #   <:col :let={product} label="Name">{product.name}</:col>
      #   <:col :let={product} label="Price">${product.price}</:col>
      # </.table>

      defp variant_class("info"), do: "bg-blue-100 text-blue-700"
      defp variant_class("success"), do: "bg-green-100 text-green-700"
      defp variant_class("warning"), do: "bg-amber-100 text-amber-700"
      defp variant_class("danger"), do: "bg-red-100 text-red-700"
    end
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok,
     assign(socket,
       active_tab: "basics",
       selected_topic: "simple"
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Function Components</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Reusable UI pieces defined as functions. Accept attributes and slots, compose like HTML elements.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["basics", "attrs", "slots", "code"]}
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

      <!-- Basics -->
      <%= if @active_tab == "basics" do %>
        <div class="space-y-4">
          <div class="flex flex-wrap gap-2">
            <button :for={topic <- ["simple", "with_attrs", "composition", "remote"]}
              phx-click="select_topic"
              phx-target={@myself}
              phx-value-topic={topic}
              class={["px-3 py-2 rounded-lg text-xs font-medium cursor-pointer transition-colors",
                if(@selected_topic == topic,
                  do: "bg-teal-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600")]}
            >
              {topic_label(topic)}
            </button>
          </div>

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{topic_code(@selected_topic)}</div>
        </div>
      <% end %>

      <!-- Attributes -->
      <%= if @active_tab == "attrs" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Declare typed attributes with <code>attr</code> — Phoenix validates them at compile time.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Attribute Declaration</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{attr_declaration_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Attribute Types</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{attr_types_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 md:col-span-2">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Global Attributes (:global)</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{global_attrs_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Slots -->
      <%= if @active_tab == "slots" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Slots let you pass content blocks into components. Like children in React.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Default Slot</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{default_slot_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Named Slots</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{named_slots_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 md:col-span-2">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Slot with Arguments</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{slot_args_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Component Library Example</h4>
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

  defp tab_label("basics"), do: "Basics"
  defp tab_label("attrs"), do: "Attributes"
  defp tab_label("slots"), do: "Slots"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("simple"), do: "Simple"
  defp topic_label("with_attrs"), do: "With Attrs"
  defp topic_label("composition"), do: "Composition"
  defp topic_label("remote"), do: "Remote"

  defp topic_code("simple") do
    """
    # Define a function component:
    def badge(assigns) do
      ~H\"\"\"
      <span class="px-2 py-1 rounded-full text-xs font-bold bg-blue-100 text-blue-700">
        {@label}
      </span>
      \"\"\"
    end

    # Usage:
    <.badge label="New" />
    <.badge label={@product.status} />\
    """
    |> String.trim()
  end

  defp topic_code("with_attrs") do
    """
    # Declare attributes with types and defaults:
    attr :label, :string, required: true
    attr :variant, :string, default: "info"
    attr :size, :string, default: "md"

    def badge(assigns) do
      ~H\"\"\"
      <span class={[
        "rounded-full font-bold",
        size_class(@size),
        variant_class(@variant)
      ]}>
        {@label}
      </span>
      \"\"\"
    end

    # Usage:
    <.badge label="New" />
    <.badge label="Error" variant="danger" size="lg" />\
    """
    |> String.trim()
  end

  defp topic_code("composition") do
    """
    # Components can use other components:
    def page_header(assigns) do
      ~H\"\"\"
      <div class="mb-6">
        <h1 class="text-2xl font-bold">{@title}</h1>
        <p :if={assigns[:subtitle]} class="text-gray-500">{@subtitle}</p>
      </div>
      \"\"\"
    end

    def product_page(assigns) do
      ~H\"\"\"
      <.page_header title="Products" subtitle="Browse our catalog" />

      <div class="grid grid-cols-3 gap-4">
        <.card :for={product <- @products}>
          <:title>{product.name}</:title>
          <p>{product.description}</p>
        </.card>
      </div>
      \"\"\"
    end\
    """
    |> String.trim()
  end

  defp topic_code("remote") do
    """
    # Same module — dot prefix:
    <.button label="Click" />

    # From another module:
    <MyAppWeb.CoreComponents.button label="Click" />

    # With import at module level:
    import MyAppWeb.CoreComponents
    # Then use:
    <.button label="Click" />

    # Phoenix auto-imports CoreComponents in all views/templates\
    """
    |> String.trim()
  end

  defp attr_declaration_code do
    """
    attr :name, :string, required: true
    attr :age, :integer, default: 0
    attr :role, :atom, values: [:admin, :user, :guest]
    attr :tags, :list, default: []
    attr :metadata, :map, default: %{}
    attr :active, :boolean, default: true
    attr :on_click, :any  # Event handler
    attr :rest, :global   # Catch-all

    def user_card(assigns) do
      ~H\"\"\"
      <div {@rest}>
        <h3>{@name}</h3>
        <p>Age: {@age}</p>
        <.badge :for={tag <- @tags} label={tag} />
      </div>
      \"\"\"
    end\
    """
    |> String.trim()
  end

  defp attr_types_code do
    """
    # Type        Example values
    :string     # "hello"
    :integer    # 42
    :float      # 3.14
    :boolean    # true / false
    :atom       # :info, :error
    :list       # [1, 2, 3]
    :map        # %{key: "val"}
    :any        # anything
    :global     # extra HTML attrs

    # Options:
    required: true      # must be provided
    default: "value"    # default if not given
    values: [...]       # allowed values
    doc: "Description"  # documentation\
    """
    |> String.trim()
  end

  defp global_attrs_code do
    """
    # :global catches extra HTML attributes:
    attr :label, :string, required: true
    attr :rest, :global, include: ~w(disabled form)

    def input(assigns) do
      ~H\"\"\"
      <input value={@label} {@rest} />
      \"\"\"
    end

    # Usage — extra attrs pass through:
    <.input label="Name" class="w-full" id="name" disabled={@loading} />
    # Renders: <input value="Name" class="w-full" id="name" disabled />

    # :global automatically includes: class, style, id, data-*, aria-*\
    """
    |> String.trim()
  end

  defp default_slot_code do
    """
    # inner_block is the default slot:
    slot :inner_block, required: true

    def card(assigns) do
      ~H\"\"\"
      <div class="p-4 rounded-lg border bg-white shadow">
        {render_slot(@inner_block)}
      </div>
      \"\"\"
    end

    # Usage:
    <.card>
      <h2>Card Title</h2>
      <p>Card content goes here.</p>
    </.card>\
    """
    |> String.trim()
  end

  defp named_slots_code do
    """
    slot :title, required: true
    slot :actions
    slot :inner_block, required: true

    def card(assigns) do
      ~H\"\"\"
      <div class="rounded-lg border bg-white shadow">
        <div class="px-4 py-3 border-b flex justify-between">
          <h3 class="font-semibold">
            {render_slot(@title)}
          </h3>
          <div :if={@actions != []}>
            {render_slot(@actions)}
          </div>
        </div>
        <div class="p-4">
          {render_slot(@inner_block)}
        </div>
      </div>
      \"\"\"
    end

    # Usage:
    <.card>
      <:title>Product Details</:title>
      <:actions><button>Edit</button></:actions>
      <p>Description here.</p>
    </.card>\
    """
    |> String.trim()
  end

  defp slot_args_code do
    """
    # Pass data back to slot consumers:
    slot :col, required: true do
      attr :label, :string, required: true
    end

    def table(assigns) do
      ~H\"\"\"
      <table>
        <thead>
          <tr>
            <th :for={col <- @col}>{col.label}</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={row <- @rows}>
            <td :for={col <- @col}>
              {render_slot(col, row)}
            </td>
          </tr>
        </tbody>
      </table>
      \"\"\"
    end

    # Usage:
    <.table rows={@products}>
      <:col :let={product} label="Name">{product.name}</:col>
      <:col :let={product} label="Price">${product.price}</:col>
    </.table>\
    """
    |> String.trim()
  end

  defp full_code do
    """
    defmodule MyAppWeb.CoreComponents do
      use Phoenix.Component

      # --- Badge ---
      attr :label, :string, required: true
      attr :variant, :string, default: "info", values: ~w(info success warning danger)

      def badge(assigns) do
        ~H\"\"\"
        <span class={["px-2 py-1 rounded-full text-xs font-bold", variant_class(@variant)]}>
          {@label}
        </span>
        \"\"\"
      end

      # --- Button ---
      attr :type, :string, default: "button"
      attr :variant, :string, default: "primary"
      attr :rest, :global
      slot :inner_block, required: true

      def button(assigns) do
        ~H\"\"\"
        <button type={@type} class={["px-4 py-2 rounded font-medium", btn_class(@variant)]} {@rest}>
          {render_slot(@inner_block)}
        </button>
        \"\"\"
      end

      # --- Card ---
      slot :title
      slot :actions
      slot :inner_block, required: true

      def card(assigns) do
        ~H\"\"\"
        <div class="rounded-lg border bg-white dark:bg-gray-800 shadow">
          <div :if={@title != []} class="px-4 py-3 border-b flex justify-between items-center">
            <h3 class="font-semibold">{render_slot(@title)}</h3>
            <div :if={@actions != []}>{render_slot(@actions)}</div>
          </div>
          <div class="p-4">{render_slot(@inner_block)}</div>
        </div>
        \"\"\"
      end

      # --- Table ---
      attr :rows, :list, required: true
      slot :col, required: true do
        attr :label, :string, required: true
      end

      def table(assigns) do
        ~H\"\"\"
        <table class="w-full">
          <thead>
            <tr class="border-b">
              <th :for={col <- @col} class="text-left py-2 px-3">{col.label}</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={row <- @rows} class="border-b hover:bg-gray-50">
              <td :for={col <- @col} class="py-2 px-3">{render_slot(col, row)}</td>
            </tr>
          </tbody>
        </table>
        \"\"\"
      end

      defp variant_class("info"), do: "bg-blue-100 text-blue-700"
      defp variant_class("success"), do: "bg-green-100 text-green-700"
      defp variant_class("warning"), do: "bg-amber-100 text-amber-700"
      defp variant_class("danger"), do: "bg-red-100 text-red-700"

      defp btn_class("primary"), do: "bg-blue-600 text-white hover:bg-blue-700"
      defp btn_class("secondary"), do: "bg-gray-200 text-gray-700 hover:bg-gray-300"
      defp btn_class("danger"), do: "bg-red-600 text-white hover:bg-red-700"
    end\
    """
    |> String.trim()
  end
end
