defmodule ElixirKatasWeb.Kata40UploadsLive do
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
    
      <div class="p-6 max-w-lg mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Drag and drop image files (jpg, png) below.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <form phx-submit="save" phx-target={@myself} phx-change="validate" phx-target={@myself}>
          
            <!-- Drop Target -->
            <div 
              class="border-2 border-dashed border-gray-300 rounded-lg p-12 text-center hover:bg-gray-50 transition-colors"
              phx-drop-target={@uploads.avatar.ref}
            >
              <div class="space-y-1 text-center">
                <svg class="mx-auto h-12 w-12 text-gray-400" stroke="currentColor" fill="none" viewBox="0 0 48 48" aria-hidden="true">
                  <path d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                </svg>
                <div class="flex text-sm text-gray-600 justify-center">
                  <label for={@uploads.avatar.ref} class="relative cursor-pointer bg-white rounded-md font-medium text-indigo-600 hover:text-indigo-500 focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-indigo-500">
                    <span>Upload a file</span>
                    <.live_file_input upload={@uploads.avatar} class="sr-only" />
                  </label>
                  <p class="pl-1">or drag and drop</p>
                </div>
                <p class="text-xs text-gray-500">
                  PNG, JPG up to 10MB
                </p>
              </div>
            </div>

            <!-- Previews -->
            <div class="mt-4 grid grid-cols-2 gap-4">
              <%= for entry <- @uploads.avatar.entries do %>
                <div class="relative">
                  <div class="group block w-full aspect-w-10 aspect-h-7 rounded-lg bg-gray-100 overflow-hidden">
                    <.live_img_preview entry={entry} class="object-cover" />
                  </div>
                  
                  <!-- Progress Bar -->
                  <div class="w-full bg-gray-200 rounded-full h-1.5 mt-2">
                    <div class="bg-indigo-600 h-1.5 rounded-full transition-all duration-300" style={"width: #{entry.progress}%"}></div>
                  </div>

                  <!-- Errors -->
                  <%= for err <- upload_errors(@uploads.avatar, entry) do %>
                    <p class="text-xs text-red-600 mt-1"><%= error_to_string(err) %></p>
                  <% end %>
                  
                   <button type="button" phx-click="cancel-upload" phx-target={@myself} phx-value-ref={entry.ref} class="absolute top-0 right-0 bg-red-500 text-white rounded-full p-1 m-1 opacity-75 hover:opacity-100">
                    <span class="sr-only">Remove</span>
                    <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
              <% end %>
            </div>

            <div class="mt-6">
              <button
                type="submit"
                class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                Save
              </button>
            </div>
            
          </form>
        </div>
        
        <!-- Result List -->
        <%= if @uploaded_files != [] do %>
           <div class="mt-6 bg-green-50 rounded-lg p-4 border border-green-200">
             <h3 class="text-sm font-bold text-green-800 mb-2">Successfully Uploaded:</h3>
             <ul class="list-disc list-inside text-sm text-green-700">
               <%= for file <- @uploaded_files do %>
                 <li><%= file %></li>
               <% end %>
             </ul>
           </div>
        <% end %>

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
    # Consume entries - in a real app we would write to disk or S3
    # Here we just collect their client-side names to prove it worked
    
    uploaded_files =
      consume_uploaded_entries(socket, :avatar, fn _meta, entry ->
        # meta is %{path: "/tmp/..."}, entry is the UploadEntry struct
        # client_name is in the entry struct
        {:ok, entry.client_name}
      end)

    {:noreply, 
     socket
     |> update(:uploaded_files, &(&1 ++ uploaded_files))
     |> put_flash(:info, "Files uploaded successfully!")}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
  
  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
