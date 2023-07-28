defmodule Metamorphic.Accounts.UserConnection do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias Metamorphic.Accounts
  alias Metamorphic.Accounts.{Connection, User}

  alias Metamorphic.Encrypted

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_connections" do
    field :key, Encrypted.Binary
    field :photos?, :boolean
    field :zen?, :boolean
    field :label, Encrypted.Binary
    field :label_hash, Encrypted.HMAC
    field :confirmed_at, :naive_datetime
    field :username, :string, virtual: true
    field :email, :string, virtual: true

    belongs_to :connection, Connection
    belongs_to :user, User

    timestamps()
  end

  def changeset(user_conn, attrs \\ %{}, opts \\ []) do
    user_conn
    |> cast(attrs, [:key, :photos?, :zen?, :label, :email, :username, :user_id, :connection_id])
    |> cast_assoc(:user)
    |> cast_assoc(:connection)
    |> validate_required([:label])
    |> validate_length(:label, min: 2, max: 160)
    |> validate_email_or_username(opts)
    |> add_label_hash()
  end

  @doc """
  Confirms the user_connection by setting `confirmed_at`.
  """
  def confirm_changeset(user_conn) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user_conn, confirmed_at: now)
  end

  defp add_label_hash(changeset) do
    if Map.get(changeset.changes, :label) do
      changeset
      |> put_change(:label_hash, String.downcase(get_field(changeset, :label)))
    else
      changeset
    end
  end

  defp validate_email_or_username(changeset, opts) do
    case opts[:selector] do
      "" ->
        changeset
        |> add_error(:email, "can't both be blank")
        |> add_error(:usernamem, "can't both be blank")

      "email" ->
        changeset
        |> validate_email(opts)

      "username" ->
        changeset
        |> validate_username(opts)

      _rest ->
        changeset
    end
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_add_recipient_id_by_email(opts)
  end

  defp validate_username(changeset, opts) do
    changeset
    |> validate_required([:username])
    |> validate_length(:username, min: 2, max: 160)
    |> maybe_add_recipient_id_by_username(opts)
  end

  defp maybe_add_recipient_id_by_email(changeset, opts) do
    email = get_change(changeset, :email, "")

    if recipient = Accounts.get_user_by_email(email) do
      changeset
      |> put_change(:user_id, recipient.id)
      |> encrypt_connection_key(recipient, opts)
    else
      changeset
    end
  end

  defp maybe_add_recipient_id_by_username(changeset, opts) do
    username = get_change(changeset, :username, "")

    if recipient = Accounts.get_user_by_username(username) do
      changeset
      |> put_change(:user_id, recipient.id)
      |> encrypt_connection_key(recipient, opts)
    else
      changeset
    end
  end

  defp encrypt_connection_key(changeset, recipient, opts) do
    conn_key = get_change(changeset, :key)

    if opts[:user] && opts[:key] do
      # We first decrypt the current_user's conn_key
      # and then encrypt it with the recipient's public key.
      d_conn_key = Encrypted.Users.Utils.decrypt_user_attrs_key(opts[:user].conn_key, opts[:user], opts[:key])

      changeset
      |> put_change(
        :key,
        Encrypted.Utils.encrypt_message_for_user_with_pk(d_conn_key, %{
          public: recipient.key_pair["public"]
        })
      )
    else
      changeset
    end
  end
end
