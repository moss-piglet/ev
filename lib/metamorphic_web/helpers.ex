defmodule MetamorphicWeb.Helpers do
  @moduledoc false

  alias Metamorphic.Accounts
  alias Metamorphic.Accounts.{Connection, User, UserConnection}
  alias Metamorphic.Encrypted
  alias Metamorphic.Extensions.AvatarProcessor
  alias Metamorphic.Cldr.DateTime.Relative
  alias Metamorphic.Timeline.Post

  ## Encryption

  def decr(_payload, _user, _key)

  def decr(payload, user, key) when is_binary(payload) do
    Encrypted.Users.Utils.decrypt_user_data(
      payload,
      user,
      key
    )
  end

  def decr(_payload, _user, _key), do: nil

  def decr_avatar(payload, user, e_item_key, key) do
    case Encrypted.Users.Utils.decrypt_user_item(
           payload,
           user,
           e_item_key,
           key
         ) do
      {:error, message} ->
        message

      :failed_verification ->
        "failed_verification"

      payload ->
        payload
    end
  end

  def decr_post(payload, user, post_key, key, post \\ nil) do
    cond do
      post && post.visibility == :public ->
        decr_public_post(payload, post_key)

      post && post.visibility == :private ->
        Encrypted.Users.Utils.decrypt_user_item(payload, user, post_key, key)

      post && post.visibility == :connections && post.user_id == user.id ->
        Encrypted.Users.Utils.decrypt_user_item(payload, user, post_key, key)

      post && post.visibility == :connections && post.user_id != user.id ->
        uconn = get_uconn_for_shared_post(post, user)
        Encrypted.Users.Utils.decrypt_user_item(payload, user, uconn.key, key)

      true ->
        "did not work"
    end
  end

  def decr_public_post(payload, post_key) do
    Encrypted.Users.Utils.decrypt_public_post(payload, post_key)
  end

  def decr_uconn(payload, user, uconn_key, key) do
    Encrypted.Users.Utils.decrypt_user_item(
      payload,
      user,
      uconn_key,
      key
    )
  end

  def decr_attrs_key(payload_key, user, key) do
    {:ok, d_attrs_key} = Encrypted.Users.Utils.decrypt_user_attrs_key(payload_key, user, key)
    d_attrs_key
  end

  ## General

  def now() do
    Date.utc_today()
  end

  def time_ago(naive_dt, tz \\ "Etc/UTC") do
    {:ok, dt} = DateTime.from_naive(naive_dt, tz)
    {:ok, string} = Relative.to_string(dt)
    string
  end

  def can_edit?(user, item) when is_struct(item) do
    if user.id == item.user_id, do: true
  end

  def can_edit?(user, item) when is_map(item) do
    if user.id == item["user_id"], do: true
  end

  ## Posts

  def can_fav?(user, post) do
    if user.id not in post.favs_list do
      true
    else
      false
    end
  end

  def can_repost?(user, post) do
    if post.user_id != user.id && user.id not in post.reposts_list do
      true
    else
      false
    end
  end

  def get_post_connection(post, current_user) do
    cond do
      post.visibility == :public ->
        post

      true ->
        Accounts.get_connection_from_post(post, current_user)
    end
  end

  def get_post_key(post) do
    Enum.at(post.user_posts, 0).key
  end

  def get_post_key(post, current_user) do
    cond do
      post.visibility == :connections && current_user.id != post.user_id ->
        uconn = get_uconn_for_shared_post(post, current_user)
        uconn.key

      post.visibility == :private ->
        current_user.conn_key

      true ->
        Enum.at(post.user_posts, 0).key
    end
  end

  def get_shared_post_identity_atom(post, user) do
    cond do
      post.visibility == :connections && post.user_id == user.id ->
        :self

      post.visibility == :connections && post.user_id != user.id &&
          user_in_post_connections(post, user) ->
        :connection

      true ->
        :invalid
    end
  end

  def get_shared_post_label(post, user, key) do
    cond do
      %UserConnection{} = uconn = get_uconn_for_shared_post(post, user) ->
        Encrypted.Users.Utils.decrypt_user_item(
          uconn.label,
          user,
          uconn.key,
          key
        )

      true ->
        "nil"
    end
  end

  # User is the current user and should be
  # different from the user_id of the post,
  # but the two users should have
  # user connections together.
  def get_uconn_for_shared_post(post, user) do
    Accounts.get_user_connection_from_shared_post(post, user)
  end

  # If the user (current_user) is the same as the
  # post.user_id, then we return the user and not
  # the uconn.
  def get_uconn_avatar_for_shared_post(post, user) do
    if post.user_id == user.id do
      user
    else
      Accounts.get_user_connection_from_shared_post(post, user)
    end
  end

  defp user_in_post_connections(post, user) do
    uconns = Accounts.get_all_user_connections_from_shared_post(post, user)
    Enum.any?(uconns, fn uconn -> uconn.user_id == user.id end)
  end

  def is_users_shared_post?(post, user) do
    cond do
      post.visibility == :connections && post.user_id == user.id ->
        true

      true ->
        false
    end
  end

  ## Avatars

  def get_user_avatar(user, key, post \\ nil, current_user \\ nil)

  def get_user_avatar(nil, _key, _post, _current_user), do: "nil"

  def get_user_avatar(%User{} = user, key, _post, _current_user) do
    cond do
      is_nil(user.avatar_url) ->
        ""

      not is_nil(avatar_binary = AvatarProcessor.get_ets_avatar(user.connection.id)) ->
        image =
          decr_avatar(
            avatar_binary,
            user,
            user.conn_key,
            key
          )
          |> Base.encode64()

        "data:image/jpg;base64," <> image

      is_nil(_avatar_binary = AvatarProcessor.get_ets_avatar(user.connection.id)) ->
        avatars_bucket = Encrypted.Session.avatars_bucket()

        with {:ok, %{body: obj}} <-
               ExAws.S3.get_object(
                 avatars_bucket,
                 decr_avatar(
                   user.connection.avatar_url,
                   user,
                   user.conn_key,
                   key
                 )
               )
               |> ExAws.request(),
             decrypted_obj <-
               decr_avatar(
                 obj,
                 user,
                 user.conn_key,
                 key
               ) do
          # Put the encrypted avatar binary in ets.
          Task.async(fn ->
            AvatarProcessor.put_ets_avatar(user.connection.id, obj)
          end)

          image = decrypted_obj |> Base.encode64()
          path = "data:image/jpg;base64," <> image
          path
        else
          {:error, _rest} ->
            "error"
        end
    end
  end

  def get_user_avatar(%UserConnection{} = uconn, key, post, current_user) do
    case post do
      nil ->
        # Handle decrypting the avatar for the user connection.
        cond do
          not is_nil(avatar_binary = AvatarProcessor.get_ets_avatar(uconn.connection.id)) ->
            image = decrypt_user_or_uconn_binary(avatar_binary, uconn, nil, key, nil)
            "data:image/jpg;base64," <> image

          is_nil(_avatar_binary = AvatarProcessor.get_ets_avatar(uconn.connection.id)) ->
            avatars_bucket = Encrypted.Session.avatars_bucket()

            with {:ok, %{body: obj}} <-
                   ExAws.S3.get_object(
                     avatars_bucket,
                     decr_avatar(
                       uconn.connection.avatar_url,
                       uconn.user,
                       uconn.key,
                       key
                     )
                   )
                   |> ExAws.request(),
                 decrypted_obj <-
                   decr_avatar(
                     obj,
                     uconn.user,
                     uconn.key,
                     key
                   ) do
              # Put the encrypted avatar binary in ets.
              Task.async(fn ->
                AvatarProcessor.put_ets_avatar(uconn.connection.id, obj)
              end)

              image = decrypted_obj |> Base.encode64()
              path = "data:image/jpg;base64," <> image
              path
            else
              {:error, _rest} ->
                "error"
            end
        end

      %Post{} = post ->
        # we handle decrypting the avatar for the user connection and
        # possibly the current user if the post is their own.
        cond do
          is_nil(uconn.connection.avatar_url) ->
            ""

          not is_nil(avatar_binary = AvatarProcessor.get_ets_avatar(uconn.connection.id)) ->
            image = decrypt_user_or_uconn_binary(avatar_binary, uconn, post, key, current_user)
            "data:image/jpg;base64," <> image

          is_nil(_avatar_binary = AvatarProcessor.get_ets_avatar(uconn.connection.id)) && not is_nil(current_user) && current_user != post.user_id ->
            avatars_bucket = Encrypted.Session.avatars_bucket()

            with {:ok, %{body: obj}} <-
                   ExAws.S3.get_object(
                     avatars_bucket,
                     decr_avatar(
                       uconn.connection.avatar_url,
                       uconn.user,
                       uconn.key,
                       key
                     )
                   )
                   |> ExAws.request(),
                 decrypted_obj <-
                   decr_avatar(
                     obj,
                     uconn.user,
                     uconn.key,
                     key
                   ) do
              # Put the encrypted avatar binary in ets.
              Task.async(fn ->
                AvatarProcessor.put_ets_avatar(uconn.connection.id, obj)
              end)

              image = decrypted_obj |> Base.encode64()
              path = "data:image/jpg;base64," <> image
              path
            else
              {:error, _rest} ->
                "error"
            end

          is_nil(_avatar_binary = AvatarProcessor.get_ets_avatar(uconn.connection.id)) && not is_nil(current_user) && current_user.id == post.user_id ->
            avatars_bucket = Encrypted.Session.avatars_bucket()

            with {:ok, %{body: obj}} <-
                    ExAws.S3.get_object(
                      avatars_bucket,
                      decr_avatar(
                        uconn.connection.avatar_url,
                        current_user,
                        uconn.key,
                        key
                      )
                    )
                    |> ExAws.request(),
                  decrypted_obj <-
                    decr_avatar(
                      obj,
                      current_user,
                      uconn.key,
                      key
                    ) do
              # Put the encrypted avatar binary in ets.
              Task.async(fn ->
                AvatarProcessor.put_ets_avatar(uconn.connection.id, obj)
              end)

              image = decrypted_obj |> Base.encode64()
              path = "data:image/jpg;base64," <> image
              path
            else
              {:error, _rest} ->
                "error"
            end
        end
    end
  end

  defp decrypt_user_or_uconn_binary(avatar_binary, uconn, post, key, current_user) do
    cond do
      is_nil(current_user) ->
        decr_avatar(
          avatar_binary,
          uconn.user,
          uconn.key,
          key
        )
        |> Base.encode64()

      not is_nil(current_user) && post.user_id != current_user.id ->
        decr_avatar(
          avatar_binary,
          uconn.user,
          uconn.key,
          key
        )
        |> Base.encode64()

        not is_nil(current_user) && post.user_id == current_user.id ->
          decr_avatar(
            avatar_binary,
            current_user,
            current_user.conn_key,
            key
          )
          |> Base.encode64()
    end
  end

  ## Errors

  def error_to_string(:too_large),
    do: "Gulp! File too large (max 10 MB)."

  def error_to_string(:too_many_files),
    do: "Whoa, too many files."

  def error_to_string(:not_accepted),
    do: "Sorry, that's not an acceptable file type."
end
