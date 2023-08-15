defmodule Metamorphic.Accounts.Connection do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.Accounts.{User, UserConnection}

  alias Metamorphic.Encrypted

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
end
