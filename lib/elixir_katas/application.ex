defmodule ElixirKatas.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ElixirKatasWeb.Telemetry,
      ElixirKatas.Repo,
      {DNSCluster, query: Application.get_env(:elixir_katas, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ElixirKatas.PubSub},
      ElixirKatasWeb.Presence,
      # Start the JobQueue GenServer for background job processing
      {ElixirKatas.Workers.JobQueue, []},
      # Start the VendingMachine state machine
      {ElixirKatas.Workers.VendingMachine, []},
      # Start to serve requests, typically the last entry
      ElixirKatasWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirKatas.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ElixirKatasWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
