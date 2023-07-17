defmodule Metamorphic.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  import ZXCVBN

  alias Metamorphic.Encrypted

  schema "users" do
    field :email, Encrypted.Binary
    field :email_hash, Encrypted.HMAC
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :is_admin, :boolean, default: false
    field :is_suspended, :boolean, default: false
    field :is_deleted, :boolean, default: false
    field :is_onboarded, :boolean, default: false
    field :key_hash, Encrypted.Binary
    field :key_pair, {:map, Encrypted.Binary}
    field :name, Encrypted.Binary
    field :name_hash, Encrypted.HMAC
    field :username, Encrypted.Binary
    field :username_hash, Encrypted.HMAC
    field :user_key, Encrypted.Binary, redact: true
    field :visibility, Ecto.Enum, values: [:public, :private, :relations]
    field :confirmed_at, :naive_datetime

    timestamps()
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_email(opts)
    |> validate_password(opts)
  end

  defp validate_email(changeset, opts) do
    # use the current_user_session_key to encrypt email change data
    # for making updates to the email when a user is signed into their
    # settings page
    if opts[:current_user_session_key] && !is_nil(get_field(changeset, :email)) do
      encrypted_email =
        Encrypted.Users.Utils.encrypt_user_data(
          get_field(changeset, :email),
          opts[:user].user_key,
          opts[:user],
          opts[:current_user_session_key]
        )

      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/,
        message: "must have the @ sign and no spaces"
      )
      |> validate_length(:email, max: 160)
      |> add_email_hash()
      |> maybe_validate_unique_email_hash(opts)
      |> put_change(:email, encrypted_email)
    else
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/,
        message: "must have the @ sign and no spaces"
      )
      |> validate_length(:email, max: 160)
      |> add_email_hash()
      |> maybe_validate_unique_email_hash(opts)
    end
  end

  defp add_email_hash(changeset) do
    if Map.has_key?(changeset.changes, :email) do
      changeset
      |> put_change(:email_hash, String.downcase(get_field(changeset, :email)))
    else
      changeset
    end
  end

  defp maybe_validate_unique_email_hash(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email_hash, Metamorphic.Repo)
      |> unique_constraint(:email_hash)
    else
      changeset
    end
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    |> check_zxcvbn_strength()
    |> maybe_hash_password(opts)
  end

  defp check_zxcvbn_strength(changeset) do
    password = get_change(changeset, :password)

    if password != nil do
      password_strength =
        zxcvbn(password, [
          get_change(changeset, :name),
          get_change(changeset, :username),
          get_change(changeset, :email)
        ])

      offline_fast_hashing =
        Map.get(password_strength.crack_times_display, :offline_fast_hashing_1e10_per_second)

      offline_slow_hashing =
        Map.get(password_strength.crack_times_display, :offline_slow_hashing_1e4_per_second)

      cond do
        password_strength.score === 4 && offline_fast_hashing === "centuries" ->
          changeset

        password_strength.score <= 4 ->
          add_error(
            changeset,
            :password,
            "may be cracked in #{offline_fast_hashing} to #{offline_slow_hashing}"
          )
      end
    else
      changeset
    end
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Argon2.hash_pwd_salt(password, salt_len: 128))
      |> put_key_hash_and_key_pair_and_encrypt_user_data()
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp put_key_hash_and_key_pair_and_encrypt_user_data(
         %Ecto.Changeset{
           valid?: true,
           changes: %{
             email: email,
             password: password
           }
         } = changeset
       ) do
    user_key = Encrypted.Utils.generate_key()
    user_attributes_key = Encrypted.Utils.generate_key()

    %{key_hash: key_hash} = Encrypted.Utils.generate_key_hash(password, user_key)
    %{public: public_key, private: private_key} = Encrypted.Utils.generate_key_pairs()

    encrypted_email = Encrypted.Utils.encrypt(%{key: user_attributes_key, payload: email})
    encrypted_private_key = Encrypted.Utils.encrypt(%{key: user_key, payload: private_key})

    encrypted_user_attributes_key =
      Encrypted.Utils.encrypt_message_for_user_with_pk(user_attributes_key, %{
        public: public_key
      })

    changeset
    |> put_change(:email, encrypted_email)
    |> put_change(:key_hash, key_hash)
    |> put_change(:key_pair, %{public: public_key, private: encrypted_private_key})
    |> put_change(:user_key, encrypted_user_attributes_key)
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Argon2.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Metamorphic.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Argon2.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Argon2.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
