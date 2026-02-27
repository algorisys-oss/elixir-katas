defmodule ElixirKatasWeb.Hooks.KataSection do
  @moduledoc "Sets @kata_section assign so the root layout can display the current section name."
  import Phoenix.Component, only: [assign: 3]

  def on_mount(section, _params, _session, socket) do
    {:cont, assign(socket, :kata_section, section)}
  end
end
