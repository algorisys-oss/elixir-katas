defmodule ElixirKatasWeb.PhoenixKata25HeexTemplatesLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    <%# HEEx — HTML + Embedded Elixir %>

    <%# Output expressions (auto-escaped for XSS safety): %>
    <h1>{@product.name}</h1>
    <p>Price: ${@product.price}</p>
    <span>{String.upcase(@user.name)}</span>

    <%# :if attribute (preferred over if blocks): %>
    <div :if={@show_sidebar} class="sidebar">
      Sidebar content
    </div>

    <%# :for attribute (preferred over for blocks): %>
    <ul>
      <li :for={product <- @products}>
        {product.name} - ${product.price}
      </li>
    </ul>

    <%# if/else block (when you need else branch): %>
    <%= if @logged_in do %>
      <p>Welcome, {@user.name}!</p>
    <% else %>
      <p>Please log in.</p>
    <% end %>

    <%# Dynamic CSS classes (false/nil filtered out): %>
    <div class={[
      "px-4 py-2 rounded",
      @active && "bg-blue-500 text-white",
      !@active && "bg-gray-100 text-gray-700"
    ]}>
      Content
    </div>

    <%# Dynamic attributes: %>
    <input type="text" name={@field} value={@value} />
    <a href={~p"/products/\#{@product}"}>View</a>

    <%# Boolean attributes: %>
    <button disabled={@loading}>Submit</button>
    <%# disabled={false} → attribute omitted %>
    <%# disabled={true}  → <button disabled>Submit</button> %>

    <%# Case — pattern match in templates: %>
    <%= case @role do %>
      <% :admin -> %>
        <span class="bg-red-100 text-red-700">Admin</span>
      <% _ -> %>
        <span class="bg-gray-100 text-gray-700">User</span>
    <% end %>
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok,
     assign(socket,
       active_tab: "expressions",
       selected_topic: "output"
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">HEEx Templates</h2>
      <p class="text-gray-600 dark:text-gray-300">
        HTML + Embedded Elixir — compile-time validated templates with automatic XSS protection.
      </p>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 dark:border-gray-700">
        <button
          :for={tab <- ["expressions", "control", "attributes", "code"]}
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

      <!-- Expressions -->
      <%= if @active_tab == "expressions" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            HEEx expressions embed Elixir values in HTML. All output is automatically escaped for XSS safety.
          </p>

          <div class="flex flex-wrap gap-2">
            <button :for={topic <- ["output", "assigns", "functions", "escaping"]}
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

          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{expression_code(@selected_topic)}</div>
        </div>
      <% end %>

      <!-- Control flow -->
      <%= if @active_tab == "control" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Conditionals and loops in HEEx. Prefer the attribute syntax (<code>:if</code>, <code>:for</code>) when possible.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">:if attribute (preferred)</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{if_attr_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">if/else block</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{if_block_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">:for attribute (preferred)</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{for_attr_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">for block</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{for_block_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 md:col-span-2">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">case</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{case_code()}</div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Attributes -->
      <%= if @active_tab == "attributes" do %>
        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Dynamic attributes, boolean attributes, and conditional CSS classes.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Dynamic Attributes</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{dynamic_attrs_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Boolean Attributes</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{boolean_attrs_code()}</div>
            </div>
            <div class="p-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 md:col-span-2">
              <h4 class="font-semibold text-gray-700 dark:text-gray-300 mb-2">Dynamic CSS Classes</h4>
              <div class="bg-gray-900 rounded p-3 font-mono text-xs text-green-400 whitespace-pre">{dynamic_classes_code()}</div>
            </div>
          </div>

          <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
            <p class="text-sm font-semibold text-amber-700 dark:text-amber-300 mb-1">Class list filtering</p>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              In a class list, <code>false</code> and <code>nil</code> values are automatically filtered out.
              Only truthy string values are included in the final class attribute.
            </p>
          </div>
        </div>
      <% end %>

      <!-- Full code -->
      <%= if @active_tab == "code" do %>
        <div class="space-y-4">
          <h4 class="font-semibold text-gray-700 dark:text-gray-300">Complete Template Example</h4>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{full_template_code()}</div>
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

  defp tab_label("expressions"), do: "Expressions"
  defp tab_label("control"), do: "Control Flow"
  defp tab_label("attributes"), do: "Attributes"
  defp tab_label("code"), do: "Source Code"

  defp topic_label("output"), do: "Output"
  defp topic_label("assigns"), do: "Assigns"
  defp topic_label("functions"), do: "Functions"
  defp topic_label("escaping"), do: "Escaping"

  defp expression_code("output") do
    """
    <%# Simple value output: %>
    <h1>{@product.name}</h1>
    <p>Price: ${@product.price}</p>

    <%# Expressions: %>
    <span>{String.upcase(@user.name)}</span>
    <p>{length(@items)} items in cart</p>

    <%# String interpolation: %>
    <p>Hello, {@first_name} {@last_name}!</p>\
    """
    |> String.trim()
  end

  defp expression_code("assigns") do
    """
    <%# @name is shorthand for assigns.name %>
    <h1>{@title}</h1>
    <%# Same as: {assigns.title} %>

    <%# In the controller: %>
    <%# render(conn, :show, title: "My Page", user: user) %>

    <%# In the template: %>
    <h1>{@title}</h1>       <%# "My Page" %>
    <p>{@user.name}</p>      <%# user's name %>
    <p>{@user.email}</p>     <%# user's email %>\
    """
    |> String.trim()
  end

  defp expression_code("functions") do
    """
    <%# Call any Elixir function: %>
    <p>{String.upcase(@name)}</p>
    <p>{Enum.count(@products)} products</p>
    <p>{Calendar.strftime(@date, "%B %d, %Y")}</p>

    <%# Helper functions from your view: %>
    <p>{format_price(@product.price)}</p>
    <p>{time_ago(@product.inserted_at)}</p>

    <%# Ternary-style: %>
    <span>{if @online, do: "Online", else: "Offline"}</span>\
    """
    |> String.trim()
  end

  defp expression_code("escaping") do
    """
    <%# ALL output is HTML-escaped by default: %>
    <p>{@user_input}</p>
    <%# If user_input = "<script>alert('xss')</script>" %>
    <%# Output: &lt;script&gt;alert('xss')&lt;/script&gt; %>
    <%# Safe! The script won't execute. %>

    <%# To output raw HTML (DANGEROUS!): %>
    {raw(@trusted_html)}
    <%# Only use with content YOU control! %>
    <%# Never with user input! %>\
    """
    |> String.trim()
  end

  defp if_attr_code do
    """
    <%# :if attribute — clean, preferred %>
    <div :if={@show_sidebar} class="sidebar">
      Sidebar content
    </div>

    <p :if={@error} class="text-red-500">
      {@error}
    </p>

    <%# Element is not rendered if condition is false %>\
    """
    |> String.trim()
  end

  defp if_block_code do
    """
    <%# Block syntax — for if/else %>
    <%= if @logged_in do %>
      <p>Welcome, {@user.name}!</p>
    <% else %>
      <p>Please log in.</p>
    <% end %>

    <%# Use when you need else branch %>\
    """
    |> String.trim()
  end

  defp for_attr_code do
    """
    <%# :for attribute — clean, preferred %>
    <ul>
      <li :for={product <- @products}>
        {product.name} - ${product.price}
      </li>
    </ul>

    <%# With index: %>
    <div :for={{item, idx} <- Enum.with_index(@items)}>
      {idx + 1}. {item.name}
    </div>\
    """
    |> String.trim()
  end

  defp for_block_code do
    """
    <%# Block syntax — traditional %>
    <ul>
      <%= for product <- @products do %>
        <li>{product.name} - ${product.price}</li>
      <% end %>
    </ul>

    <%# Attribute syntax is preferred in modern Phoenix %>\
    """
    |> String.trim()
  end

  defp case_code do
    """
    <%# Case — pattern match in templates %>
    <%= case @role do %>
      <% :admin -> %>
        <span class="px-2 py-1 rounded bg-red-100 text-red-700">Admin</span>
      <% :moderator -> %>
        <span class="px-2 py-1 rounded bg-yellow-100 text-yellow-700">Mod</span>
      <% _ -> %>
        <span class="px-2 py-1 rounded bg-gray-100 text-gray-700">User</span>
    <% end %>\
    """
    |> String.trim()
  end

  defp dynamic_attrs_code do
    """
    <%# Dynamic attribute values: %>
    <input type="text" name={@field} value={@value} />
    <a href={~p"/products/\#{@product}"}>View</a>
    <img src={@avatar_url} alt={@user.name} />

    <%# Spread attributes from a map/keyword: %>
    <input {@rest} />
    <%# @rest = [type: "email", required: true] %>\
    """
    |> String.trim()
  end

  defp boolean_attrs_code do
    """
    <%# Boolean attributes: %>
    <input type="checkbox" checked={@is_checked} />
    <button disabled={@loading}>Submit</button>
    <details open={@expanded}>...</details>

    <%# If value is false/nil → attribute omitted %>
    <%# If value is truthy → attribute present %>

    <%# disabled={false} → <button>Submit</button> %>
    <%# disabled={true}  → <button disabled>Submit</button> %>\
    """
    |> String.trim()
  end

  defp dynamic_classes_code do
    """
    <%# List of classes — false/nil values filtered out: %>
    <div class={[
      "px-4 py-2 rounded",
      @active && "bg-blue-500 text-white",
      @disabled && "opacity-50 cursor-not-allowed",
      !@active && "bg-gray-100 text-gray-700"
    ]}>
      Content
    </div>

    <%# Result when @active=true, @disabled=false: %>
    <%# class="px-4 py-2 rounded bg-blue-500 text-white" %>

    <%# Using if/else inline: %>
    <div class={if @dark, do: "bg-gray-900 text-white", else: "bg-white text-gray-900"}>
      Content
    </div>\
    """
    |> String.trim()
  end

  defp full_template_code do
    """
    <%# products/index.html.heex %>
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-6">{@page_title}</h1>

      <%# Flash messages %>
      <div :if={info = Phoenix.Flash.get(@flash, :info)}
           class="p-4 mb-4 rounded bg-green-100 text-green-700">
        {info}
      </div>

      <%# Product grid %>
      <div :if={@products == []} class="text-gray-500 text-center py-12">
        No products found.
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div :for={product <- @products}
             class={[
               "p-4 rounded-lg border",
               product.featured && "border-amber-400 bg-amber-50",
               !product.featured && "border-gray-200"
             ]}>
          <h2 class="font-semibold">{product.name}</h2>
          <p class="text-gray-500">${product.price}</p>

          <span :if={product.featured}
                class="text-xs px-2 py-1 rounded bg-amber-100 text-amber-700">
            Featured
          </span>

          <div class="mt-4 flex gap-2">
            <.link navigate={~p"/products/\#{product}"}
                   class="text-blue-600 hover:underline">
              View
            </.link>
            <.link navigate={~p"/products/\#{product}/edit"}
                   class="text-gray-500 hover:underline">
              Edit
            </.link>
          </div>
        </div>
      </div>

      <%# Pagination %>
      <nav :if={@total_pages > 1} class="flex gap-2 mt-8 justify-center">
        <.link :for={page <- 1..@total_pages}
               navigate={~p"/products?\#{%{page: page}}"}
               class={[
                 "px-3 py-1 rounded",
                 page == @current_page && "bg-blue-600 text-white",
                 page != @current_page && "bg-gray-100 hover:bg-gray-200"
               ]}>
          {page}
        </.link>
      </nav>
    </div>\
    """
    |> String.trim()
  end
end
