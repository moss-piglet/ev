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
     |> stream(:uconns, Accounts.list_user_connections(user))
     |> stream(:arrivals, Accounts.list_user_arrival_connections(user))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info({MetamorphicWeb.UserConnectionLive.FormComponent, {:saved, uconn}}, socket) do
    if uconn.user_id == socket.assigns.current_user.id do
      {:noreply, stream_insert(socket, :uconns, uconn)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_created, uconn}, socket) do
    # WIP
    IO.inspect(uconn, label: "UCONN HANDLE INFO")

    if uconn.user_id == socket.assigns.current_user.id do
      {:noreply, stream_insert(socket, :uconns, uconn)}
    else
      {:noreply, socket}
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Connection")
    |> assign(:uconn, %UserConnection{})
  end

  defp apply_action(socket, :screen, _params) do
    user = socket.assigns.current_user

    socket
    |> assign(:page_title, "Connection Arrivals")
    |> stream(:arrivals, Accounts.list_user_arrival_connections(user))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Your Connections")
    |> assign(:uconn, nil)
  end
end
