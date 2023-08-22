defmodule MetamorphicWeb.UserProfileLive do
  use MetamorphicWeb, :live_view

  alias Metamorphic.Accounts

  def render(%{live_action: :show} = assigns) do
    ~H"""
    <.header>
      <div :if={@user.id != @current_user.id}>
        User <%= decr_uconn(
          get_uconn_for_users(@user, @current_user).connection.username,
          @current_user,
          get_uconn_for_users(@user, @current_user).key,
          @key
        ) %>
      </div>
      <div :if={@user.id == @current_user.id}>
        User <%= decr(@user.username, @current_user, @key) %>
      </div>
      <:subtitle :if={@current_user.id == @user.id}>
        This is your user profile on <%= now() %>.
      </:subtitle>
      <:subtitle :if={@current_user.id != @user.id}>
        This is their user profile on <%= now() %>.
      </:subtitle>
    </.header>

    <.list>
      <:item title="Username"><%= decr(@user.username, @current_user, @key) %></:item>
      <:item title="Email"><%= decr(@user.email, @current_user, @key) %></:item>
      <:item title="Joined"><%= time_ago(@user.inserted_at) %></:item>
    </.list>

    <.back navigate={~p"/users/dash"}>Back to dash</.back>
    """
  end

  def mount(%{"id" => id} = _params, _session, socket) do
    # if connected?(socket), do: Timeline.subscribe()
    socket =
      socket
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:user, Accounts.get_user!(id))

    {:ok, socket}
  end

  defp page_title(:show), do: "Show User"
end
