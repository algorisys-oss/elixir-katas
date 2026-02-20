defmodule ElixirKatasWeb.TaskyLive.Index do
  use ElixirKatasWeb, :live_view
  alias ElixirKatas.Tasky
  alias ElixirKatas.Tasky.Todo

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Tasky.subscribe()
    end

    user_id = socket.assigns.current_scope.user.id
    categories = Tasky.list_categories(user_id)

    {:ok, 
     socket
     |> assign(:page_title, "Tasky")
     |> assign(:form, to_form(Tasky.change_todo(%Todo{})))
     |> assign(:show_confirm_modal, false)
     |> assign(:confirm_delete_id, nil)
     |> assign(:confirm_delete_type, nil)
     |> assign(:categories, categories)
     |> assign(:selected_todo, nil)
     |> allow_upload(:attachment, accept: ~w(.jpg .jpeg .png .pdf .txt), max_entries: 1)
     |> stream(:todos, [])}
  end

  def handle_params(params, _url, socket) do
    page = String.to_integer(params["page"] || "1")
    search = params["search"] || ""
    category = params["category"] || ""
    priority = params["priority"] || ""
    due_date_filter = params["due_date_filter"] || ""
    per_page = 5
    
    user_id = socket.assigns.current_scope.user.id
    pagination = Tasky.list_todos(user_id, 
      page: page, 
      per_page: per_page, 
      search: search,
      category: category,
      priority: priority,
      due_date_filter: due_date_filter
    )
    
    {:noreply,
     socket
     |> assign(:page, page)
     |> assign(:per_page, per_page)
     |> assign(:search, search)
     |> assign(:category, category)
     |> assign(:priority, priority)
     |> assign(:due_date_filter, due_date_filter)
     |> assign(:total_pages, pagination.total_pages)
     |> stream(:todos, pagination.entries, reset: true)}
  end

  def handle_event("search", %{"query" => search}, socket) do
    {:noreply, push_patch(socket, to: build_url(socket, %{search: search, page: 1}))}
  end

  def handle_event("filter_category", %{"category" => category}, socket) do
    {:noreply, push_patch(socket, to: build_url(socket, %{category: category, page: 1}))}
  end

  def handle_event("filter_priority", %{"priority" => priority}, socket) do
    {:noreply, push_patch(socket, to: build_url(socket, %{priority: priority, page: 1}))}
  end

  def handle_event("filter_due_date", %{"due_date_filter" => due_date_filter}, socket) do
    {:noreply, push_patch(socket, to: build_url(socket, %{due_date_filter: due_date_filter, page: 1}))}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_patch(socket, to: build_url(socket, %{category: "", priority: "", due_date_filter: "", page: 1}))}
  end

  def handle_event("validate", %{"todo" => todo_params}, socket) do
    form =
      %Todo{}
      |> Tasky.change_todo(todo_params)
      |> to_form(action: :validate)

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"todo" => todo_params}, socket) do
    case Tasky.create_todo(socket.assigns.current_scope.user.id, todo_params) do
      {:ok, _todo} ->
        search = socket.assigns.search
        user_id = socket.assigns.current_scope.user.id
        total_pages = ceil(Tasky.count_todos(user_id, search) / socket.assigns.per_page)
        categories = Tasky.list_categories(user_id)
        
        {:noreply,
         socket
         |> assign(:total_pages, total_pages)
         |> assign(:categories, categories)
         |> assign(:form, to_form(Tasky.change_todo(%Todo{})))}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("toggle_complete", %{"id" => id}, socket) do
    todo = Tasky.get_todo!(id)
    {:ok, updated_todo} = Tasky.update_todo(todo, %{is_complete: !todo.is_complete})
    {:noreply, stream_insert(socket, :todos, updated_todo)}
  end

  def handle_event("toggle_favorite", %{"id" => id}, socket) do
    todo = Tasky.get_todo!(id)
    {:ok, updated_todo} = Tasky.update_todo(todo, %{is_favorite: !todo.is_favorite})
    {:noreply, stream_insert(socket, :todos, updated_todo)}
  end

  def handle_event("confirm_delete", %{"id" => id, "type" => type}, socket) do
    {:noreply,
     socket
     |> assign(:confirm_delete_id, id)
     |> assign(:confirm_delete_type, type)
     |> assign(:show_confirm_modal, true)}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply,
     socket
     |> assign(:confirm_delete_id, nil)
     |> assign(:confirm_delete_type, nil)
     |> assign(:show_confirm_modal, false)}
  end

  def handle_event("delete_todo", %{"id" => id}, socket) do
    todo = Tasky.get_todo!(id)
    {:ok, _} = Tasky.delete_todo(todo)
    
    search = socket.assigns.search
    total_pages = ceil(Tasky.count_todos(socket.assigns.current_scope.user.id, search) / socket.assigns.per_page)
    
    {:noreply,
     socket
     |> assign(:total_pages, total_pages)
     |> assign(:show_confirm_modal, false)
     |> assign(:confirm_delete_type, nil)}
  end

  # Blue Belt Handlers

  def handle_event("open_todo", %{"id" => id}, socket) do
    todo = Tasky.get_todo!(id)
    {:noreply, assign(socket, selected_todo: todo)}
  end

  def handle_event("close_todo", _params, socket) do
    {:noreply, assign(socket, selected_todo: nil)}
  end

  def handle_event("save_subtask", %{"subtask" => subtask_params}, socket) do
    params = Map.put(subtask_params, "todo_id", socket.assigns.selected_todo.id)
    
    case Tasky.create_subtask(params) do
      {:ok, _subtask} ->
        # Refresh the selected todo to show new subtask
        updated_todo = Tasky.get_todo!(socket.assigns.selected_todo.id)
        {:noreply, assign(socket, selected_todo: updated_todo)}
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not create subtask")}
    end
  end

  def handle_event("toggle_subtask", %{"id" => id}, socket) do
    subtask = ElixirKatas.Repo.get!(ElixirKatas.Tasky.Subtask, id)
    {:ok, _} = Tasky.update_subtask(subtask, %{is_complete: !subtask.is_complete})
    
    updated_todo = Tasky.get_todo!(socket.assigns.selected_todo.id)
    {:noreply, assign(socket, selected_todo: updated_todo)}
  end

  def handle_event("delete_subtask", %{"id" => id}, socket) do
    subtask = ElixirKatas.Repo.get!(ElixirKatas.Tasky.Subtask, id)
    {:ok, _} = Tasky.delete_subtask(subtask)

    updated_todo = Tasky.get_todo!(socket.assigns.selected_todo.id)
    {:noreply, assign(socket, selected_todo: updated_todo)}
  end

  def handle_event("save_comment", %{"comment" => comment_params}, socket) do
    params = comment_params
      |> Map.put("todo_id", socket.assigns.selected_todo.id)
      |> Map.put("user_id", socket.assigns.current_scope.user.id)

    case Tasky.create_comment(params) do
      {:ok, _comment} ->
        updated_todo = Tasky.get_todo!(socket.assigns.selected_todo.id)
        {:noreply, assign(socket, selected_todo: updated_todo)}
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not create comment")}
    end
  end

  def handle_event("validate_upload", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save_attachment", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :attachment, fn %{path: path}, entry ->
        dest_dir = Path.join(["priv", "static", "uploads"])
        File.mkdir_p!(dest_dir)
        dest = Path.join(dest_dir, "#{entry.uuid}-#{entry.client_name}")
        File.cp!(path, dest)
        
        # Return the params needed to create the attachment record
        {:ok, %{
          "filename" => entry.client_name,
          "content_type" => entry.client_type,
          "path" => "/uploads/#{entry.uuid}-#{entry.client_name}",
          "size" => entry.client_size,
          "todo_id" => socket.assigns.selected_todo.id
        }}
      end)

    # Create records for uploaded files
    Enum.each(uploaded_files, fn attrs ->
      Tasky.create_attachment(attrs)
    end)

    updated_todo = Tasky.get_todo!(socket.assigns.selected_todo.id)
    {:noreply, assign(socket, selected_todo: updated_todo)}
  end

  def handle_event("delete_attachment", %{"id" => id}, socket) do
    attachment = ElixirKatas.Repo.get!(ElixirKatas.Tasky.Attachment, id)
    
    # Try to delete the file from disk (optional, but good practice)
    file_path = Path.join(["priv", "static", attachment.path])
    File.rm(file_path)

    {:ok, _} = Tasky.delete_attachment(attachment)
    
    updated_todo = Tasky.get_todo!(socket.assigns.selected_todo.id)
    {:noreply, 
     socket 
     |> assign(:selected_todo, updated_todo)
     |> assign(:show_confirm_modal, false)
     |> assign(:confirm_delete_type, nil)}
  end

  def handle_info({:todo_created, todo}, socket) do
    {:noreply, stream_insert(socket, :todos, todo, at: 0)}
  end

  def handle_info({:todo_updated, todo}, socket) do
    {:noreply, stream_insert(socket, :todos, todo)}
  end

  def handle_info({:todo_deleted, todo}, socket) do
    {:noreply, stream_delete(socket, :todos, todo)}
  end

  defp build_url(socket, updates) do
    params = %{
      "page" => to_string(updates[:page] || socket.assigns.page),
      "search" => updates[:search] || socket.assigns.search,
      "category" => updates[:category] || socket.assigns.category,
      "priority" => updates[:priority] || socket.assigns.priority,
      "due_date_filter" => updates[:due_date_filter] || socket.assigns.due_date_filter
    }
    |> Enum.reject(fn {_k, v} -> v == "" end)
    |> Enum.map(fn {k, v} -> "#{k}=#{URI.encode_www_form(v)}" end)
    |> Enum.join("&")

    "/usecases/tasky?" <> params
  end

  defp priority_class("high"), do: "bg-red-100 text-red-800"
  defp priority_class("medium"), do: "bg-yellow-100 text-yellow-800"
  defp priority_class("low"), do: "bg-green-100 text-green-800"
  defp priority_class(_), do: "bg-gray-100 text-gray-800"

  defp due_date_class(due_date) do
    today = Date.utc_today()
    case Date.compare(due_date, today) do
      :lt -> "text-red-600 font-medium"  # Overdue
      :eq -> "text-orange-600 font-medium"  # Due today
      :gt ->
        days_until = Date.diff(due_date, today)
        if days_until <= 7 do
          "text-blue-600"  # Due this week
        else
          "text-gray-600"  # Future
        end
    end
  end

  defp format_due_date(due_date) do
    today = Date.utc_today()
    case Date.compare(due_date, today) do
      :lt ->
        days_ago = Date.diff(today, due_date)
        "Overdue by #{days_ago} #{if days_ago == 1, do: "day", else: "days"}"
      :eq ->
        "Due today"
      :gt ->
        days_until = Date.diff(due_date, today)
        cond do
          days_until == 1 -> "Due tomorrow"
          days_until <= 7 -> "Due in #{days_until} days"
          true -> "Due #{Calendar.strftime(due_date, "%b %d, %Y")}"
        end
    end
  end

  defp humanize_size(size) do
    cond do
      size < 1024 -> "#{size} B"
      size < 1024 * 1024 -> "#{Float.round(size / 1024, 1)} KB"
      true -> "#{Float.round(size / (1024 * 1024), 1)} MB"
    end
  end

  defp is_image?(content_type) do
    String.starts_with?(content_type, "image/")
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div class="sm:mx-auto sm:w-full sm:max-w-md">
        <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
          Tasky
        </h2>
        <p class="mt-2 text-center text-sm text-gray-600">
          Simplify your day
        </p>
      </div>

      <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div class="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
          <div class="mb-6">
             <div class="relative rounded-md shadow-sm">
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <.icon name="hero-magnifying-glass" class="h-5 w-5 text-gray-400" />
                </div>
                <form phx-change="search" phx-submit="search">
                  <input 
                    type="text" 
                    name="query" 
                    value={@search}
                    placeholder="Search tasks..." 
                    class="focus:ring-indigo-500 focus:border-indigo-500 block w-full pl-10 sm:text-sm border-gray-300 rounded-md" 
                  />
                </form>
             </div>
          </div>

          <!-- Filter Controls -->
          <div class="mb-6 space-y-3">
            <div class="flex flex-wrap gap-2">
              <select phx-change="filter_category" name="category" class="text-sm border-gray-300 rounded-md">
                <option value="">All Categories</option>
                <option :for={cat <- @categories} value={cat} selected={@category == cat}>{cat}</option>
              </select>

              <select phx-change="filter_priority" name="priority" class="text-sm border-gray-300 rounded-md">
                <option value="">All Priorities</option>
                <option value="high" selected={@priority == "high"}>High</option>
                <option value="medium" selected={@priority == "medium"}>Medium</option>
                <option value="low" selected={@priority == "low"}>Low</option>
              </select>

              <select phx-change="filter_due_date" name="due_date_filter" class="text-sm border-gray-300 rounded-md">
                <option value="">All Dates</option>
                <option value="overdue" selected={@due_date_filter == "overdue"}>Overdue</option>
                <option value="today" selected={@due_date_filter == "today"}>Due Today</option>
                <option value="week" selected={@due_date_filter == "week"}>This Week</option>
                <option value="no_date" selected={@due_date_filter == "no_date"}>No Date</option>
              </select>

              <%= if @category != "" || @priority != "" || @due_date_filter != "" do %>
                <button phx-click="clear_filters" class="text-sm text-indigo-600 hover:text-indigo-800">
                  Clear Filters
                </button>
              <% end %>
            </div>
          </div>

          <!-- Add Task Form -->
          <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4 mb-8">
            <div>
              <label for="title" class="sr-only">New Task</label>
              <div class="relative rounded-md shadow-sm">
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <.icon name="hero-plus" class="h-5 w-5 text-gray-400" />
                </div>
                <.input field={@form[:title]} type="text" placeholder="Add a new task..." 
                  class="focus:ring-indigo-500 focus:border-indigo-500 block w-full pl-10 sm:text-sm border-gray-300 rounded-md" />
              </div>
            </div>
            
            <div class="grid grid-cols-3 gap-3">
              <div>
                <.input field={@form[:category]} type="text" placeholder="Category" list="categories-list"
                  class="focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />
                <datalist id="categories-list">
                  <option :for={cat <- @categories} value={cat}>{cat}</option>
                </datalist>
              </div>
              
              <div>
                <.input field={@form[:priority]} type="select" options={[{"Low", "low"}, {"Medium", "medium"}, {"High", "high"}]}
                  class="focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />
              </div>
              
              <div>
                <.input field={@form[:due_date]} type="date"
                  class="focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />
              </div>
            </div>
            
            <div>
              <button type="submit" class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                Add Task
              </button>
            </div>
          </.form>

          <!-- Todo List -->
          <ul id="todos" phx-update="stream" class="divide-y divide-gray-200">
            <li :for={{id, todo} <- @streams.todos} id={id} class="py-4 group">
              <div class="flex items-start justify-between">
                <div class="flex items-start flex-1">
                  <button phx-click="toggle_complete" phx-value-id={todo.id} class="focus:outline-none mt-1">
                    <%= if todo.is_complete do %>
                      <.icon name="hero-check-circle-solid" class="h-6 w-6 text-green-500" />
                    <% else %>
                      <.icon name="hero-check-circle" class="h-6 w-6 text-gray-300 group-hover:text-green-500 transition-colors" />
                    <% end %>
                  </button>
                  <div class="ml-3 flex-1">
                    <div class="flex items-center gap-2 flex-wrap">
                      <button phx-click="open_todo" phx-value-id={todo.id} class={"text-sm font-medium hover:underline text-left #{if todo.is_complete, do: "text-gray-400 line-through", else: "text-gray-900"}"}>
                        <%= todo.title %>
                      </button>
                      
                      <!-- Priority Badge -->
                      <%= if todo.priority do %>
                        <span class={"inline-flex items-center px-2 py-0.5 rounded text-xs font-medium #{priority_class(todo.priority)}"}>
                          <%= String.capitalize(todo.priority) %>
                        </span>
                      <% end %>
                      
                      <!-- Category Badge -->
                      <%= if todo.category do %>
                        <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
                          <%= todo.category %>
                        </span>
                      <% end %>
                    </div>
                    
                    <!-- Due Date -->
                    <%= if todo.due_date do %>
                      <div class={"text-xs mt-1 #{due_date_class(todo.due_date)}"}>
                        <.icon name="hero-calendar" class="h-3 w-3 inline" />
                        <%= format_due_date(todo.due_date) %>
                      </div>
                    <% end %>
                  </div>
                </div>
                
                <div class="flex items-center gap-2 ml-2">
                  <button phx-click="toggle_favorite" phx-value-id={todo.id} class="focus:outline-none transition-transform active:scale-95 group/fav">
                     <%= if todo.is_favorite do %>
                       <.icon name="hero-star-solid" class="h-5 w-5 text-yellow-500" />
                     <% else %>
                       <.icon name="hero-star" class="h-5 w-5 text-gray-300 group-hover/fav:text-yellow-400" />
                     <% end %>
                  </button>
                  <button phx-click="confirm_delete" phx-value-id={todo.id} phx-value-type="todo" class="text-gray-400 hover:text-red-500 opacity-0 group-hover:opacity-100 transition-opacity">
                    <.icon name="hero-trash" class="h-5 w-5" />
                  </button>
                </div>
              </div>
            </li>
          </ul>
          
          <!-- Pagination -->
          <div class="mt-6 flex items-center justify-between border-t border-gray-200 pt-4">
            <div class="flex flex-1 justify-between sm:hidden">
              <.link :if={@page > 1} patch={~p"/usecases/tasky?page=#{@page - 1}&search=#{@search}"} class="relative inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">
                Previous
              </.link>
              <.link :if={@page < @total_pages} patch={~p"/usecases/tasky?page=#{@page + 1}&search=#{@search}"} class="relative ml-3 inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">
                Next
              </.link>
            </div>
            <div class="hidden sm:flex sm:flex-1 sm:items-center sm:justify-between">
              <div>
                <p class="text-sm text-gray-700">
                  Showing page <span class="font-medium"><%= @page %></span> of <span class="font-medium"><%= @total_pages %></span>
                </p>
              </div>
              <div>
                <nav class="isolate inline-flex -space-x-px rounded-md shadow-sm" aria-label="Pagination">
                  <.link :if={@page > 1} patch={~p"/usecases/tasky?page=#{@page - 1}&search=#{@search}"} class="relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0">
                    <span class="sr-only">Previous</span>
                    <.icon name="hero-chevron-left-mini" class="h-5 w-5" />
                  </.link>
                  <.link :if={@page < @total_pages} patch={~p"/usecases/tasky?page=#{@page + 1}&search=#{@search}"} class="relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0">
                    <span class="sr-only">Next</span>
                    <.icon name="hero-chevron-right-mini" class="h-5 w-5" />
                  </.link>
                </nav>
              </div>
            </div>
          </div>
          

        </div>
      </div>



      <%= if @selected_todo do %>
      <.modal id="todo_detail_modal" show={true} on_cancel={Phoenix.LiveView.JS.push("close_todo")}>
        <div class="p-4 sm:px-6">
          <!-- Header -->
          <!-- Header -->
          <div class="mb-6 border-b pb-4 flex justify-between items-start">
            <div>
              <h2 class="text-2xl font-bold text-gray-900"><%= @selected_todo.title %></h2>
              <div class="mt-2 flex items-center gap-2">
                 <%= if @selected_todo.category do %>
                  <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
                    <%= @selected_todo.category %>
                  </span>
                 <% end %>
                 <%= if @selected_todo.priority do %>
                  <span class={"inline-flex items-center px-2 py-0.5 rounded text-xs font-medium #{priority_class(@selected_todo.priority)}"}>
                    <%= String.capitalize(@selected_todo.priority) %>
                  </span>
                 <% end %>
                  <%= if @selected_todo.due_date do %>
                      <span class={"text-xs #{due_date_class(@selected_todo.due_date)}"}>
                          <.icon name="hero-calendar" class="h-3 w-3 inline" />
                          <%= format_due_date(@selected_todo.due_date) %>
                      </span>
                  <% end %>
              </div>
            </div>
            <button phx-click="close_todo" class="text-gray-400 hover:text-gray-500 transition-colors">
              <.icon name="hero-x-mark" class="h-6 w-6" />
              <span class="sr-only">Close</span>
            </button>
          </div>

          <!-- Subtasks Section -->
          <div class="mb-8">
            <h3 class="text-lg font-medium text-gray-900 mb-3 flex items-center gap-2">
              <.icon name="hero-list-bullet" class="h-5 w-5 text-gray-500" />
              Subtasks
            </h3>
            
            <div class="space-y-2 mb-4">
              <%= for subtask <- @selected_todo.subtasks do %>
                <div class="flex items-center group">
                  <button phx-click="toggle_subtask" phx-value-id={subtask.id} class="focus:outline-none">
                    <%= if subtask.is_complete do %>
                      <.icon name="hero-check-circle-solid" class="h-5 w-5 text-green-500" />
                    <% else %>
                      <.icon name="hero-check-circle" class="h-5 w-5 text-gray-300 hover:text-green-500" />
                    <% end %>
                  </button>
                  <span class={"ml-2 text-sm flex-1 #{if subtask.is_complete, do: "text-gray-400 line-through", else: "text-gray-700"}"}>
                    <%= subtask.title %>
                  </span>
                  <button phx-click="delete_subtask" phx-value-id={subtask.id} class="text-gray-400 hover:text-red-500 opacity-0 group-hover:opacity-100 transition-opacity p-1">
                    <.icon name="hero-trash" class="h-4 w-4" />
                  </button>
                </div>
              <% end %>
              
              <%= if Enum.empty?(@selected_todo.subtasks) do %>
                <p class="text-sm text-gray-400 italic">No subtasks yet.</p>
              <% end %>
            </div>

            <form phx-submit="save_subtask" class="flex gap-2">
              <input type="text" name="subtask[title]" placeholder="Add a subtask..." required class="flex-1 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" />
              <button type="submit" class="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-indigo-700 bg-indigo-100 hover:bg-indigo-200 focus:outline-none">
                Add
              </button>
            </form>
          </div>

          <!-- Attachments Section -->
          <div class="mb-8">
            <h3 class="text-lg font-medium text-gray-900 mb-3 flex items-center gap-2">
              <.icon name="hero-paper-clip" class="h-5 w-5 text-gray-500" />
              Attachments
            </h3>

            <div class="grid grid-cols-2 gap-4 mb-4">
               <%= for attachment <- @selected_todo.attachments do %>
                 <div class="relative flex flex-col p-2 rounded border border-gray-200 bg-gray-50 group">
                    <div class="flex items-center mb-2">
                        <div class="flex-1 min-w-0">
                           <a href={attachment.path} target="_blank" class="text-sm font-medium text-indigo-600 hover:text-indigo-500 truncate block">
                             <%= attachment.filename %>
                           </a>
                           <p class="text-xs text-gray-500"><%= humanize_size(attachment.size) %></p>
                        </div>
                        <button phx-click="confirm_delete" phx-value-id={attachment.id} phx-value-type="attachment" class="ml-2 text-gray-400 hover:text-red-500 opacity-0 group-hover:opacity-100 transition-opacity">
                          <.icon name="hero-trash" class="h-4 w-4" />
                        </button>
                    </div>
                    
                    <%= if is_image?(attachment.content_type) do %>
                      <div class="mt-2 text-center bg-gray-200 rounded overflow-hidden">
                        <img src={attachment.path} class="max-h-32 mx-auto object-contain" />
                      </div>
                    <% end %>
                 </div>
               <% end %>
            </div>
            
            <!-- ... (upload form unchanged) ... -->


             <form phx-submit="save_attachment" phx-change="validate_upload">
               <div class="flex items-center justify-center w-full" phx-drop-target={@uploads.attachment.ref}>
                  <label class="flex flex-col items-center justify-center w-full h-32 border-2 border-gray-300 border-dashed rounded-lg cursor-pointer bg-gray-50 hover:bg-gray-100">
                      <div class="flex flex-col items-center justify-center pt-5 pb-6">
                           <.icon name="hero-cloud-arrow-up" class="h-8 w-8 text-gray-400 mb-2" />
                          <p class="text-sm text-gray-500"><span class="font-semibold">Click to upload</span> or drag and drop</p>
                      </div>
                      <.live_file_input upload={@uploads.attachment} class="hidden" />
                  </label>
               </div>
               
               <%= for entry <- @uploads.attachment.entries do %>
                 <div class="mt-2 flex items-center justify-between text-sm text-gray-600 bg-gray-100 p-2 rounded">
                   <span><%= entry.client_name %></span>
                   <button type="submit" class="text-indigo-600 font-medium hover:text-indigo-500">Upload</button>
                 </div>
               <% end %>
             </form>
          </div>

          <!-- Comments Section -->
          <div>
            <h3 class="text-lg font-medium text-gray-900 mb-3 flex items-center gap-2">
              <.icon name="hero-chat-bubble-left" class="h-5 w-5 text-gray-500" />
              Comments
            </h3>
            
            <div class="space-y-4 mb-4 max-h-60 overflow-y-auto">
              <%= for comment <- @selected_todo.comments do %>
                <div class="flex space-x-3">
                  <div class="flex-shrink-0">
                    <div class="h-8 w-8 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-700 font-bold text-xs">
                      <%= String.at(comment.user.email, 0) |> String.upcase() %>
                    </div>
                  </div>
                  <div class="flex-1 bg-gray-50 rounded-lg px-4 py-2">
                     <div class="flex items-center justify-between">
                        <h4 class="text-sm font-bold text-gray-900"><%= comment.user.email %></h4>
                        <span class="text-xs text-gray-500"><%= Calendar.strftime(comment.inserted_at, "%b %d, %H:%M") %></span>
                     </div>
                     <p class="text-sm text-gray-700 mt-1"><%= comment.content %></p>
                  </div>
                </div>
              <% end %>
               <%= if Enum.empty?(@selected_todo.comments) do %>
                <p class="text-sm text-gray-400 italic">No comments yet.</p>
              <% end %>
            </div>
            
            <form phx-submit="save_comment">
              <div class="mt-2">
                <textarea name="comment[content]" rows="2" required placeholder="Add a comment..." class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"></textarea>
              </div>
              <div class="mt-2 flex justify-end">
                <button type="submit" class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none">
                  Post
                </button>
              </div>
            </form>
          </div>

        </div>
      </.modal>
      <% end %>
    </div>
      <%= if @show_confirm_modal do %>
      <.modal 
        id="confirm_modal" 
        show={@show_confirm_modal} 
        on_cancel={Phoenix.LiveView.JS.push("cancel_delete")}
      >
        <div class="p-4 sm:p-6 text-center">
            <div class="mx-auto flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-red-100 mb-4">
              <.icon name="hero-exclamation-triangle" class="h-6 w-6 text-red-600" />
            </div>
            <h3 class="text-base font-semibold leading-6 text-gray-900 mb-2">
              <%= if @confirm_delete_type == "todo", do: "Delete Task", else: "Delete Attachment" %>
            </h3>
            <p class="text-sm text-gray-500 mb-6">
              <%= if @confirm_delete_type == "todo" do %>
                Are you sure you want to delete this task? This action cannot be undone.
              <% else %>
                Are you sure you want to delete this attachment? This action cannot be undone.
              <% end %>
            </p>
            
            <div class="flex justify-end gap-3">
              <button 
                phx-click="cancel_delete"
                class="rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button 
                phx-click={if @confirm_delete_type == "todo", do: "delete_todo", else: "delete_attachment"}
                phx-value-id={@confirm_delete_id}
                class="rounded-md bg-red-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-red-500"
              >
                Delete
              </button>
            </div>
        </div>
      </.modal>
      <% end %>
    """
  end
end
