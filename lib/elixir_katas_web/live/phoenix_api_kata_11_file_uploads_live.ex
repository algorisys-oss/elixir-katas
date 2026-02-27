defmodule ElixirKatasWeb.PhoenixApiKata11FileUploadsLive do
  use ElixirKatasWeb, :live_component

  @sample_files [
    %{
      name: "profile.jpg",
      type: "image/jpeg",
      size: 245_760,
      icon: "photo",
      category: "image"
    },
    %{
      name: "report.csv",
      type: "text/csv",
      size: 12_288,
      icon: "table-cells",
      category: "csv"
    },
    %{
      name: "manual.pdf",
      type: "application/pdf",
      size: 1_048_576,
      icon: "document-text",
      category: "pdf"
    },
    %{
      name: "huge_video.mp4",
      type: "video/mp4",
      size: 52_428_800,
      icon: "film",
      category: "video"
    }
  ]

  @validations [
    %{name: "Max file size (5 MB)", check: :size, limit: 5_242_880},
    %{name: "Allowed types (image, csv, pdf)", check: :type, allowed: ["image/jpeg", "image/png", "text/csv", "application/pdf"]}
  ]

  def phoenix_source do
    """
    # File Uploads in Phoenix APIs
    #
    # Phoenix uses Plug.Upload to handle multipart form data.
    # The file is uploaded to a temp directory and a %Plug.Upload{}
    # struct is passed to your controller.

    # Router
    scope "/api", MyAppWeb.Api do
      pipe_through [:api, :api_auth]

      post "/documents/upload", DocumentController, :upload
      post "/users/:id/avatar", UserController, :upload_avatar
    end

    # Controller — handling a file upload
    defmodule MyAppWeb.Api.DocumentController do
      use MyAppWeb, :controller

      # The uploaded file arrives as a %Plug.Upload{} struct
      # in the params map under the field name used in the form.
      #
      # %Plug.Upload{
      #   filename: "report.csv",
      #   content_type: "text/csv",
      #   path: "/tmp/plug-1234/multipart-56789"
      # }

      @max_size 5 * 1024 * 1024  # 5 MB
      @allowed_types ~w(image/jpeg image/png text/csv application/pdf)

      def upload(conn, %{"file" => %Plug.Upload{} = upload}) do
        with :ok <- validate_size(upload),
             :ok <- validate_type(upload),
             {:ok, stored_path} <- store_file(upload) do
          conn
          |> put_status(:created)
          |> json(%{
            data: %{
              filename: upload.filename,
              content_type: upload.content_type,
              size: File.stat!(upload.path).size,
              url: "/uploads/" <> Path.basename(stored_path)
            }
          })
        end
      end

      # Missing file parameter
      def upload(conn, _params) do
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: %{file: ["is required"]}})
      end

      defp validate_size(%Plug.Upload{path: path}) do
        case File.stat(path) do
          {:ok, %{size: size}} when size <= @max_size -> :ok
          {:ok, %{size: size}} -> {:error, :file_too_large}
          _ -> {:error, :file_not_found}
        end
      end

      defp validate_type(%Plug.Upload{content_type: type}) do
        if type in @allowed_types, do: :ok, else: {:error, :invalid_type}
      end

      defp store_file(%Plug.Upload{path: temp_path, filename: name}) do
        dest = Path.join(["priv/static/uploads", name])
        File.mkdir_p!(Path.dirname(dest))

        case File.cp(temp_path, dest) do
          :ok -> {:ok, dest}
          error -> error
        end
      end
    end

    # FallbackController handles upload errors
    defmodule MyAppWeb.FallbackController do
      def call(conn, {:error, :file_too_large}) do
        conn
        |> put_status(:request_entity_too_large)
        |> json(%{errors: %{file: ["exceeds maximum size of 5 MB"]}})
      end

      def call(conn, {:error, :invalid_type}) do
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: %{file: ["type not allowed"]}})
      end
    end

    # Sending a multipart upload with curl:
    #
    # curl -X POST http://localhost:4000/api/documents/upload \\
    #   -H "Authorization: Bearer <token>" \\
    #   -F "file=@./report.csv"
    """
    |> String.trim()
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(id: assigns.id)
     |> assign(sample_files: @sample_files)
     |> assign(validations: @validations)
     |> assign(selected_file: nil)
     |> assign(validation_results: [])
     |> assign(validation_step: 0)
     |> assign(upload_complete: false)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">File Uploads</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Pick a sample file to see how Phoenix handles multipart uploads. Watch the request
        build up and see which validations pass or fail.
      </p>

      <!-- Step 1: Pick a File -->
      <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">1. Pick a File to Upload</h3>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
          <%= for file <- @sample_files do %>
            <button
              phx-click="select_file"
              phx-value-name={file.name}
              phx-target={@myself}
              class={["p-4 rounded-lg border-2 text-left transition-all cursor-pointer",
                if(@selected_file && @selected_file.name == file.name,
                  do: "border-rose-500 bg-rose-50 dark:bg-rose-900/20 shadow-md",
                  else: "border-gray-200 dark:border-gray-700 hover:border-rose-300 dark:hover:border-rose-700 bg-white dark:bg-gray-800")
              ]}
            >
              <div class="flex items-center gap-3 mb-2">
                <div class="w-10 h-10 rounded-lg bg-rose-100 dark:bg-rose-900/30 flex items-center justify-center">
                  <span class="text-rose-600 dark:text-rose-400 text-lg font-bold">
                    <%= icon_for(file.category) %>
                  </span>
                </div>
                <div class="min-w-0 flex-1">
                  <div class="font-semibold text-gray-900 dark:text-white text-sm truncate">{file.name}</div>
                  <div class="text-xs text-gray-500 dark:text-gray-400">{format_size(file.size)}</div>
                </div>
              </div>
              <div class="text-xs text-gray-400 font-mono">{file.type}</div>
            </button>
          <% end %>
        </div>
      </div>

      <!-- Multipart Request Preview -->
      <%= if @selected_file do %>
        <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">2. Multipart Request</h3>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm overflow-x-auto">
            <div class="text-blue-400">POST /api/documents/upload HTTP/1.1</div>
            <div class="text-gray-400">Authorization: Bearer eyJhbG...kpXVCJ9</div>
            <div class="text-yellow-400">Content-Type: multipart/form-data; boundary=----FormBoundary</div>
            <div class="text-gray-500 mt-2">------FormBoundary</div>
            <div class="text-emerald-400">{"Content-Disposition: form-data; name=\"file\"; filename=\"#{@selected_file.name}\""}</div>
            <div class="text-emerald-400">Content-Type: {@selected_file.type}</div>
            <div class="text-gray-500 mt-1">{"<#{format_size(@selected_file.size)} of binary data>"}</div>
            <div class="text-gray-500">------FormBoundary--</div>
          </div>
        </div>

        <!-- Plug.Upload Struct -->
        <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">3. Plug.Upload Struct (in Controller Params)</h3>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm">
            <div class="text-gray-400">{"# conn.params[\"file\"] contains:"}</div>
            <pre class="text-purple-400 whitespace-pre"><%= plug_upload_display(@selected_file) %></pre>
          </div>
          <div class="mt-3 grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div class="p-3 rounded-lg bg-gray-50 dark:bg-gray-700/50">
              <div class="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase mb-1">filename</div>
              <div class="text-sm font-mono text-gray-900 dark:text-white">{@selected_file.name}</div>
              <div class="text-xs text-gray-500 mt-1">Original name from the client</div>
            </div>
            <div class="p-3 rounded-lg bg-gray-50 dark:bg-gray-700/50">
              <div class="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase mb-1">content_type</div>
              <div class="text-sm font-mono text-gray-900 dark:text-white">{@selected_file.type}</div>
              <div class="text-xs text-gray-500 mt-1">MIME type from the client</div>
            </div>
            <div class="p-3 rounded-lg bg-gray-50 dark:bg-gray-700/50">
              <div class="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase mb-1">path</div>
              <div class="text-sm font-mono text-gray-900 dark:text-white truncate">/tmp/plug-1234/...</div>
              <div class="text-xs text-gray-500 mt-1">Temp file on disk (auto-cleaned)</div>
            </div>
          </div>
        </div>

        <!-- Validation Flow -->
        <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">4. Validation Flow</h3>
            <div class="flex gap-2">
              <button
                phx-click="reset_validation"
                phx-target={@myself}
                class="px-3 py-1.5 text-sm bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors cursor-pointer"
              >
                Reset
              </button>
              <button
                phx-click="next_validation"
                phx-target={@myself}
                disabled={@validation_step > length(@validation_results)}
                class={["px-4 py-1.5 text-sm rounded-lg font-medium transition-colors cursor-pointer",
                  if(@validation_step > length(@validation_results),
                    do: "bg-gray-300 dark:bg-gray-700 text-gray-500 cursor-not-allowed",
                    else: "bg-rose-600 hover:bg-rose-700 text-white")
                ]}
              >
                <%= if @validation_step == 0, do: "Run Validations", else: "Next Check" %>
              </button>
            </div>
          </div>

          <div class="space-y-3">
            <%= for {result, i} <- Enum.with_index(@validation_results) do %>
              <div class={["flex items-start gap-4 p-4 rounded-lg transition-all duration-300",
                cond do
                  i < @validation_step -> "bg-gray-50 dark:bg-gray-800 opacity-100"
                  i == @validation_step -> "bg-rose-50 dark:bg-rose-900/20 border-2 border-rose-300 dark:border-rose-700 shadow-md"
                  true -> "bg-gray-50 dark:bg-gray-800 opacity-30"
                end
              ]}>
                <div class={["flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm",
                  cond do
                    i < @validation_step && result.passed -> "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400"
                    i < @validation_step && !result.passed -> "bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400"
                    true -> "bg-rose-100 dark:bg-rose-900/30 text-rose-600 dark:text-rose-400"
                  end
                ]}>
                  <%= if i < @validation_step do %>
                    <%= if result.passed do %>
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                    <% else %>
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    <% end %>
                  <% else %>
                    {i + 1}
                  <% end %>
                </div>

                <div class="flex-1 min-w-0">
                  <div class="font-semibold text-gray-900 dark:text-white text-sm">{result.name}</div>
                  <div class="font-mono text-sm text-gray-700 dark:text-gray-300 mt-0.5">{result.code}</div>
                  <%= if i < @validation_step do %>
                    <div class={["text-sm mt-1", if(result.passed, do: "text-emerald-600 dark:text-emerald-400", else: "text-red-600 dark:text-red-400")]}>
                      {result.detail}
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>

          <!-- Final Result -->
          <%= if @upload_complete do %>
            <% all_passed = Enum.all?(@validation_results, & &1.passed) %>
            <div class={["mt-4 p-4 rounded-lg border-2",
              if(all_passed,
                do: "bg-emerald-50 dark:bg-emerald-900/20 border-emerald-300 dark:border-emerald-700",
                else: "bg-red-50 dark:bg-red-900/20 border-red-300 dark:border-red-700")
            ]}>
              <div class="flex items-center gap-2 mb-2">
                <%= if all_passed do %>
                  <svg class="w-6 h-6 text-emerald-600 dark:text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                  </svg>
                  <span class="font-bold text-emerald-800 dark:text-emerald-300">201 Created &mdash; File uploaded successfully</span>
                <% else %>
                  <svg class="w-6 h-6 text-red-600 dark:text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
                  </svg>
                  <span class="font-bold text-red-800 dark:text-red-300">
                    <% error = Enum.find(@validation_results, &(!&1.passed)) %>
                    {error.status_code} &mdash; {error.error_message}
                  </span>
                <% end %>
              </div>
              <div class="bg-gray-900 rounded-lg p-3 font-mono text-sm">
                <%= if all_passed do %>
                  <pre class="text-emerald-400 whitespace-pre-wrap">{"HTTP/1.1 201 Created\nContent-Type: application/json\n\n{\n  \"data\": {\n    \"filename\": \"#{@selected_file.name}\",\n    \"content_type\": \"#{@selected_file.type}\",\n    \"size\": #{@selected_file.size},\n    \"url\": \"/uploads/#{@selected_file.name}\"\n  }\n}"}</pre>
                <% else %>
                  <% error = Enum.find(@validation_results, &(!&1.passed)) %>
                  <pre class="text-red-400 whitespace-pre-wrap">{error.response_body}</pre>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>

      <!-- curl Example -->
      <div class="p-4 rounded-lg bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">Sending uploads with curl</h4>
        <div class="bg-gray-900 rounded-lg p-3 font-mono text-sm text-gray-300">
          <pre class="whitespace-pre-wrap">{"curl -X POST http://localhost:4000/api/documents/upload \\\n  -H \"Authorization: Bearer <token>\" \\\n  -F \"file=@./report.csv\""}</pre>
        </div>
      </div>

      <!-- Key Insight -->
      <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
        <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-1">Plug.Upload Lifecycle</h4>
        <p class="text-sm text-rose-700 dark:text-rose-400">
          When Phoenix receives a multipart request, Plug writes the file to a <strong>temporary directory</strong>.
          The temp file is <strong>automatically deleted</strong> when the request finishes. You must copy/move
          the file to permanent storage (local disk, S3, etc.) during the request. The <code>path</code> field
          points to the temp file &mdash; never store this path as a reference.
        </p>
      </div>
    </div>
    """
  end

  defp plug_upload_display(file) do
    "%Plug.Upload{\n  filename: \"#{file.name}\",\n  content_type: \"#{file.type}\",\n  path: \"/tmp/plug-1234/multipart-56789\"\n}"
  end

  defp icon_for("image"), do: "IMG"
  defp icon_for("csv"), do: "CSV"
  defp icon_for("pdf"), do: "PDF"
  defp icon_for("video"), do: "VID"
  defp icon_for(_), do: "FILE"

  defp format_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_size(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1024, 1)} KB"
  defp format_size(bytes), do: "#{Float.round(bytes / 1_048_576, 1)} MB"

  defp run_validations(file) do
    size_passed = file.size <= 5_242_880
    type_passed = file.type in ["image/jpeg", "image/png", "text/csv", "application/pdf"]

    [
      %{
        name: "File size check",
        code: "validate_size(upload)  # max 5 MB",
        passed: size_passed,
        detail:
          if(size_passed,
            do: "#{format_size(file.size)} <= 5 MB -- PASS",
            else: "#{format_size(file.size)} > 5 MB -- FAIL"
          ),
        status_code: "413 Request Entity Too Large",
        error_message: "File exceeds maximum size of 5 MB",
        response_body: "HTTP/1.1 413 Request Entity Too Large\nContent-Type: application/json\n\n{\n  \"errors\": {\n    \"file\": [\"exceeds maximum size of 5 MB\"]\n  }\n}"
      },
      %{
        name: "Content type check",
        code: "validate_type(upload)  # image, csv, pdf only",
        passed: type_passed,
        detail:
          if(type_passed,
            do: "\"#{file.type}\" is in allowed types -- PASS",
            else: "\"#{file.type}\" is NOT in allowed types -- FAIL"
          ),
        status_code: "422 Unprocessable Entity",
        error_message: "File type not allowed",
        response_body: "HTTP/1.1 422 Unprocessable Entity\nContent-Type: application/json\n\n{\n  \"errors\": {\n    \"file\": [\"type not allowed: #{file.type}\"]\n  }\n}"
      }
    ]
  end

  def handle_event("select_file", %{"name" => name}, socket) do
    file = Enum.find(@sample_files, &(&1.name == name))
    results = run_validations(file)
    {:noreply, assign(socket, selected_file: file, validation_results: results, validation_step: 0, upload_complete: false)}
  end

  def handle_event("next_validation", _params, socket) do
    max = length(socket.assigns.validation_results)
    new_step = min(socket.assigns.validation_step + 1, max + 1)

    # Check if a previous step already failed
    already_failed =
      socket.assigns.validation_results
      |> Enum.take(socket.assigns.validation_step)
      |> Enum.any?(&(!&1.passed))

    upload_complete = new_step > max or already_failed

    {:noreply, assign(socket, validation_step: new_step, upload_complete: upload_complete)}
  end

  def handle_event("reset_validation", _params, socket) do
    {:noreply, assign(socket, validation_step: 0, upload_complete: false)}
  end
end
