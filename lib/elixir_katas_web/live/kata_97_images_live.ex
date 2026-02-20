defmodule ElixirKatasWeb.Kata97ImageProcessingLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:original_path, nil)
      |> assign(:processed_path, nil)
      |> allow_upload(:image, accept: ~w(.jpg .jpeg .png), max_entries: 1)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Upload and process images using Mogrify (ImageMagick wrapper)
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <h3 class="text-lg font-medium mb-4">Resize & Grayscale</h3>
          
          <form phx-submit="save" phx-target={@myself} phx-change="validate" phx-target={@myself}>
            <div class="mb-4" phx-drop-target={@uploads.image.ref}>
              <div class="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-indigo-500 transition-colors">
                <.live_file_input upload={@uploads.image} class="block w-full text-sm text-gray-500
                  file:mr-4 file:py-2 file:px-4
                  file:rounded-full file:border-0
                  file:text-sm file:font-semibold
                  file:bg-indigo-50 file:text-indigo-700
                  hover:file:bg-indigo-100" />
                <p class="mt-2 text-xs text-gray-500">Upload an image to process</p>
              </div>
            </div>

            <!-- Previews -->
            <%= for entry <- @uploads.image.entries do %>
              <div class="mb-4">
                <div class="text-sm text-gray-600 mb-1">Preview:</div>
                <.live_img_preview entry={entry} class="h-32 rounded border" />
                <div class="w-full bg-gray-200 rounded-full h-1.5 mt-2">
                   <div class="bg-indigo-600 h-1.5 rounded-full transition-all duration-300" style={"width: #{entry.progress}%"}></div>
                </div>
              </div>
            <% end %>

            <button type="submit" class="px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700 disabled:opacity-50" disabled={@uploads.image.entries == []}>
              Process Image
            </button>
          </form>

          <%= if @processed_path do %>
            <div class="mt-8 pt-6 border-t grid grid-cols-2 gap-6">
              <div>
                <h4 class="text-sm font-medium text-gray-900 mb-2">Original</h4>
                <img src={@original_path} class="w-full rounded border" />
              </div>
              <div>
                <h4 class="text-sm font-medium text-gray-900 mb-2">Processed (Grayscale + Resize)</h4>
                <img src={@processed_path} class="w-full rounded border" />
              </div>
            </div>
          <% end %>
        </div>
      </div>
    
    """
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", _params, socket) do
    # Consume, copy to static, then process
    [{original_url, processed_url}] = 
      consume_uploaded_entries(socket, :image, fn %{path: path}, entry ->
        file_name = "#{entry.uuid}-#{entry.client_name}"
        dest_dir = "priv/static/uploads"
        File.mkdir_p!(dest_dir)
        
        original_dest = Path.join(dest_dir, "original-#{file_name}")
        processed_dest = Path.join(dest_dir, "processed-#{file_name}")
        
        File.cp!(path, original_dest)
        File.cp!(path, processed_dest)
        
        # Process using Mogrify
        try do
          import Mogrify
          
          open(processed_dest)
          |> resize("300x300")
          |> custom("colorspace", "gray")
          |> save(in_place: true)

          {:ok, {"/uploads/original-#{file_name}", "/uploads/processed-#{file_name}"}}
        rescue
          e -> 
            IO.warn("Image processing failed: #{inspect(e)}")
            # Fallback if mogrify fails (e.g. tool missing)
            {:ok, {"/uploads/original-#{file_name}", "/uploads/original-#{file_name}"}}
        end
      end)

    {:noreply, 
     socket 
     |> assign(:original_path, original_url)
     |> assign(:processed_path, processed_url)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
