defmodule MetamorphicWeb.MemoryLive.Index do
  @moduledoc false
  use MetamorphicWeb, :live_view

  alias Metamorphic.Accounts

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Accounts.private_subscribe(socket.assigns.current_user)
    end

    {:ok, socket}
  end
end
