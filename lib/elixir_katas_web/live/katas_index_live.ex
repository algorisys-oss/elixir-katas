defmodule ElixirKatasWeb.KatasIndexLive do
  use ElixirKatasWeb, :live_view
  import ElixirKatasWeb.KataComponents

  alias ElixirKatasWeb.LiveviewKataData

  def mount(_params, _session, socket) do
    sections = LiveviewKataData.sections()

    {:ok,
     assign(socket,
       sections: sections,
       filtered_sections: sections,
       search: "",
       active_tags: MapSet.new(),
       all_tags: LiveviewKataData.all_tags()
     )}
  end

  def handle_event("search", %{"search" => search}, socket) do
    {:noreply, socket |> assign(:search, search) |> filter_katas()}
  end

  def handle_event("toggle_tag", %{"tag" => tag}, socket) do
    active_tags = socket.assigns.active_tags

    active_tags =
      if MapSet.member?(active_tags, tag) do
        MapSet.delete(active_tags, tag)
      else
        MapSet.put(active_tags, tag)
      end

    {:noreply, socket |> assign(:active_tags, active_tags) |> filter_katas()}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:search, "")
     |> assign(:active_tags, MapSet.new())
     |> assign(:filtered_sections, socket.assigns.sections)}
  end

  defp filter_katas(socket) do
    search = String.downcase(socket.assigns.search)
    active_tags = socket.assigns.active_tags

    filtered =
      socket.assigns.sections
      |> Enum.map(fn section ->
        filtered_katas =
          Enum.filter(section.katas, fn kata ->
            matches_search =
              search == "" or
                String.contains?(String.downcase(kata.label), search) or
                String.contains?(String.downcase(kata.description), search)

            matches_tags =
              MapSet.size(active_tags) == 0 or
                Enum.any?(kata.tags, &MapSet.member?(active_tags, &1))

            matches_search and matches_tags
          end)

        %{section | katas: filtered_katas}
      end)
      |> Enum.reject(fn section -> section.katas == [] end)

    assign(socket, :filtered_sections, filtered)
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto py-8">
      <h1 class="text-3xl font-bold mb-4 text-gray-900 dark:text-white">
        Phoenix LiveView Katas
      </h1>
      <p class="text-lg text-gray-600 dark:text-gray-300 mb-6">
        Select a kata from the sidebar or the list below to begin your journey.
      </p>

      <div class="mb-6 space-y-4">
        <form phx-change="search" class="relative">
          <input
            type="text"
            name="search"
            value={@search}
            placeholder="Search katas..."
            phx-debounce="200"
            class="w-full px-4 py-2 pl-10 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
          />
          <svg class="absolute left-3 top-2.5 w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </form>

        <div class="flex flex-wrap gap-2">
          <%= for tag <- @all_tags do %>
            <button
              phx-click="toggle_tag"
              phx-value-tag={tag}
              class={[
                "px-3 py-1 text-sm font-medium rounded-full border transition-colors cursor-pointer",
                if(MapSet.member?(@active_tags, tag),
                  do: "border-indigo-500 bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-200 dark:border-indigo-400",
                  else: "border-gray-300 dark:border-gray-600 text-gray-600 dark:text-gray-400 hover:border-gray-400 dark:hover:border-gray-500"
                )
              ]}
            >
              {tag}
            </button>
          <% end %>
          <%= if @search != "" or MapSet.size(@active_tags) > 0 do %>
            <button
              phx-click="clear_filters"
              class="px-3 py-1 text-sm font-medium rounded-full border border-red-300 text-red-600 dark:text-red-400 dark:border-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors cursor-pointer"
            >
              Clear filters
            </button>
          <% end %>
        </div>
      </div>

      <%= if @filtered_sections == [] do %>
        <div class="text-center py-12">
          <p class="text-gray-500 dark:text-gray-400 text-lg">No katas match your search.</p>
          <button phx-click="clear_filters" class="mt-4 text-indigo-600 dark:text-indigo-400 hover:underline cursor-pointer">
            Clear filters
          </button>
        </div>
      <% end %>

      <%= for section <- @filtered_sections do %>
        <div class="mb-8">
          <h2 class="text-xl font-bold text-gray-800 dark:text-gray-200 mb-4 border-b border-gray-200 dark:border-gray-700 pb-2">
            {section.title}
          </h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <%= for kata <- section.katas do %>
              <.kata_card
                title={kata.label}
                description={kata.description}
                path={"/liveview-katas/#{kata.slug}"}
                tags={kata.tags}
              />
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
