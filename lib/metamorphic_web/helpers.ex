defmodule MetamorphicWeb.Helpers do
  @moduledoc false

  alias Metamorphic.Encrypted

  def decr(_payload, _user, _key)

  def decr(payload, user, key) do
    Encrypted.Users.Utils.decrypt_user_data(
      payload,
      user,
      key
    )
  end

  ## Edit

  def can_edit?(id, item) when is_struct(item) do
    if id == item.user_id, do: true
  end

  def can_edit?(id, item) when is_map(item) do
    if id == item["user_id"], do: true
  end
end
