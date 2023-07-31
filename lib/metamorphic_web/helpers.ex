defmodule MetamorphicWeb.Helpers do
  @moduledoc false

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
    if post && post.visibility == :public do
      decr_public_post(payload, post_key)
    else
      Encrypted.Users.Utils.decrypt_user_item(payload, user, post_key, key)
    end
  end

  def decr_public_post(payload, post_key) do
    Encrypted.Users.Utils.decrypt_public_post(payload, post_key)
  end

  # This is currently not used. Consider removing.
  def decr_post_key(payload_key, post, user, key) do
    case post.visibility do
      :public -> Encrypted.Users.Utils.decrypt_public_post_key(payload_key)
      :private -> Encrypted.Users.Utils.decrypt_user_attrs_key(payload_key, user, key)
      :connections -> :error
    end
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
    Encrypted.Users.Utils.decrypt_user_attrs_key(payload_key, user, key)
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
end
