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
    field :request_username, Encrypted.Binary
    field :request_email, Encrypted.Binary
    field :request_username_hash, Encrypted.HMAC
    field :request_email_hash, Encrypted.HMAC

    belongs_to :connection, Connection
    belongs_to :user, User

    timestamps()
  end

  def changeset(uconn, attrs \\ %{}, opts \\ []) do
    uconn
    |> cast(attrs, [
      :key,
      :photos?,
      :zen?,
      :label,
      :email,
      :username,
      :request_email,
      :request_username,
      :user_id,
      :connection_id
    ])
    |> cast_assoc(:user)
    |> cast_assoc(:connection)
    |> validate_required([:label])
    |> validate_length(:label, min: 2, max: 160)
    |> add_label_hash()
    |> validate_request_email_and_username(opts)
    |> validate_email_or_username(opts)
    |> unsafe_validate_unique([:connection_id, :user_id], Metamorphic.Repo.Local)
    |> unique_constraint([:connection_id, :user_id])
  end

  @doc """
  Confirms the user_connection by setting `confirmed_at`.
  """
  def confirm_changeset(uconn) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(uconn, confirmed_at: now)
  end

  defp validate_email_or_username(changeset, opts) do
    case opts[:selector] do
      "" ->
        changeset
        |> add_error(:email, "can't both be blank")
        |> add_error(:username, "can't both be blank")

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

  defp validate_request_email_and_username(changeset, opts) do
    changeset
    |> add_request_email_hash(opts)
    |> add_request_username_hash(opts)
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

    if recipient = Accounts.get_user_by_email(opts[:user], email) do
      changeset
      |> put_change(:user_id, recipient.id)
      |> encrypt_connection_key_and_data(recipient, opts)
    else
      changeset
      |> add_error(:email, "invalid or does not exist")
    end
  end

  defp maybe_add_recipient_id_by_username(changeset, opts) do
    username = get_change(changeset, :username, "")

    if recipient = Accounts.get_user_by_username(opts[:user], username) do
      changeset
      |> put_change(:user_id, recipient.id)
      |> encrypt_connection_key_and_data(recipient, opts)
    else
      changeset
      |> add_error(:username, "invalid or does not exist")
    end
  end

  defp add_label_hash(changeset) do
    if Map.get(changeset.changes, :label) do
      changeset
      |> put_change(:label_hash, String.downcase(get_field(changeset, :label)))
    else
      changeset
    end
  end

  defp add_request_email_hash(changeset, opts) do
    if opts[:user] && opts[:key] do
      d_email =
        Encrypted.Users.Utils.decrypt_user_data(
          opts[:user].email,
          opts[:user],
          opts[:key]
        )

      changeset
      |> put_change(:request_email_hash, String.downcase(d_email))
    else
      changeset
    end
  end

  defp add_request_username_hash(changeset, opts) do
    if opts[:user] && opts[:key] do
      d_username =
        Encrypted.Users.Utils.decrypt_user_data(
          opts[:user].username,
          opts[:user],
          opts[:key]
        )

      changeset
      |> put_change(:request_username_hash, String.downcase(d_username))
    else
      changeset
    end
  end

  defp encrypt_connection_key_and_data(changeset, recipient, opts) do
    if opts[:user] && opts[:key] do
      # We first decrypt the current_user's conn_key
      # and then encrypt it with the recipient's public key.
      d_conn_key =
        Encrypted.Users.Utils.decrypt_user_attrs_key(
          opts[:user].conn_key,
          opts[:user],
          opts[:key]
        )

      d_req_username =
        Encrypted.Users.Utils.decrypt_user_data(
          opts[:user].username,
          opts[:user],
          opts[:key]
        )

      d_req_email =
        Encrypted.Users.Utils.decrypt_user_data(
          opts[:user].email,
          opts[:user],
          opts[:key]
        )

      changeset
      |> put_change(
        :key,
        Encrypted.Utils.encrypt_message_for_user_with_pk(d_conn_key, %{
          public: recipient.key_pair["public"]
        })
      )
      |> put_change(
        :request_username,
        Encrypted.Utils.encrypt(%{key: d_conn_key, payload: d_req_username})
      )
      |> put_change(
        :request_email,
        Encrypted.Utils.encrypt(%{key: d_conn_key, payload: d_req_email})
      )
    else
      changeset
    end
  end
end
