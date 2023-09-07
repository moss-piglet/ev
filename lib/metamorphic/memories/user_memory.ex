defmodule Metamorphic.Memories.UserMemory do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.Accounts.User
  alias Metamorphic.Encrypted
  alias Metamorphic.Memories.Memory

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_memories" do
    field :key, Encrypted.Binary

    belongs_to :memory, Memory
    belongs_to :user, User

    timestamps()
  end

  def changeset(user_memory, attrs \\ %{}) do
    user_memory
    |> cast(attrs, [:key])
    |> cast_assoc(:memory)
    |> cast_assoc(:user)
    |> validate_required([:key])
  end
end
