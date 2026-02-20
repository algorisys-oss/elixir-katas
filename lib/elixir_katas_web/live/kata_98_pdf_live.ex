defmodule ElixirKatasWeb.Kata98PDFGenerationLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:form, to_form(%{"title" => "My Document", "body" => "## Section 1\nContent goes here..."}))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Generate PDF documents from HTML/Markdown using wkhtmltopdf
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <h3 class="text-lg font-medium mb-4">Create PDF Document</h3>
          
          <form action="/exports/pdf" method="post">
            <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />
            
            
            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700">Document Title</label>
                <input 
                  type="text" 
                  name="title" 
                  value={@form[:title].value} 
                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700">Content (Markdown supported)</label>
                <textarea 
                  name="body" 
                  rows="8" 
                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                ><%= @form[:body].value %></textarea>
              </div>

              <div class="flex justify-end">
                <button 
                  type="submit" 
                  class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  <span class="mr-2">Download PDF</span>
                  <.icon name="hero-document-arrow-down" class="w-4 h-4" />
                </button>
              </div>
            </div>
          </form>
        </div>
      </div>
    
    """
  end

  def handle_event("validate", %{"title" => title, "body" => body}, socket) do
    # Just update the form for UI feedback if we wanted preview
    {:noreply, assign(socket, :form, to_form(%{"title" => title, "body" => body}))}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
