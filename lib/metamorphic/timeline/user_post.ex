defmodule Metamorphic.Timeline.UserPost do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.Accounts.User
  alias Metamorphic.Encrypted
  alias Metamorphic.Timeline.Post

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_posts" do
    field :key, Encrypted.Binary

    belongs_to :post, Post
    belongs_to :user, User

    timestamps()
  end

  def changeset(user_post, attrs \\ %{}) do
    user_post
    |> cast(attrs, [:key])
    |> cast_assoc(:post)
    |> cast_assoc(:user)
    |> validate_required([:key])
  end
end
