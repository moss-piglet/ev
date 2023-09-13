defmodule Metamorphic.Accounts.Connection do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.Accounts.{User, UserConnection}

  alias Metamorphic.Encrypted
  alias Metamorphic.Encrypted.Utils

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "connections" do
    field :name, Encrypted.Binary
    field :name_hash, Encrypted.HMAC
    field :email, Encrypted.Binary
    field :email_hash, Encrypted.HMAC
    field :username, Encrypted.Binary
    field :username_hash, Encrypted.HMAC
    field :avatar_url, Encrypted.Binary
    field :avatar_url_hash, Encrypted.HMAC

    embeds_one :profile, ConnectionProfile, on_replace: :update do
      field :name, Encrypted.Binary
      field :about, Encrypted.Binary
      field :email, Encrypted.Binary
      field :username, Encrypted.Binary
      field :avatar_url, Encrypted.Binary
      field :slug, Encrypted.Binary
      field :profile_key, Encrypted.Binary
      field :show_avatar?, :boolean, default: false
      field :show_email?, :boolean, default: false
      field :show_name?, :boolean, default: false
      field :show_public_memories?, :boolean, default: false
      field :user_id, :binary_id
      field :visibility, Ecto.Enum, values: [:public, :private, :connections], default: :private

      field :opts_map, :map, virtual: true
    end

    belongs_to :user, User

    has_many :user_connections, UserConnection

    timestamps()
  end

  def register_changeset(conn, attrs \\ %{}) do
    conn
    |> cast(attrs, [:email, :email_hash, :username, :username_hash])
    |> cast_assoc(:user)
    |> validate_required([:email, :email_hash, :username, :username_hash])
    |> add_email_hash()
    |> add_username_hash()
  end

  def profile_changeset(conn, attrs \\ %{}, _opts \\ []) do
    conn
    |> cast(attrs, [:id])
    |> cast_embed(:profile,
      with: &connection_profile_changeset/2
    )
  end

  def connection_profile_changeset(profile, attrs \\ %{}) do
    opts_map = attrs["opts_map"]

    profile
    |> cast(attrs, [
      :user_id,
      :name,
      :about,
      :email,
      :username,
      :avatar_url,
      :show_avatar?,
      :show_email?,
      :show_name?,
      :show_public_memories?,
      :slug,
      :visibility,
      :profile_key,
      :opts_map
    ])
    |> validate_length(:about, max: 500)
    |> build_slug()
    |> encrypt_attrs(opts_map)
  end

  def update_username_changeset(conn, attrs \\ %{}) do
    conn
    |> cast(attrs, [:username, :username_hash])
    |> add_username_hash()
  end

  def update_email_changeset(conn, attrs \\ %{}) do
    conn
    |> cast(attrs, [:email, :email_hash])
    |> add_email_hash()
  end

  def update_avatar_changeset(conn, attrs \\ %{}, opts \\ []) do
    conn
    |> cast(attrs, [:avatar_url, :avatar_url_hash])
    |> add_avatar_hash(opts)
  end

  # The email_hash comes through as a temp clear text
  # so we go straight ahead and hash it. The `:email`
  # is coming through already encrypted correctly
  # from the user changeset.
  defp add_email_hash(changeset) do
    if Map.has_key?(changeset.changes, :email_hash) do
      changeset
      |> put_change(:email_hash, String.downcase(get_field(changeset, :email_hash)))
    else
      changeset
    end
  end

  # The avatar_url_hash comes through as a temp clear text
  # so we go straight ahead and hash it. The `:avatar_url`
  # is coming through already encrypted correctly
  # from the user changeset.
  defp add_avatar_hash(changeset, opts) do
    if Map.has_key?(changeset.changes, :avatar_url_hash) do
      if opts[:delete_avatar] do
        changeset
        |> put_change(:avatar_url_hash, nil)
      else
        changeset
        |> put_change(:avatar_url_hash, String.downcase(get_field(changeset, :avatar_url_hash)))
      end
    else
      changeset
    end
  end

  # The username_hash comes through as a temp clear text
  # so we go straight ahead and hash it. The `:username`
  # is coming through already encrypted correctly
  # from the user changeset.
  defp add_username_hash(changeset) do
    if Map.has_key?(changeset.changes, :username_hash) do
      changeset
      |> put_change(:username_hash, String.downcase(get_field(changeset, :username_hash)))
    else
      changeset
    end
  end

  defp build_slug(changeset) do
    if username = get_field(changeset, :username) do
      slug = Slug.slugify(username)
      put_change(changeset, :slug, slug)
    else
      changeset
    end
  end

  defp encrypt_attrs(changeset, opts_map) do
    if changeset.valid? && opts_map && Map.has_key?(opts_map, :encrypt) do
      about = get_field(changeset, :about)
      username = get_field(changeset, :username)
      name = get_field(changeset, :name)
      visibility = opts_map.user.visibility
      profile_key = maybe_generate_key(opts_map, visibility)
      e_avatar_url = maybe_encrypt_avatar_url(opts_map.user, profile_key)

      case visibility do
        :public ->
          changeset
          |> put_change(:avatar_url, e_avatar_url)
          # |> put_change(:name, Utils.encrypt(%{key: profile_key, payload: name}))
          |> put_change(:about, Utils.encrypt(%{key: profile_key, payload: about}))
          |> put_change(:username, Utils.encrypt(%{key: profile_key, payload: username}))
          |> put_change(
            :profile_key,
            Encrypted.Utils.encrypt_message_for_user_with_pk(profile_key, %{
              public: Encrypted.Session.server_public_key()
            })
          )

        :private ->
          changeset
          |> put_change(:avatar_url, e_avatar_url)
          # |> put_change(:name, Utils.encrypt(%{key: profile_key, payload: name}))
          |> put_change(:about, Utils.encrypt(%{key: profile_key, payload: about}))
          |> put_change(:username, Utils.encrypt(%{key: profile_key, payload: username}))
          |> put_change(
            :profile_key,
            Encrypted.Utils.encrypt_message_for_user_with_pk(profile_key, %{
              public: opts_map.user.key_pair["public"]
            })
          )

        :connections ->
          changeset
          |> put_change(:avatar_url, e_avatar_url)
          # |> put_change(:name, Utils.encrypt(%{key: profile_key, payload: name}))
          |> put_change(:about, Utils.encrypt(%{key: profile_key, payload: about}))
          |> put_change(:username, Utils.encrypt(%{key: profile_key, payload: username}))
          |> put_change(
            :profile_key,
            Encrypted.Utils.encrypt_message_for_user_with_pk(profile_key, %{
              public: opts_map.user.key_pair["public"]
            })
          )

        _rest ->
          changeset |> add_error(:about, "There was an error determining the visibility.")
      end
    else
      changeset
    end
  end

  defp maybe_encrypt_avatar_url(user, profile_key) do
    case user.avatar_url do
      nil ->
        nil

      avatar_url ->
        Utils.encrypt(%{key: profile_key, payload: avatar_url})
    end
  end

  defp maybe_generate_key(opts_map, visibility) do
    if Map.get(opts_map, :update_profile) do
      profile_viz = Map.get(opts_map.user.connection.profile, :visibility)

      case profile_viz do
        :public ->
          Encrypted.Users.Utils.decrypt_public_item_key(
            opts_map.user.connection.profile.profile_key
          )

        _rest ->
          {:ok, d_profile_key} =
            Encrypted.Users.Utils.decrypt_user_attrs_key(
              opts_map.user.connection.profile.profile_key,
              opts_map.user,
              opts_map.key
            )

          d_profile_key
      end
    else
      case visibility do
        :connections ->
          {:ok, d_profile_key} =
            Encrypted.Users.Utils.decrypt_user_attrs_key(
              opts_map.user.conn_key,
              opts_map.user,
              opts_map.key
            )

          d_profile_key

        _rest ->
          IO.puts("GENERATING NEW KEY")
          Encrypted.Utils.generate_key()
      end
    end
  end
end
