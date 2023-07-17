defmodule Metamorphic.Encrypted.IntegerList do
  @moduledoc """
  Cloak.Ecto module for implementing encryption
  functionality for integer-list fields.
  """
  use Cloak.Ecto.IntegerList, vault: Metamorphic.Vault
end
