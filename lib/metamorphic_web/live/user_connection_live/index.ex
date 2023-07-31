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

    {:ok, stream(socket, :uconns, Accounts.list_user_connections(user))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info({MetamorphicWeb.UserConnectionLive.FormComponent, {:saved, uconn}}, socket) do
    {:noreply, stream_insert(socket, :uconns, uconn)}
  end

  @impl true
  def handle_info({:uconn_created, _uconn}, socket) do
    # WIP
    {:noreply, socket}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Connection")
    |> assign(:uconn, %UserConnection{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Your Connections")
    |> assign(:uconn, nil)
  end
end
