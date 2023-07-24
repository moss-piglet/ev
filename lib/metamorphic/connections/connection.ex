defmodule Metamorphic.Connections.Connection do
  @moduledoc false
  use Ecto.Schema

  alias Metamorphic.Accounts
  alias Metamorphic.Connections

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "connections" do
    field :name, :binary
    field :name_hash, :binary
    field :email, :binary
    field :email_hash, :binary
    field :username, :binary
    field :username_hash, :binary

    many_to_many :users, Accounts.User, join_through: Connections.UserConnection

    timestamps()
  end
end
