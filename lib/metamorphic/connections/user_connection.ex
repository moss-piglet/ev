defmodule Metamorphic.Connections.UserConnection do
  @moduledoc false
  use Ecto.Schema

  alias Metamorphic.Accounts
  alias Metamorphic.Connections

  alias Metamorphic.Encrypted

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_connections" do
    field :key, Encrypted.Binary
    field :photos?, :boolean
    field :zen?, :boolean

    belongs_to :connection, Connections.Connection
    belongs_to :user, Accounts.User

    timestamps()
  end
end
