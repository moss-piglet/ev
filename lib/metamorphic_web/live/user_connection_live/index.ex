defmodule MetamorphicWeb.UserConnectionLive.Index do
  use MetamorphicWeb, :live_view

  alias Metamorphic.Accounts
  alias Metamorphic.Accounts.UserConnection

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if connected?(socket) do
      Accounts.private_subscribe(user)
    end

    {:ok,
     socket
     |> assign(page: 1, per_page: 10)
     |> stream(:uconns, Accounts.list_user_connections(user))
     |> paginate_arrivals(1)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info({MetamorphicWeb.UserConnectionLive.FormComponent, {:saved, uconn}}, socket) do
    cond do
      uconn.user_id == socket.assigns.current_user.id && uconn.confirmed_at ->
        {:noreply, stream_insert(socket, :uconns, uconn)}

      uconn.user_id == socket.assigns.current_user.id ->
        {:noreply, stream_insert(socket, :arrivals, uconn)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_created, uconn}, socket) do
    cond do
      uconn.user_id == socket.assigns.current_user.id && uconn.confirmed_at ->
        {:noreply, stream_insert(socket, :uconns, uconn)}

      uconn.user_id == socket.assigns.current_user.id ->
        {:noreply, stream_insert(socket, :arrivals, uconn)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("accept_uconn", params, socket) do
    IO.inspect params, label: "SAVE PARAMS"
    {:noreply, socket}
  end

  @impl true
  def handle_event("decline_uconn", params, socket) do

    {:noreply, socket}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Connection")
    |> assign(:uconn, %UserConnection{})
  end

  defp apply_action(socket, :screen, _params) do
    user = socket.assigns.current_user

    socket
    |> assign(:page_title, "New Connection Arrivals")
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Your Connections")
    |> assign(:uconn, nil)
  end

  defp paginate_arrivals(socket, new_page) when new_page >= 1 do
    %{per_page: per_page, page: cur_page} = socket.assigns
    user = socket.assigns.current_user

    arrivals =
      Accounts.list_user_arrival_connections(user,
        offset: (new_page - 1) * per_page,
        limit: per_page
      )

    {arrivals, at, limit} =
      if new_page >= cur_page do
        {arrivals, -1, per_page * 3 * -1}
      else
        {Enum.reverse(arrivals), 0, per_page * 3}
      end

    case arrivals do
      [] ->
        socket
        |> assign(end_of_timeline?: at == -1)
        |> stream(:arrivals, [])

      [_ | _] = arrivals ->
        socket
        |> assign(end_of_timeline?: false)
        |> assign(page: if(arrivals == [], do: cur_page, else: new_page))
        |> stream(:arrivals, arrivals, at: at, limit: limit)
    end
  end
end
