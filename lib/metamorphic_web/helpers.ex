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

  def decr_post(payload, user, post_key, key) do
    Encrypted.Users.Utils.decrypt_user_post(payload, user, post_key, key)
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

  def get_key(struct) do
    Enum.at(struct.user_posts, 0).key
  end
end
