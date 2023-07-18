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
end
