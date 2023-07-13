defmodule E2.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      E2Web.Telemetry,
      # Start the Ecto repository
      E2.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: E2.PubSub},
      # Start Finch
      {Finch, name: E2.Finch},
      # Start the Endpoint (http/https)
      E2Web.Endpoint
      # Start a worker by calling: E2.Worker.start_link(arg)
      # {E2.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: E2.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    E2Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
