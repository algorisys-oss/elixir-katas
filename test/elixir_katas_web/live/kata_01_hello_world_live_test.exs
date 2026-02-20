defmodule ElixirKatasWeb.Kata01HelloWorldLiveTest do
  use ElixirKatasWeb.ConnCase

  import Phoenix.LiveViewTest

  test "renders hello world kata", %{conn: conn} do
    {:ok, view, html} = live(conn, "/katas/01-hello-world")

    assert html =~ "Kata 01: Hello World"
    assert html =~ "Description"
    
    # Check default tab content (Notes)
    assert html =~ "prose dark:prose-invert"
    
    # Switch to Interactive
    html = view
           |> element("button", "Interactive")
           |> render_click()
    
    assert html =~ "Welcome to your first Elixir LiveView Kata"
    assert html =~ "Click me!"
    
    # Switch to Source
    html = view
           |> element("button", "Source Code")
           |> render_click()
           
    # Check for editor div hook
    assert html =~ "phx-hook=\"CodeEditor\""
    
    # Test saving source (mocked in test env)
    source = File.read!("lib/elixir_katas_web/live/kata_01_hello_world_live.ex")
    
    result = render_hook(view, "save_source", %{"source" => source})
    assert result =~ "Source saved!"
  end
end
