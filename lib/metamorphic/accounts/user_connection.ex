defmodule Metamorphic.Accounts.UserConnection do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.Accounts.{Connection, User}

  alias Metamorphic.Encrypted

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_connections" do
    field :key, Encrypted.Binary
    field :photos?, :boolean
    field :zen?, :boolean
    field :label, Encrypted.Binary

    belongs_to :connection, Connection
    belongs_to :user, User

    timestamps()
  end

  def changeset(user_conn, attrs \\ %{}, _opts \\ []) do
    user_conn
    |> cast(attrs, [:key, :photos?, :zen?, :label, :connection_id, :user_id])
    |> validate_required([:key, :connection_id, :user_id])
  end
end
