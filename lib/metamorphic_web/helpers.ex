defmodule MetamorphicWeb.Helpers do
  @moduledoc false

  alias Metamorphic.Accounts
  alias Metamorphic.Accounts.UserConnection
  alias Metamorphic.Encrypted
  alias Metamorphic.Cldr.DateTime.Relative

  ## Encryption

  def decr(_payload, _user, _key)

  def decr(payload, user, key) do
    Encrypted.Users.Utils.decrypt_user_data(
      payload,
      user,
      key
    )
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

  def get_post_key(post) do
    Enum.at(post.user_posts, 0).key
  end

  def get_shared_post_identity_atom(post, user) do
    cond do
      post.visibility == :connections && post.user_id == user.id ->
        :self

      post.visibility == :connections && post.user_id != user.id && user_in_post_connections(post, user) ->
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
  defp get_uconn_for_shared_post(post, user) do
    Accounts.get_user_connection_from_shared_post(post, user)
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
end
