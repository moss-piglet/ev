defmodule Metamorphic.Encrypted.Users.Utils do
  @moduledoc false
  alias Metamorphic.Encrypted

  ## Notes
  #
  # We need the `encrypted_payload_user_key` argument
  # to allow for using these functions with both
  # users and relationships.

  ## Decryption

  @doc """
  Decrypts payload for the current user's data
  with their current_user_session_key.

  Updated for Metamorphic.
  """
  def decrypt_user_data(
        payload,
        current_user,
        current_user_session_key
      ) do
    with session_key <- current_user_session_key,
         {:ok, d_private_key} <- decrypt_private_key(current_user, session_key),
         {:ok, d_user_key} <-
           decrypt_user_key(current_user, current_user.user_key, d_private_key),
         {:ok, d_payload} <- decrypt_payload(d_user_key, payload) do
      d_payload
    else
      {:error_private_key, message} -> message
      {:error_user_key, message} -> message
      {:error_payload, message} -> message
      rest -> rest
    end
  end

  @doc """
  Decrypts a user item, where item is a
  struct (e.g. %Post{}, %Userconnection).
  """
  def decrypt_user_item(payload, user, e_item_key, key) do
    with {:ok, d_item_key} <- decrypt_user_attrs_key(e_item_key, user, key),
         {:ok, d_payload} <- decrypt_payload(d_item_key, payload) do
      d_payload
    else
      {:error_user_key, message} -> message
      {:error_payload, message} -> message
      rest -> rest
    end
  end

  def decrypt_public_post(payload, e_post_key) do
    with {:ok, d_post_key} <-
           Encrypted.Utils.decrypt_message_for_user(e_post_key, %{
             public: Encrypted.Session.server_public_key(),
             private: Encrypted.Session.server_private_key()
           }),
         {:ok, d_payload} <- decrypt_payload(d_post_key, payload) do
      d_payload
    else
      {:error_user_key, message} -> message
      rest -> rest
    end
  end

  def decrypt_public_post_key(payload) do
    with {:ok, d_post_key} <-
           Encrypted.Utils.decrypt_message_for_user(payload, %{
             public: Encrypted.Session.server_public_key(),
             private: Encrypted.Session.server_private_key()
           }) do
      d_post_key
    else
      {:error_user_key, message} -> message
      rest -> rest
    end
  end

  # Used to decrypt user_key, aka the
  # user_attributes_key. This is the key that
  # is used to encrypt/decrypt data.
  #
  # It is encrypted by the user's public_key.
  #
  # Used for sharing or changing the password.
  #
  # Returns `{:ok, key}`
  def decrypt_user_attrs_key(
        user_key,
        current_user,
        current_user_session_key
      ) do
    with session_key <- current_user_session_key,
         {:ok, d_private_key} <- decrypt_private_key(current_user, session_key),
         {:ok, d_user_key} <-
           decrypt_user_key(current_user, user_key, d_private_key) do
      {:ok, d_user_key}
    else
      {:error_private_key, message} -> message
      {:error_user_key, message} -> message
      rest -> rest
    end
  end

  @doc """
  Used to decrypt the `user_key` and the
  user's `private_key.
  """
  def decrypt_user_keys(
        user_key,
        current_user,
        current_user_session_key
      ) do
    with session_key <- current_user_session_key,
         {:ok, d_private_key} <- decrypt_private_key(current_user, session_key),
         {:ok, d_user_key} <-
           decrypt_user_key(current_user, user_key, d_private_key) do
      %{user_key: d_user_key, private_key: d_private_key}
    else
      {:error_private_key, message} -> message
      {:error_user_key, message} -> message
      rest -> rest
    end
  end

  ## Encryption

  @doc """
  Encrypts the current user's data
  with their current_user_session_key and
  public key.
  """
  def encrypt_user_data(
        payload,
        current_user,
        current_user_session_key
      ) do
    with session_key <- current_user_session_key,
         {:ok, d_private_key} <- decrypt_private_key(current_user, session_key),
         {:ok, d_user_key} <-
           decrypt_user_key(current_user, current_user.user_key, d_private_key),
         e_payload <- encrypt_payload(d_user_key, payload) do
      e_payload
    else
      {:error_private_key, message} -> message
      {:error_user_key, message} -> message
      rest -> rest
    end
  end

  ## Private

  @spec decrypt_private_key(struct, binary) :: tuple
  defp decrypt_private_key(user, session_key) do
    private_key = user.key_pair["private"] || user.key_pair.private

    case Encrypted.Utils.decrypt(%{key: session_key, payload: private_key}) do
      {:ok, d_private_key} ->
        {:ok, d_private_key}

      {:error, message} ->
        {:error_private_key, message}
    end
  end

  @spec decrypt_user_key(struct, binary, binary) :: tuple
  defp decrypt_user_key(user, encrypted_payload_user_key, d_private_key) do
    public_key = user.key_pair["public"] || user.key_pair.public

    case Encrypted.Utils.decrypt_message_for_user(encrypted_payload_user_key, %{
           public: public_key,
           private: d_private_key
         }) do
      {:ok, d_user_key} ->
        {:ok, d_user_key}

      {:error, message} ->
        {:error_user_key, message}
    end
  end

  @spec decrypt_payload(binary, binary) :: tuple
  defp decrypt_payload(d_user_key, payload) do
    case Encrypted.Utils.decrypt(%{key: d_user_key, payload: payload}) do
      {:ok, d_payload} ->
        {:ok, d_payload}

      {:error_user_key, message} ->
        message

      {:error, message} ->
        {:error_payload, message}

      rest ->
        rest
    end
  end

  @spec encrypt_payload(binary, binary) :: binary
  defp encrypt_payload(d_user_key, payload) do
    Encrypted.Utils.encrypt(%{key: d_user_key, payload: payload})
  end
end
