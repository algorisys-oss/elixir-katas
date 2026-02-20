defmodule KataMigrator do
  def migrate_all do
    IO.puts "Starting SAFE Bulk Kata Migration..."
    
    source_dir = "lib/elixir_katas_web/live"
    katas = Path.wildcard("#{source_dir}/kata_*.ex")
    
    katas
    |> Enum.reject(&String.contains?(&1, "kata_host_live.ex"))
    |> Enum.reject(&String.contains?(&1, "kata_active_counter_live.ex"))
    |> Enum.reject(&String.contains?(&1, "kata_live.ex"))
    |> Enum.each(&migrate_file/1)
    
    IO.puts "Migration Complete!"
  end

  def migrate_file(path) do
    IO.puts "Migrating #{path}..."
    content = File.read!(path)
    
    # 1. Change use to :live_component
    content = String.replace(content, "use ElixirKatasWeb, :live_view", "use ElixirKatasWeb, :live_component")
    
    # 2. Rename mount/3 to update/2 and inject assign(assigns)
    content = Regex.replace(~r/def mount\(([^,]*), ([^,]*), (socket)\) do/s, content, "def update(assigns, \\3) do\n    \\3 = assign(\\3, assigns)")

    # 3. Strip File.read! calls and local variable assignments
    content = Regex.replace(~r/source_code\s*=\s*File\.read!\([^)]*?\)\s*/s, content, "")
    content = Regex.replace(~r/notes_content\s*=\s*File\.read!\([^)]*?\)\s*/s, content, "")
    
    # 4. Strip corresponding assigns (Very aggressive)
    # Handle |> assign(...)
    content = Regex.replace(~r/\|\>\s*assign\(\s*:?source_code,.*?\)/s, content, "")
    content = Regex.replace(~r/\|\>\s*assign\(\s*source_code:.*?\)/s, content, "")
    content = Regex.replace(~r/\|\>\s*assign\(\s*:?notes_content,.*?\)/s, content, "")
    content = Regex.replace(~r/\|\>\s*assign\(\s*notes_content:.*?\)/s, content, "")
    
    # Handle assign(socket, ...)
    content = Regex.replace(~r/assign\(\s*socket,\s*:?source_code,.*?\)/s, content, "socket")
    content = Regex.replace(~r/assign\(\s*socket,\s*source_code:.*?\)/s, content, "socket")
    content = Regex.replace(~r/assign\(\s*socket,\s*:?notes_content,.*?\)/s, content, "socket")
    content = Regex.replace(~r/assign\(\s*socket,\s*notes_content:.*?\)/s, content, "socket")

    # 5. Strip <.kata_viewer> wrapper
    content = Regex.replace(~r/<.kata_viewer.*?>/s, content, "")
    content = String.replace(content, "</.kata_viewer>", "")
    
    # 6. Inject phx-target={@myself} into interactive tags
    content = Regex.replace(~r/(<(button|form|div|input|a|textarea|select)\s+[^>]*?phx-(click|change|submit|blur|focus|keydown|keyup)="[^"]+")(?![^>]*?phx-target=)/s, content, "\\1 phx-target={@myself}")
    
    File.write!(path, content)
  end
end

KataMigrator.migrate_all()
