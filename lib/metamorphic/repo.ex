defmodule Metamorphic.Repo.Local do
  use Ecto.Repo,
    otp_app: :metamorphic,
    adapter: Ecto.Adapters.Postgres

  @env Mix.env()

  # Dynamically configure the database url based on runtime and build
  # environments.
  def init(_type, config) do
    Fly.Postgres.config_repo_url(config, @env)
  end
end

defmodule Metamorphic.Repo do
  use Fly.Repo, local_repo: Metamorphic.Repo.Local

  def transaction_on_primary(tx_fun) do
    Fly.Postgres.rpc_and_wait(__MODULE__, :transaction, [tx_fun])
  end
end
