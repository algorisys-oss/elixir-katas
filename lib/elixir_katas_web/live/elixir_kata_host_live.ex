defmodule ElixirKatasWeb.ElixirKataHostLive do
  use ElixirKatasWeb, :live_view
  alias ElixirKatas.Katas.DynamicCompiler
  import ElixirKatasWeb.KataComponents

  def mount(params, session, socket) do
    slug = Map.get(params, "slug", "01")
    kata_id =
      case Regex.run(~r/^(\d+)/, slug) do
        [_, id] -> id
        _ -> "01"
      end

    user_token = session["user_token"]
    user =
      if user_token do
        case ElixirKatas.Accounts.get_user_by_session_token(user_token) do
          {user, _token} -> user
          _ -> nil
        end
      end

    user_id = if user, do: user.id, else: 0

    # 1. Resolve Files Dynamically
    source_pattern = "lib/elixir_katas_web/live/elixir_kata_#{kata_id}_*_live.ex"
    base_file =
      case Path.wildcard(source_pattern) do
        [file | _] -> file
        [] -> nil
      end

    if base_file == nil do
      {:ok, socket |> put_flash(:error, "Elixir Kata #{kata_id} not found.") |> push_navigate(to: ~p"/elixir-katas")}
    else
      file_source = File.read!(base_file)

      # Derive Title from Filename
      title =
        base_file
        |> Path.basename(".ex")
        |> String.replace("elixir_kata_", "Kata ")
        |> String.replace("_live", "")
        |> String.split("_")
        |> Enum.map_join(" ", &String.capitalize/1)
        |> String.replace(~r/^Kata (\d+)/, "Kata \\1:")

      # 2. Load Source (DB or File)
      kata_name = "ElixirKata#{kata_id}"
      {source_code, is_user_author} =
        if user_id != 0 do
          case ElixirKatas.Katas.get_user_kata(user_id, kata_name) do
            nil -> {file_source, false}
            user_kata -> {user_kata.source_code, true}
          end
        else
          {file_source, false}
        end

      # 3. Compile Initial
      {dynamic_module, flash} =
        case DynamicCompiler.compile(user_id, kata_name, source_code) do
          {:ok, module} -> {module, nil}
          {:error, err} -> {nil, {:error, "Initial compilation failed: #{inspect(err)}. Please fix the source code."}}
        end

      # 4. Load Notes
      notes_pattern = "notes/elixir_kata_#{kata_id}_*_notes.md"
      notes_path =
        case Path.wildcard(notes_pattern) do
          [file | _] -> file
          [] -> nil
        end

      notes_content =
        if notes_path && File.exists?(notes_path), do: File.read!(notes_path), else: "Notes not found."

      kata_mode = "full"
      initial_tab = "interactive"

      {:ok,
       socket
       |> assign(:dynamic_module, dynamic_module)
       |> assign(:source_code, source_code)
       |> assign(:user_id, user_id)
       |> assign(:kata_id, kata_id)
       |> assign(:title, title)
       |> assign(:active_tab, initial_tab)
       |> assign(:notes_content, notes_content)
       |> assign(:kata_mode, kata_mode)
       |> assign(:read_only, false)
       |> assign(:is_user_author, is_user_author)
       |> assign(:compiling, false)
       |> assign(:compile_error, nil)
       |> assign(:saved_at, nil)
       |> assign(:params, params)
       |> then(fn s ->
         if flash do
           {type, msg} = flash
           if type == :error and String.contains?(String.downcase(msg), "compilation failed") do
             assign(s, :compile_error, msg)
           else
             put_flash(s, type, msg)
           end
         else
           s
         end
       end)
      }
    end
  end

  def render(assigns) do
    ~H"""
    <.kata_viewer
      active_tab={@active_tab}
      title={@title}
      source_code={@source_code}
      notes_content={@notes_content}
      read_only={@read_only}
      is_user_author={@is_user_author}
      compile_error={@compile_error}
      compiling={@compiling}
      saved_at={@saved_at}
      mode={@kata_mode}
    >
      <div class="h-full w-full">
        <%= if @dynamic_module do %>
          <.live_component module={@dynamic_module} id="kata-sandbox" params={@params} />
        <% else %>
          <div class="flex flex-col items-center justify-center h-full text-zinc-500 gap-4">
            <.icon name="hero-exclamation-triangle" class="w-12 h-12 opacity-20" />
            <p>Waiting for successful compilation...</p>
          </div>
        <% end %>
      </div>
    </.kata_viewer>
    """
  end

  def handle_params(params, _uri, socket) do
    {:noreply, assign(socket, params: params)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("save_source", %{"source" => source}, socket) do
    user_id = socket.assigns.user_id
    kata_id = socket.assigns.kata_id
    kata_name = "ElixirKata#{kata_id}"

    _task = Task.async(fn ->
      compile_result = DynamicCompiler.compile(user_id, kata_name, source)

      if user_id != 0 do
        ElixirKatas.Katas.save_user_kata(user_id, kata_name, source)
      end

      compile_result
    end)

    {:noreply,
     socket
     |> assign(:compiling, true)
     |> assign(:source_code, source)
    }
  end

  def handle_event("revert", _, socket) do
    user_id = socket.assigns.user_id
    kata_id = socket.assigns.kata_id
    kata_name = "ElixirKata#{kata_id}"

    if user_id != 0 do
      ElixirKatas.Katas.delete_user_kata(user_id, kata_name)

      source_pattern = "lib/elixir_katas_web/live/elixir_kata_#{kata_id}_*_live.ex"
      base_file =
        case Path.wildcard(source_pattern) do
          [file | _] -> file
          [] -> nil
        end

      source_code = File.read!(base_file)
      {:ok, module} = DynamicCompiler.compile(user_id, kata_name, source_code)

      {:noreply,
       socket
       |> assign(:source_code, source_code)
       |> assign(:dynamic_module, module)
       |> assign(:is_user_author, false)
       |> put_flash(:info, "Reverted to original version!")
      }
    else
      {:noreply, put_flash(socket, :error, "Cannot revert as Guest.")}
    end
  end

  # Catch-all to forward hook events to the component
  def handle_event(event, params, socket) do
    if socket.assigns.dynamic_module do
      send_update(socket.assigns.dynamic_module, id: "kata-sandbox", event: event, params: params)
    end
    {:noreply, socket}
  end

  def handle_info({ref, result}, socket) when is_reference(ref) do
    Process.demonitor(ref, [:flush])

    case result do
      {:ok, new_module} ->
        {:noreply,
         socket
         |> assign(:compiling, false)
         |> assign(:compile_error, nil)
         |> assign(:saved_at, System.system_time(:second))
         |> assign(:dynamic_module, new_module)
         |> assign(:is_user_author, true)
        }

      {:error, err} ->
        {:noreply,
         socket
         |> assign(:compiling, false)
         |> assign(:compile_error, "Compilation failed: #{inspect(err)}")
        }
    end
  end

  def handle_info({:DOWN, _ref, :process, _pid, reason}, socket) do
    {:noreply,
     socket
     |> assign(:compiling, false)
     |> put_flash(:error, "Compiler crashed: #{inspect(reason)}")
    }
  end

  def handle_info(msg, socket) do
    if socket.assigns.dynamic_module do
      send_update(socket.assigns.dynamic_module, id: "kata-sandbox", info_msg: msg)
    end
    {:noreply, socket}
  end
end
