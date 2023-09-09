defmodule Metamorphic.Memories.Memory do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.Accounts
  alias Metamorphic.Accounts.User
  alias Metamorphic.Encrypted
  alias Metamorphic.Encrypted.Utils
  alias Metamorphic.Memories.UserMemory

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "memories" do
    field :memory_url, Encrypted.Binary
    field :memory_url_hash, Encrypted.HMAC
    field :username, Encrypted.Binary
    field :username_hash, Encrypted.HMAC
    field :favs_list, {:array, :binary_id}, default: []
    field :favs_count, :integer
    field :visibility, Ecto.Enum, values: [:public, :private, :connections], default: :private
    field :size, :decimal
    field :type, :string
    field :blurb, Encrypted.Binary

    field :user_memory_map, :map, virtual: true

    embeds_many :shared_users, SharedUser, on_replace: :delete do
      field :sender_id, :string, virtual: true
      field :username, :string, virtual: true
      field :user_id, :binary_id
    end

    belongs_to :user, User

    has_many :user_memories, UserMemory

    timestamps()
  end

  @doc false
  def changeset(memory, attrs, opts \\ []) do
    memory
    |> cast(attrs, [
      :memory_url,
      :blurb,
      :username,
      :favs_count,
      :favs_list,
      :user_id,
      :visibility,
      :size,
      :type
    ])
    |> validate_required([:blurb, :username, :user_id])
    |> validate_length(:blurb, max: 250)
    |> add_username_hash()
    |> add_memory_url_hash()
    |> validate_visibility(opts)
    |> encrypt_attrs(opts)
    |> cast_embed(:shared_users,
      with: &shared_user_changeset/2,
      sort_param: :shared_users_order,
      drop_param: :shared_users_delete
    )
  end

  def shared_user_changeset(shared_user, attrs \\ %{}, _opts \\ []) do
    shared_user
    |> cast(attrs, [:sender_id, :username])
    |> validate_shared_username()
  end

  defp add_username_hash(changeset) do
    if Map.has_key?(changeset.changes, :username) do
      changeset
      |> put_change(:username_hash, String.downcase(get_field(changeset, :username)))
    else
      changeset
    end
  end

  defp add_memory_url_hash(changeset) do
    if Map.has_key?(changeset.changes, :memory_url) do
      changeset
      |> put_change(:memory_url_hash, String.downcase(get_field(changeset, :memory_url)))
    else
      changeset
    end
  end

  defp validate_visibility(changeset, opts) do
    visibility = get_field(changeset, :visibility)

    case visibility do
      :public ->
        changeset

      :private ->
        changeset

      :connections ->
        if Accounts.has_any_user_connections?(opts[:user]) do
          changeset
        else
          changeset |> add_error(:blurb, "Woopsy, first we need to make some connections.")
        end
    end
  end

  defp validate_shared_username(changeset) do
    changeset
    |> validate_required([:username])
    |> validate_length(:username, min: 2, max: 160)
    |> maybe_add_recipient_id_by_username()
  end

  # The recipient is either the user_id or reverse_user_id
  # of the connection.
  defp maybe_add_recipient_id_by_username(changeset) do
    username = get_change(changeset, :username, "")
    user_id = get_field(changeset, :sender_id)

    if recipient = Accounts.get_shared_user_by_username(user_id, username) do
      changeset
      |> put_change(:user_id, recipient.id)
    else
      changeset
      |> add_error(:username, "invalid or does not exist")
    end
  end

  defp encrypt_attrs(changeset, opts) do
    if changeset.valid? && opts[:user] && opts[:key] do
      body = get_change(changeset, :blurb)
      username = get_field(changeset, :username)
      visibility = get_field(changeset, :visibility)
      memory_url = get_field(changeset, :memory_url)
      memory_key = maybe_generate_memory_key(opts, visibility)

      case visibility do
        :public ->
          changeset
          |> put_change(:memory_url, Utils.encrypt(%{key: memory_key, payload: memory_url}))
          |> put_change(:blurb, Utils.encrypt(%{key: memory_key, payload: body}))
          |> put_change(:username, Utils.encrypt(%{key: memory_key, payload: username}))
          |> put_change(:user_memory_map, %{
            key:
              Encrypted.Utils.encrypt_message_for_user_with_pk(memory_key, %{
                public: Encrypted.Session.server_public_key()
              })
          })

        :private ->
          changeset
          |> put_change(:memory_url, Utils.encrypt(%{key: memory_key, payload: memory_url}))
          |> put_change(:blurb, Utils.encrypt(%{key: memory_key, payload: body}))
          |> put_change(:username, Utils.encrypt(%{key: memory_key, payload: username}))
          |> put_change(:user_memory_map, %{
            key:
              Encrypted.Utils.encrypt_message_for_user_with_pk(memory_key, %{
                public: opts[:user].key_pair["public"]
              })
          })

        :connections ->
          changeset
          |> put_change(:memory_url, Utils.encrypt(%{key: memory_key, payload: memory_url}))
          |> put_change(:blurb, Utils.encrypt(%{key: memory_key, payload: body}))
          |> put_change(:username, Utils.encrypt(%{key: memory_key, payload: username}))
          |> put_change(:user_memory_map, %{
            key:
              Encrypted.Utils.encrypt_message_for_user_with_pk(memory_key, %{
                public: opts[:user].key_pair["public"]
              })
          })

        _rest ->
          changeset |> add_error(:blurb, "There was an error determining the visibility.")
      end
    else
      changeset
    end
  end

  defp maybe_generate_memory_key(opts, visibility) do
    if opts[:update_memory] do
      case visibility do
        :public ->
          Encrypted.Users.Utils.decrypt_public_item_key(opts[:memory_key])

        _rest ->
          {:ok, d_memory_key} =
            Encrypted.Users.Utils.decrypt_user_attrs_key(
              opts[:memory_key],
              opts[:user],
              opts[:key]
            )

          d_memory_key
      end
    else
      case visibility do
        :connections ->
          {:ok, d_memory_key} =
            Encrypted.Users.Utils.decrypt_user_attrs_key(
              opts[:user].conn_key,
              opts[:user],
              opts[:key]
            )

          d_memory_key

        _rest ->
          Encrypted.Utils.generate_key()
      end
    end
  end
end
