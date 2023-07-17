defmodule Metamorphic.Encrypted.Integer do
  @moduledoc """
  Cloak.Ecto module for implementing encryption
  functionality for integer fields.
  """
  use Cloak.Ecto.Integer, vault: Metamorphic.Vault
end
