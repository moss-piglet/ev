defmodule MetamorphicWeb.UserProfileLive do
  use MetamorphicWeb, :live_view

  alias Metamorphic.Accounts

  def render(%{live_action: :show} = assigns) do
    ~H"""
    <div :if={
      @user.visibility == :public || @user.visibility == :connections || @user.id == @current_user.id
    }>
      <.header :if={@user.id != @current_user.id}>
        <div class="flex items-center gap-x-6">
          <.avatar
            :if={@user.id != @current_user.id}
            src={get_user_avatar(get_uconn_for_users(@user, @current_user), @key)}
            alt=""
            class="h-16 w-16 flex-none rounded-full ring-1 ring-gray-900/10"
          />
          <h1>
            <div class="text-sm leading-6 text-gray-500">
              Profile
              <span class="text-gray-700">
                <%= decr_uconn(
                  get_uconn_for_users(@user, @current_user).label,
                  @current_user,
                  get_uconn_for_users(@user, @current_user).key,
                  @key
                ) %>
              </span>
            </div>
            <div class="mt-1 text-base font-semibold leading-6 text-gray-900">
              <%= decr_uconn(
                get_uconn_for_users(@user, @current_user).connection.email,
                @current_user,
                get_uconn_for_users(@user, @current_user).key,
                @key
              ) %>
            </div>
          </h1>
        </div>

        <:subtitle>
          This is their user profile on <.local_time_now id={@user.id} />.
        </:subtitle>
      </.header>

      <.header :if={@user.id == @current_user.id}>
        <div class="flex items-center gap-x-6">
          <.avatar
            :if={@user.id == @current_user.id}
            src={get_user_avatar(@user, @key)}
            alt=""
            class="h-16 w-16 flex-none rounded-full ring-1 ring-gray-900/10"
          />
          <h1>
            <div class="text-sm leading-6 text-gray-500">
              Profile
              <span class="text-gray-700"><%= decr(@user.username, @current_user, @key) %></span>
            </div>
            <div class="mt-1 text-base font-semibold leading-6 text-gray-900">
              <%= decr(@user.email, @current_user, @key) %>
            </div>
          </h1>
        </div>

        <:subtitle>
          This is your user profile on <.local_time_now id={@user.id} />.
        </:subtitle>
      </.header>

      <.list :if={@user.id != @current_user.id}>
        <:item title="Username">
          <%= decr_uconn(
            get_uconn_for_users(@user, @current_user).connection.username,
            @current_user,
            get_uconn_for_users(@user, @current_user).key,
            @key
          ) %>
        </:item>
        <:item title="Email">
          <%= decr_uconn(
            get_uconn_for_users(@user, @current_user).connection.email,
            @current_user,
            get_uconn_for_users(@user, @current_user).key,
            @key
          ) %>
        </:item>
        <:item title="Joined"><.local_time_ago id={@user.id} at={@user.inserted_at} /></:item>
      </.list>

      <.list :if={@user.id == @current_user.id}>
        <:item title="Username"><%= decr(@user.username, @current_user, @key) %></:item>
        <:item title="Email"><%= decr(@user.email, @current_user, @key) %></:item>
        <:item title="Joined"><.local_time_ago id={@user.id} at={@user.inserted_at} /></:item>
      </.list>

      <.back navigate={~p"/users/dash"}>Back to dash</.back>
    </div>
    """
  end

  def mount(%{"id" => id} = _params, _session, socket) do
    if connected?(socket), do: Accounts.private_subscribe(socket.assigns.current_user)

    socket =
      socket
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:user, Accounts.get_user!(id))

    {:ok, socket}
  end

  def handle_info({:uconn_visibility_updated, uconn}, socket) do
    user = socket.assigns.current_user

    cond do
      uconn.user_id == user.id ->
        {:noreply, assign(socket, :user, Accounts.get_user!(uconn.reverse_user_id))}

      uconn.reverse_user_id == user.id ->
        {:noreply, assign(socket, :user, Accounts.get_user!(uconn.user_id))}

      true ->
        {:noreply, socket}
    end
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  defp page_title(:show), do: "Show User"
end
