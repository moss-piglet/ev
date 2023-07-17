defmodule Metamorphic.Repo do
  use Ecto.Repo,
    otp_app: :Metamorphic,
    adapter: Ecto.Adapters.Postgres
end
