defmodule ElixirKatasWeb.PageController do
  use ElixirKatasWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
