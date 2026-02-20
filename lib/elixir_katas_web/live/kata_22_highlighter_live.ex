defmodule ElixirKatasWeb.Kata22HighlighterLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    text = """
    Elixir is a dynamic, functional language for building scalable and maintainable applications.
    Elixir runs on the Erlang VM, known for running low-latency, distributed, and fault-tolerant systems.
    Elixir is successfully used in web development, embedded software, data ingestion, and multimedia processing domains.
    """

    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:text, text)
      |> assign(:search_term, "")

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-lg mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Highlighting search terms within text
        </div>

        <div class="mt-6">
          <div class="mb-4">
            <label class="block text-sm font-medium text-gray-700">Search Term</label>
            <form phx-change="search" phx-target={@myself}>
              <input
                type="text"
                name="value"
                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                placeholder="Type to highlight..."
                value={@search_term}
                autocomplete="off"
              />
            </form>
          </div>

          <div class="p-4 bg-gray-50 border rounded-lg text-gray-800 leading-relaxed whitespace-pre-wrap">
            <%= raw(highlight_text(@text, @search_term)) %>
          </div>
        </div>

         <div class="mt-12 bg-gray-50 p-4 rounded-lg border text-sm text-gray-600">
          <h3 class="font-bold mb-2">How it works:</h3>
          <p>
            We use regex to find matches of the search term and wrap them in a <code>span</code> with a yellow background. <code>Phoenix.HTML.raw/1</code> is used to render the resulting HTML string safely (be careful with user input in real apps!).
          </p>
        </div>
      </div>
    
    """
  end

  def handle_event("search", %{"value" => term}, socket) do
    {:noreply, assign(socket, :search_term, term)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  defp highlight_text(text, ""), do: html_escape(text)
  
  defp highlight_text(text, term) do
    # Escape the text first to prevent XSS from the original text content
    safe_text = Phoenix.HTML.html_escape(text) |> Phoenix.HTML.safe_to_string()
    safe_term = Phoenix.HTML.html_escape(term) |> Phoenix.HTML.safe_to_string()
    
    # We need a way to wrap matches. 
    # Since we already escaped the full text, we can safely inject our span tags 
    # assuming we match the escaped version of the term.
    
    # However, a simpler approach for this kata (and safer for "raw" usage) 
    # is to split by the term and join with the highlighted span.
    # Note: This simple split/join is case-sensitive.
    
    regex = Regex.compile!(Regex.escape(safe_term), "i")
    
    String.replace(safe_text, regex, fn match -> 
      "<span class=\"bg-yellow-200 font-bold px-1 rounded\">#{match}</span>" 
    end)
  end
  
  # Helper to ensure we don't double escape if we call it directly, 
  # but above logic attempts to handle it. 
  # Actually, `raw` expects a string.
end
