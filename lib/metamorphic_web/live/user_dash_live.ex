defmodule MetamorphicWeb.UserDashLive do
  use MetamorphicWeb, :live_view

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Welcome home
      <:subtitle>This is your account dashboard.</:subtitle>
      <:actions :if={!@current_user.confirmed_at}>
        <.button type="button" class="bg-brand-500" phx-click={JS.patch(~p"/users/confirm")}>
          Confirm my account
        </.button>
      </:actions>
    </.header>

    <.flash_group flash={@flash} />
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
