defmodule ElixirKatasWeb.KataComponents do
  use ElixirKatasWeb, :html

  attr :active_tab, :string, required: true
  attr :title, :string, required: true
  attr :source_code, :string, required: true
  attr :notes_content, :string, required: true
  slot :inner_block, required: true
  
  attr :read_only, :boolean, default: false
  attr :is_user_author, :boolean, default: false
  attr :compile_error, :string, default: nil
  attr :compiling, :boolean, default: false
  attr :saved_at, :integer, default: nil
  
  attr :mode, :string, default: "full"
  
  def kata_viewer(assigns) do
    ~H"""
    <div class="flex flex-col h-full">
      <div class="flex items-center justify-between border-b border-zinc-200 dark:border-zinc-700 px-4 py-2">
        <div class="flex items-center gap-4">
          <h2 class="text-xl font-bold">{@title}</h2>
          <%= if @mode != "notes_only" do %>
            <%= if @compiling do %>
               <div class="flex items-center gap-2">
                  <span class="loading loading-spinner loading-xs text-primary"></span>
                  <span class="text-xs text-zinc-500">Compiling...</span>
               </div>
            <% else %>
               <%= if @saved_at && !@compile_error do %>
                  <span class="text-xs text-green-600 font-medium animate-out fade-out duration-1000 delay-[2000ms]">
                    ✓ Saved!
                  </span>
               <% end %>
            <% end %>
            <%= if @read_only == false and @active_tab == "source" and @is_user_author do %>
               <button phx-click="revert" data-confirm="Are you sure? This will discard your changes and restore the original code." class="btn btn-xs btn-outline btn-error">
                 Revert to Original
               </button>
            <% end %>
          <% end %>
        </div>
        
        <div class="flex gap-2 items-center">
          <.tab_button active={@active_tab == "notes"} phx-click="set_tab" phx-value-tab="notes">
            Description
          </.tab_button>
          <%= if @mode != "notes_only" do %>
            <.tab_button active={@active_tab == "interactive"} phx-click="set_tab" phx-value-tab="interactive">
              Interactive
            </.tab_button>
            <.tab_button active={@active_tab == "source"} phx-click="set_tab" phx-value-tab="source">
              Source Code
            </.tab_button>
          <% end %>
          
          <%= if @read_only and @mode != "notes_only" do %>
             <span class="ml-2 px-2 py-1 text-xs font-semibold bg-gray-200 text-gray-700 rounded-full dark:bg-gray-700 dark:text-gray-300">
               Read Only
             </span>
          <% end %>
        </div>

      </div>

      <div class="flex-1 overflow-auto p-4">
        <%= case @active_tab do %>
          <% "interactive" -> %>
            {render_slot(@inner_block)}
          
          <% "source" -> %>
            <div class="mockup-code w-full p-0 overflow-hidden relative">
              <div 
                id={"editor-#{@title |> slugify()}"}
                phx-hook="CodeEditor" 
                data-content={@source_code}
                data-read-only={"#{@read_only}"}
                phx-update="ignore"
                class="w-full text-sm"
              ></div>
              <%= if @compile_error do %>
                 <div class="absolute bottom-0 left-0 right-0 p-4 bg-red-900/90 text-red-100 text-xs font-mono z-50 animate-in fade-in slide-in-from-bottom-2 duration-300 pointer-events-none">
                    <div class="flex items-start gap-2">
                       <span class="font-bold flex-shrink-0">ERROR:</span>
                       <span class="whitespace-pre-wrap">{@compile_error}</span>
                    </div>
                 </div>
               <% end %>
            </div>

          <% "notes" -> %>
            <div class="prose dark:prose-invert max-w-none">
              {raw Earmark.as_html!(@notes_content)}
            </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr :active, :boolean, default: false
  attr :rest, :global
  slot :inner_block

  def tab_button(assigns) do
    ~H"""
    <button
      class={[
        "px-4 py-2 rounded-lg text-sm font-medium transition-colors",
        if(@active, do: "bg-primary text-white", else: "hover:bg-zinc-100 dark:hover:bg-zinc-800")
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :path, :string, required: true
  attr :tags, :list, default: []
  attr :tag_color_fn, :any, default: &ElixirKatasWeb.LiveviewKataData.tag_color/1
  attr :disabled, :boolean, default: false

  def kata_card(assigns) do
    ~H"""
    <div class={["card bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 p-6 rounded-lg relative",
      if(@disabled, do: "opacity-50 cursor-not-allowed", else: "shadow-md hover:shadow-lg transition-shadow group")]}>
      <%= unless @disabled do %>
        <.link navigate={@path} class="absolute inset-0 z-0"><span class="sr-only">{@title}</span></.link>
      <% end %>
      <div class="relative z-10 pointer-events-none">
        <div class="flex items-center mb-4">
          <span class={["w-3 h-3 rounded-full mr-3", if(@disabled, do: "bg-gray-400", else: "bg-indigo-600")]}></span>
          <h2 class={["text-xl font-semibold", if(@disabled, do: "text-gray-400 dark:text-gray-500", else: "group-hover:text-primary transition-colors")]}>{@title}</h2>
          <%= if @disabled do %>
            <span class="ml-2 px-2 py-0.5 text-xs font-medium rounded-full bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400">Coming soon</span>
          <% end %>
        </div>
        <p class="text-gray-600 dark:text-gray-400">
          {@description}
        </p>
        <%= if @tags != [] do %>
          <div class="mt-3 flex flex-wrap gap-1 pointer-events-auto">
            <%= for tag <- @tags do %>
              <button
                phx-click="toggle_tag"
                phx-value-tag={tag}
                class={["inline-block px-2 py-0.5 text-xs font-medium rounded-full cursor-pointer hover:ring-2 hover:ring-offset-1 hover:ring-current transition-all", @tag_color_fn.(tag)]}
              >
                {tag}
              </button>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
  defp slugify(str) do
    str
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
  end
end
