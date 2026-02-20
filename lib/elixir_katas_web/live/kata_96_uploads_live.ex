defmodule ElixirKatasWeb.Kata96FileUploadsLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:uploaded_files, [])
      |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png), max_entries: 2)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          File upload with progress tracking and validation
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <h3 class="text-lg font-medium mb-4">Upload Files</h3>
          
          <form phx-submit="save" phx-target={@myself} phx-change="validate" phx-target={@myself}>
            <div class="mb-4" phx-drop-target={@uploads.avatar.ref}>
              <div class="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-indigo-500 transition-colors">
                <.live_file_input upload={@uploads.avatar} class="block w-full text-sm text-gray-500
                  file:mr-4 file:py-2 file:px-4
                  file:rounded-full file:border-0
                  file:text-sm file:font-semibold
                  file:bg-indigo-50 file:text-indigo-700
                  hover:file:bg-indigo-100" />
                <p class="mt-2 text-xs text-gray-500">Drag and drop files here or click to select</p>
                <p class="text-xs text-gray-400 mt-1">Max 2 files, 5MB each (jpg, jpeg, png)</p>
              </div>
            </div>

            <!-- Error Messages -->
            <%= for err <- upload_errors(@uploads.avatar) do %>
              <div class="mb-4 p-3 bg-red-50 text-red-700 text-sm rounded border border-red-200 flex items-center gap-2">
                <.icon name="hero-exclamation-circle" class="w-4 h-4" />
                <%= error_to_string(err) %>
              </div>
            <% end %>

            <!-- Selected Files Preview -->
            <div class="space-y-3 mb-6">
              <%= for entry <- @uploads.avatar.entries do %>
                <div class="flex items-center p-3 bg-gray-50 rounded border">
                  <div class="flex-1 min-w-0 mr-4">
                    <div class="flex justify-between mb-1">
                      <span class="text-sm font-medium text-gray-900 truncate"><%= entry.client_name %></span>
                      <span class="text-xs text-gray-500"><%= entry.progress %>%</span>
                    </div>
                    <div class="w-full bg-gray-200 rounded-full h-1.5">
                      <div class="bg-indigo-600 h-1.5 rounded-full transition-all duration-300" style={"width: #{entry.progress}%"}></div>
                    </div>
                  </div>
                  <button type="button" phx-click="cancel-upload" phx-target={@myself} phx-value-ref={entry.ref} class="text-gray-400 hover:text-red-500">
                    <.icon name="hero-x-mark" class="w-5 h-5" />
                  </button>
                  
                  <%= for err <- upload_errors(@uploads.avatar, entry) do %>
                    <p class="text-xs text-red-600 mt-1 pl-2 border-l-2 border-red-300"><%= error_to_string(err) %></p>
                  <% end %>
                </div>
              <% end %>
            </div>

            <button type="submit" class="px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed" disabled={@uploads.avatar.entries == []}>
              Upload Files
            </button>
          </form>

          <!-- Uploaded Files List -->
          <div class="mt-8 pt-6 border-t">
            <h4 class="text-sm font-medium text-gray-900 mb-4">Uploaded Files</h4>
            <%= if @uploaded_files == [] do %>
              <p class="text-sm text-gray-500 italic">No files uploaded yet.</p>
            <% else %>
              <div class="grid grid-cols-2 gap-4">
                <%= for file_url <- @uploaded_files do %>
                  <div class="relative group aspect-square bg-gray-100 rounded-lg overflow-hidden border">
                    <img src={file_url} class="w-full h-full object-cover" />
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  def handle_event("save", _params, socket) do
    # In a real app, you would consume the uploads here.
    # For this demo, we'll simulate "persisting" them by generating
    # a temporary URL (or just using the preview URL if we were doing that).
    # Since we can't easily serve temp files without a full upload provider setup 
    # and static serving configuration, we will consume them to a path but
    # for the UI we might just show a placeholder or the same preview if possible.
    
    # Let's consume to get the path, but for the demo "uploaded list", we will
    # just reuse the client-side preview URL principle or a placeholder
    # because serving the file back requires a static path route.
    
    uploaded_files =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, _entry ->
        dest = Path.join("priv/static/uploads", Path.basename(path))
        # Ensure directory exists
        File.mkdir_p!("priv/static/uploads")
        File.cp!(path, dest)
        
        # Return the public path
        {:ok, "/uploads/#{Path.basename(dest)}"}
      end)

    {:noreply, update(socket, :uploaded_files, &(&1 ++ uploaded_files))}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  defp error_to_string(:too_large), do: "File is too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
