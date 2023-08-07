defmodule MetamorphicWeb.UserConnectionLive.Index do
  alias Metamorphic.Encrypted
  use MetamorphicWeb, :live_view

  alias Metamorphic.Accounts
  alias Metamorphic.Accounts.UserConnection

  alias MetamorphicWeb.UserConnectionLive.Components

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if connected?(socket) do
      Accounts.private_subscribe(user)
    end

    {:ok,
     socket
     |> assign(page: 1, per_page: 10)}
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
  def handle_info({MetamorphicWeb.UserConnectionLive.Index, {:deleted, uconn}}, socket) do
    cond do
      uconn.user_id == socket.assigns.current_user.id && uconn.confirmed_at ->
        {:noreply, stream_delete(socket, :uconns, uconn)}

      uconn.user_id == socket.assigns.current_user.id ->
        {:noreply, stream_delete(socket, :arrivals, uconn)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(
        {MetamorphicWeb.UserConnectionLive.Index, {:uconn_confirmed, upd_uconn}},
        socket
      ) do
    cond do
      upd_uconn.user_id == socket.assigns.current_user.id && upd_uconn.confirmed_at ->
        {:noreply,
         socket
         |> stream_delete(:arrivals, upd_uconn)
         |> stream_insert(:connections, upd_uconn)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_deleted, uconn}, socket) do
    cond do
      uconn.user_id == socket.assigns.current_user.id && uconn.confirmed_at ->
        {:noreply, stream_delete(socket, :uconns, uconn)}

      uconn.user_id == socket.assigns.current_user.id ->
        {:noreply, stream_delete(socket, :arrivals, uconn)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_created, uconn}, socket) do
    cond do
      uconn.user_id == socket.assigns.current_user.id && uconn.confirmed_at ->
        {:noreply, stream_insert(socket, :uconns, uconn, at: 0)}

      uconn.user_id == socket.assigns.current_user.id ->
        {:noreply, stream_insert(socket, :arrivals, uconn, at: 0)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_confirmed, uconn}, socket) do
    cond do
      uconn.user_id == socket.assigns.current_user.id && uconn.confirmed_at ->
        {:noreply, stream_insert(socket, :connections, uconn, at: 0)}

      uconn.user_id == socket.assigns.current_user.id ->
        {:noreply, stream_insert(socket, :arrivals, uconn, at: 0)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_email_updated, uconn}, socket) do
    cond do
      uconn.user_id == socket.assigns.current_user.id && uconn.confirmed_at ->
        {:noreply, stream_insert(socket, :connections, uconn, at: -1)}

      uconn.user_id == socket.assigns.current_user.id ->
        {:noreply, stream_insert(socket, :arrivals, uconn, at: -1)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("accept_uconn", %{"id" => id}, socket) do
    uconn = Accounts.get_user_connection!(id)
    user = socket.assigns.current_user

    if uconn.user_id == user.id do
      key = socket.assigns.key
      attrs = build_accepting_uconn_attrs(uconn, user, key)

      case Accounts.confirm_user_connection(uconn, attrs, user: user, key: key, confirm: true) do
        {:ok, upd_uconn, _ins_uconn} ->
          notify_self({:uconn_confirmed, upd_uconn})

          {:noreply,
           socket
           |> put_flash(:info, "Connection accepted successfully.")}

        {:error, changeset} ->
          {:noreply, put_flash(socket, :error, changeset.msg)}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("decline_uconn", %{"id" => id}, socket) do
    uconn = Accounts.get_user_connection!(id)

    if uconn.user_id == socket.assigns.current_user.id do
      case Accounts.delete_user_connection(uconn) do
        {:ok, uconn} ->
          notify_self({:deleted, uconn})
          {:noreply, socket}

        {:error, changeset} ->
          {:noreply, put_flash(socket, :error, "#{changeset.message}")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("top", param, socket) do
    {:noreply, socket |> put_flash(:info, "You reached the top") |> paginate_arrivals(1)}
  end

  @impl true
  def handle_event("next-page-arrivals", _, socket) do
    {:noreply, paginate_arrivals(socket, socket.assigns.page + 1)}
  end

  @impl true
  def handle_event("prev-page-arrivals", %{"_overran" => true}, socket) do
    {:noreply, paginate_arrivals(socket, 1)}
  end

  @impl true
  def handle_event("prev-page-arrivals", _, socket) do
    if socket.assigns.page > 1 do
      {:noreply, paginate_arrivals(socket, socket.assigns.page - 1)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("next-page-connections", _, socket) do
    {:noreply, paginate_connections(socket, socket.assigns.page + 1)}
  end

  @impl true
  def handle_event("prev-page-connections", %{"_overran" => true}, socket) do
    {:noreply, paginate_connections(socket, 1)}
  end

  @impl true
  def handle_event("prev-page-connections", _, socket) do
    if socket.assigns.page > 1 do
      {:noreply, paginate_connections(socket, socket.assigns.page - 1)}
    else
      {:noreply, socket}
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Connection")
    |> assign(:uconn, %UserConnection{})
    |> paginate_arrivals(1)
    |> paginate_connections(1)
  end

  defp apply_action(socket, :greet, _params) do
    socket
    |> assign(:page_title, "Arrivals Greeter")
    |> paginate_arrivals(1)
    |> paginate_connections(1)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Your Connections")
    |> assign(:uconn, nil)
    |> paginate_arrivals(1)
    |> paginate_connections(1)
  end

  defp paginate_connections(socket, new_page) when new_page >= 1 do
    %{per_page: per_page, page: cur_page} = socket.assigns
    user = socket.assigns.current_user

    connections =
      Accounts.list_user_connections(user,
        offset: (new_page - 1) * per_page,
        limit: per_page
      )

    {connections, at, limit} =
      if new_page >= cur_page do
        {connections, -1, per_page * 3 * -1}
      else
        {Enum.reverse(connections), 0, per_page * 3}
      end

    case connections do
      [] ->
        socket
        |> assign(end_of_connections_timeline?: at == -1)
        |> assign(:connections_empty?, true)
        |> stream(:connections, [])

      [_ | _] = connections ->
        socket
        |> assign(end_of_connections_timeline?: false)
        |> assign(:connections_empty?, false)
        |> assign(page: if(connections == [], do: cur_page, else: new_page))
        |> stream(:connections, connections, at: at, limit: limit)
    end
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
        |> assign(end_of_arrivals_timeline?: at == -1)
        |> stream(:arrivals, [])

      [_ | _] = arrivals ->
        socket
        |> assign(end_of_arrivals_timeline?: false)
        |> assign(page: if(arrivals == [], do: cur_page, else: new_page))
        |> stream(:arrivals, arrivals, at: at, limit: limit)
    end
  end

  defp build_accepting_uconn_attrs(uconn, user, key) do
    d_req_email =
      Encrypted.Users.Utils.decrypt_user_item(uconn.request_email, user, uconn.key, key)

    d_req_username =
      Encrypted.Users.Utils.decrypt_user_item(uconn.request_username, user, uconn.key, key)

    d_label = Encrypted.Users.Utils.decrypt_user_item(uconn.label, user, uconn.key, key)
    req_user = Accounts.get_user_by_email(d_req_email)

    %{
      connection_id: user.connection.id,
      user_id: req_user.id,
      email: d_req_email,
      username: d_req_username,
      temp_label: d_label,
      request_username: d_req_username,
      request_email: d_req_email
    }
  end

  defp notify_self(msg), do: send(self(), {__MODULE__, msg})
end
