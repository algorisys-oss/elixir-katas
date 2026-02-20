defmodule ElixirKatasWeb.Presence do
  @moduledoc """
  Provides presence tracking to processes and channels.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :elixir_katas,
    pubsub_server: ElixirKatas.PubSub
end
