defmodule Metamorphic.Repo do
  use Ecto.Repo,
    otp_app: :metamorphic,
    adapter: Ecto.Adapters.Postgres
end
