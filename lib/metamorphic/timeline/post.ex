defmodule Metamorphic.Timeline.Post do
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.Accounts.User
  alias Metamorphic.Timeline.{Post, UserPost}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "posts" do
    field :body, :string
    field :username, :string
    field :favs_list, {:array, :binary_id}, default: []
    field :reposts_list, {:array, :binary_id}, default: []
    field :favs_count, :integer, default: 0
    field :reposts_count, :integer, default: 0
    field :repost, :boolean, default: false
    field :visibility, Ecto.Enum, values: [:public, :private, :connections], default: :public

    belongs_to :user, User
    belongs_to :original_post, Post

    has_many :user_posts, UserPost

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [
      :body,
      :username,
      :favs_count,
      :reposts_count,
      :reposts_list,
      :favs_list,
      :user_id,
      :visibility
    ])
    |> cast_assoc(:user_posts, with: &UserPost.changeset/2)
    |> validate_required([:body, :username, :user_id])
    |> validate_length(:body, min: 2, max: 250)
  end

  @doc false
  def repost_changeset(post, attrs) do
    post
    |> cast(attrs, [
      :body,
      :username,
      :favs_list,
      :favs_count,
      :reposts_list,
      :reposts_count,
      :repost,
      :user_id,
      :original_post_id,
      :visibility
    ])
    |> cast_assoc(:user_posts, with: &UserPost.changeset/2)
    |> validate_required([:body, :username, :reposts_list, :repost, :user_id, :original_post_id])
    |> validate_length(:body, min: 2, max: 250)
  end
end
