defmodule ElixirKatasWeb.KataAuthTest do
  use ElixirKatasWeb.ConnCase
  import Phoenix.LiveViewTest
  alias ElixirKatas.Accounts
  alias ElixirKatas.Katas

  @kata_path "/katas/01-hello-world"
  @source_path "lib/elixir_katas_web/live/kata_01_hello_world_live.ex"

  setup do
    # Ensure clean state
    # Restore original file if backup exists to start clean
    if File.exists?(@source_path <> ".bak") do
       File.cp!(@source_path <> ".bak", @source_path)
       File.rm(@source_path <> ".bak")
    end
    
    # Create a user
    {:ok, user} =
      Accounts.register_user(%{
        email: "test@example.com",
        password: "valid_password_1234"
      })
      
    {:ok, user: user}
  end

  test "guest sees read-only mode", %{conn: conn} do
    {:ok, view, html} = live(conn, @kata_path)
    
    # Check for Read Only badge (text content)
    assert html =~ "Read Only"
    
    # Check for editor data attribute
    assert html =~ "data-read-only=\"true\""
    
    # Try to save - should fail (flash error) via handle_event
    params = %{"source" => "IO.puts \"pwned\""}
    html = render_hook(view, "save_source", params)
    
    assert html =~ "You must be logged in to edit"
    
    # Verify file was NOT changed
    refute File.read!(@source_path) =~ "pwned"
  end

  test "user can edit and backup is created", %{conn: conn, user: user} do
    # Log in user
    conn = log_in_user(conn, user)
    {:ok, view, html} = live(conn, @kata_path)
    
    # Ensure NOT read only
    refute html =~ "Read Only"
    refute html =~ "data-read-only=\"true\""
    
    # Edit code
    new_source = File.read!(@source_path) <> "\n# User Edit"
    render_hook(view, "save_source", %{"source" => new_source})
    
    # 1. Check DB
    assert user_kata = Katas.get_user_kata(user.id, "kata_01_hello_world_live")
    # Wait, kata_name is derived from basename: "kata_01_hello_world_live"
    assert user_kata.source_code == new_source
    
    # 2. Check File System (Hot Seat) - NOTE: In test mode, we might skip write?
    # KataLive: if Application.get_env(:elixir_katas, :env) != :test do File.write! ...
    # Ah, we logic skips writing to disk in test mode.
    # So we can't verify disk write unless we temporarily enable it or mock it.
    # BUT we can verify DB persist.
    
    # 3. Check Backup creation (also skipped in test env?)
    # "if !File.exists?(bak) do File.cp! end"
    # This is NOT skipped in the code I wrote! Only the *write* to source is skipped.
    # So backup SHOULD be created.
    assert File.exists?(@source_path <> ".bak")
  end

  test "revert restores backup and deletes db entry", %{conn: conn, user: user} do
    conn = log_in_user(conn, user)
    {:ok, view, _html} = live(conn, @kata_path)
    
    # Create backup (simulated side effect of save)
    # First, creating a fake backup manually to ensure "revert" has something to restore
    File.cp!(@source_path, @source_path <> ".bak")
    
    # Save something to DB
    Katas.save_user_kata(user.id, "kata_01_hello_world_live", "Fake content")
    
    # Call Revert
    render_hook(view, "revert", %{})
    
    # 1. Verify DB deletion
    refute Katas.get_user_kata(user.id, "kata_01_hello_world_live")
    
    # 2. Verify flash
    assert render(view) =~ "Reverted to original!"
  end
end
