defmodule ElixirKatasWeb.Kata92FileDropzoneLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:uploaded_files, [])
      |> allow_upload(:files, accept: :any, max_entries: 3)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Advanced file dropzone with management
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <h3 class="text-lg font-medium mb-4">File Dropzone</h3>
          
          <form phx-submit="save" phx-target={@myself} phx-change="validate" phx-target={@myself}>
            <!-- Dropzone -->
            <div 
              phx-drop-target={@uploads.files.ref}
              class="border-2 border-dashed border-indigo-200 rounded-xl p-10 text-center hover:bg-indigo-50 hover:border-indigo-400 transition-colors cursor-pointer group"
            >
              <.live_file_input upload={@uploads.files} class="hidden" />
              <.icon name="hero-cloud-arrow-up" class="w-12 h-12 text-indigo-300 group-hover:text-indigo-500 mb-2 transition" />
              <div class="text-lg font-medium text-gray-700">Drop files here</div>
              <div class="text-sm text-gray-500 mt-1">or click to browse</div>
              <%= for err <- upload_errors(@uploads.files) do %>
                <div class="text-red-600 text-sm mt-2"><%= error_to_string(err) %></div>
              <% end %>
            </div>

            <!-- Staged Files List -->
            <%= if @uploads.files.entries != [] do %>
              <div class="mt-6">
                <h4 class="text-sm font-medium text-gray-700 mb-3">Selected Files</h4>
                <div class="space-y-2">
                  <%= for entry <- @uploads.files.entries do %>
                    <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg border">
                      <div class="flex items-center gap-3">
                        <div class="w-8 h-8 rounded bg-indigo-100 text-indigo-600 flex items-center justify-center text-xs font-bold">
                          <%= Path.extname(entry.client_name) %>
                        </div>
                        <div>
                           <div class="text-sm font-medium text-gray-900"><%= entry.client_name %></div>
                           <div class="text-xs text-gray-500"><%= div(entry.client_size, 1024) %> KB – <%= entry.progress %>%</div>
                        </div>
                      </div>
                      <button 
                        type="button" 
                        phx-click="cancel-upload" phx-target={@myself} 
                        phx-value-ref={entry.ref}
                        class="text-gray-400 hover:text-red-500 p-1"
                      >
                       <.icon name="hero-x-mark" class="w-5 h-5" />
                      </button>
                    </div>
                  <% end %>
                </div>
              </div>

              <div class="mt-4 flex justify-end">
                <button type="submit" class="bg-indigo-600 text-white px-4 py-2 rounded shadow-sm hover:bg-indigo-700">
                  Upload <%= length(@uploads.files.entries) %> Files
                </button>
              </div>
            <% end %>
          </form>

          <!-- Uploaded Result (Mock) -->
          <%= if @uploaded_files != [] do %>
            <div class="mt-8 pt-6 border-t">
              <h4 class="text-sm font-medium text-gray-900 mb-3">Recently Uploaded</h4>
               <div class="space-y-2">
                 <%= for file <- @uploaded_files do %>
                   <div class="flex items-center gap-2 text-sm text-green-700">
                     <.icon name="hero-check-circle" class="w-5 h-5" />
                     <span><%= file %></span>
                   </div>
                 <% end %>
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

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :files, ref)}
  end

  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :files, fn %{path: _path}, entry ->
        # Just return the name for display demo
        {:ok, entry.client_name}
      end)

    {:noreply, update(socket, :uploaded_files, &(&1 ++ uploaded_files))}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  defp error_to_string(:too_large), do: "File too large"
  defp error_to_string(:too_many_files), do: "Too many files"
  defp error_to_string(:not_accepted), do: "Unacceptable file type"
end
