defmodule Metamorphic.Encrypted.Date do
  @moduledoc """
  Cloak.Ecto module for implementing encryption
  functionality for date fields.
  """
  use Cloak.Ecto.Date, vault: Metamorphic.Vault
end
