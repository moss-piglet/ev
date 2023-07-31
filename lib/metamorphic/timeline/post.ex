defmodule Metamorphic.Timeline.Post do
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.Accounts.User
  alias Metamorphic.Encrypted
  alias Metamorphic.Encrypted.Utils
  alias Metamorphic.Timeline.{Post, UserPost}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "posts" do
    field :body, Encrypted.Binary
    field :username, Encrypted.Binary
    field :username_hash, Encrypted.HMAC
    field :favs_list, {:array, :binary_id}, default: []
    field :reposts_list, {:array, :binary_id}, default: []
    field :favs_count, :integer, default: 0
    field :reposts_count, :integer, default: 0
    field :repost, :boolean, default: false
    field :visibility, Ecto.Enum, values: [:public, :private, :connections], default: :public

    field :user_post_map, :map, virtual: true

    belongs_to :user, User
    belongs_to :original_post, Post

    has_many :user_posts, UserPost

    timestamps()
  end

  @doc false
  def changeset(post, attrs, opts \\ []) do
    post
    |> cast(attrs, [
      :body,
      :username,
      :username_hash,
      :favs_count,
      :reposts_count,
      :reposts_list,
      :favs_list,
      :user_id,
      :visibility
    ])
    |> validate_required([:body, :username, :user_id])
    |> validate_length(:body, min: 2, max: 250)
    |> add_username_hash()
    |> encrypt_attrs(opts)
  end

  @doc false
  def repost_changeset(post, attrs, opts \\ []) do
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
    |> add_username_hash()
    |> encrypt_attrs(opts)
  end

  defp add_username_hash(changeset) do
    if Map.has_key?(changeset.changes, :username) do
      changeset
      |> put_change(:username_hash, String.downcase(get_field(changeset, :username)))
    else
      changeset
    end
  end

  defp encrypt_attrs(changeset, opts) do
    if changeset.valid? && opts[:user] && opts[:key] do
      body = get_change(changeset, :body)
      username = get_field(changeset, :username)
      visibility = get_field(changeset, :visibility)
      post_key = maybe_generate_post_key(opts, visibility)

      case visibility do
        :public ->
          changeset
          |> put_change(:body, Utils.encrypt(%{key: post_key, payload: body}))
          |> put_change(:username, Utils.encrypt(%{key: post_key, payload: username}))
          |> put_change(:user_post_map, %{
            key:
              Encrypted.Utils.encrypt_message_for_user_with_pk(post_key, %{
                public: Encrypted.Session.server_public_key()
              })
          })

        :private ->
          changeset
          |> put_change(:body, Utils.encrypt(%{key: post_key, payload: body}))
          |> put_change(:username, Utils.encrypt(%{key: post_key, payload: username}))
          |> put_change(:user_post_map, %{
            key:
              Encrypted.Utils.encrypt_message_for_user_with_pk(post_key, %{
                public: opts[:user].key_pair["public"]
              })
          })

        :connections ->
          changeset |> add_error(:body, "TODO connections")

        _rest ->
          changeset |> add_error(:body, "VISIBILITY OFF")
      end
    else
      changeset
    end
  end

  defp maybe_generate_post_key(opts, visibility) do
    if opts[:update_post] do
      case visibility do
        :public ->
          Encrypted.Users.Utils.decrypt_public_post_key(opts[:post_key])

        :private ->
          Encrypted.Users.Utils.decrypt_user_attrs_key(opts[:post_key], opts[:user], opts[:key])

        :connections ->
          :error
      end
    else
      Encrypted.Utils.generate_key()
    end
  end
end
