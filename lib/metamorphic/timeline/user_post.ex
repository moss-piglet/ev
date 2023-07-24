defmodule Metamorphic.Timeline.UserPost do
  @moduledoc false
  use Ecto.Schema

  alias Metamorphic.Accounts.User
  alias Metamorphic.Encrypted
  alias Metamorphic.Timeline.Post

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_posts" do
    field :key, Encrypted.Binary

    belongs_to :user, User
    belongs_to :post, Post

    timestamps()
  end
end
