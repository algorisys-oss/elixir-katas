defmodule ElixirKatas.Repo do
  use Ecto.Repo,
    otp_app: :elixir_katas,
    adapter: Ecto.Adapters.SQLite3
end
