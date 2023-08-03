defmodule MetamorphicWeb.UserConnectionLive.ArrivalComponent do
  @moduledoc false
  use MetamorphicWeb, :live_component

  alias Metamorphic.Accounts

  alias MetamorphicWeb.UserConnectionLive.Components

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle :if={@action == :greet}>Greet your new connections! Click their avatar to accept or privately decline their request.</:subtitle>
      </.header>

      <Components.cards
        id="arrivals_greeter"
        stream={@stream}
        current_user={@user}
        key={@key}
        page={@page}
        end_of_timeline?={@end_of_timeline?}
        card_click={fn _uconn -> nil end}
      />
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(page: 1, per_page: 10)
     |> assign(assigns)}
  end
end
