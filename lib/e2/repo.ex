defmodule E2.Repo do
  use Ecto.Repo,
    otp_app: :e2,
    adapter: Ecto.Adapters.Postgres
end
