defmodule MetamorphicWeb.UserProfileLive do
  use MetamorphicWeb, :live_view

  alias Metamorphic.Accounts

  alias Metamorphic.Memories

  alias MetamorphicWeb.MemoryLive.Components

  @impl true
  def mount(%{"slug" => slug} = _params, _session, socket) do
    if connected?(socket) do
      if socket.assigns.current_user do
        Accounts.private_subscribe(socket.assigns.current_user)
        Memories.subscribe()
      else
        Accounts.subscribe()
        Memories.subscribe()
      end
    end

    user = Accounts.get_user_from_profile_slug!(slug)

    {:ok,
      socket
      |> assign(:slug, slug)
      |> assign(:page_title, "Profile")
      |> assign(:user, user)
      |> assign(page: 1, per_page: 20)
      |> paginate_memories(1)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:uconn_visibility_updated, uconn}, socket) do
    user = socket.assigns.user
    current_user = socket.assigns.current_user

    cond do
      is_nil(current_user) ->
        {:noreply, socket}

      uconn.user_id == current_user.id && user.id != current_user.id ->
        {:noreply, socket |> paginate_memories(socket.assigns.page, true)}

      uconn.reverse_user_id == current_user.id && user.id != current_user.id ->
        {:noreply, socket |> paginate_memories(socket.assigns.page, true)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_updated, uconn}, socket) do
    current_user = socket.assigns.current_user
    user = socket.assigns.user

    cond do
      is_nil(current_user) ->
        {:noreply, socket |> assign(:user, Accounts.get_user_with_preloads(user.id)) |> paginate_memories(socket.assigns.page, true) |> redirect(to: "/profile/#{socket.assigns.slug}")}

      uconn.user_id == current_user.id && user.id != current_user.id ->
        {:noreply, socket |> assign(:user, Accounts.get_user_with_preloads(uconn.reverse_user_id)) |> paginate_memories(socket.assigns.page, true) |> redirect(to: "/profile/#{socket.assigns.slug}")}

      uconn.reverse_user_id == current_user.id && user.id != current_user.id ->
        {:noreply, socket |> assign(:user, Accounts.get_user_with_preloads(uconn.user_id)) |> paginate_memories(socket.assigns.page, true) |> redirect(to: "/profile/#{socket.assigns.slug}")}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:memory_created, memory}, socket) do
    if memory.visibility != :public do
      {:noreply, stream_insert(socket, :memories, memory, at: 0)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:memory_deleted, memory}, socket) do
    {:noreply, stream_delete(socket, :memories, memory)}
  end

  @impl true
  def handle_info({:uconn_deleted, uconn}, socket) do
    current_user = socket.assigns.current_user

    cond do
      uconn.user_id == current_user.id || uconn.reverse_user_id == current_user.id ->
        {:noreply, paginate_memories(socket, socket.assigns.page, true)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_confirmed, uconn}, socket) do
    current_user = socket.assigns.current_user

    cond do
      uconn.user_id == current_user.id || uconn.reverse_user_id == current_user.id ->
        {:noreply, paginate_memories(socket, socket.assigns.page, true)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_username_updated, uconn}, socket) do
    current_user = socket.assigns.current_user

    cond do
      uconn.user_id == current_user.id || uconn.reverse_user_id == current_user.id ->
        {:noreply, paginate_memories(socket, socket.assigns.page, true)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_name_updated, uconn}, socket) do
    current_user = socket.assigns.current_user

    cond do
      uconn.user_id == current_user.id || uconn.reverse_user_id == current_user.id ->
        {:noreply, paginate_memories(socket, socket.assigns.page, true)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_email_updated, uconn}, socket) do
    current_user = socket.assigns.current_user

    cond do
      uconn.user_id == current_user.id || uconn.reverse_user_id == current_user.id ->
        {:noreply, paginate_memories(socket, socket.assigns.page, true)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_avatar_updated, uconn}, socket) do
    current_user = socket.assigns.current_user

    cond do
      uconn.user_id == current_user.id || uconn.reverse_user_id == current_user.id ->
        {:noreply, paginate_memories(socket, socket.assigns.page, true)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:user_profile_deleted, _conn}, socket) do
    {:noreply, redirect(socket, to: "/profile/#{socket.assigns.slug}")}
  end

  @impl true
  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("next-page", _, socket) do
    {:noreply, paginate_memories(socket, socket.assigns.page + 1)}
  end

  @impl true
  def handle_event("prev-page", %{"_overran" => true}, socket) do
    {:noreply, paginate_memories(socket, 1)}
  end

  @impl true
  def handle_event("prev-page", _, socket) do
    if socket.assigns.page > 1 do
      {:noreply, paginate_memories(socket, socket.assigns.page - 1)}
    else
      {:noreply, socket}
    end
  end

  defp paginate_memories(socket, new_page, reset \\ false) when new_page >= 1 do
    %{per_page: per_page, page: cur_page} = socket.assigns
    user = socket.assigns.user
    memories = Memories.list_public_memories(user, offset: (new_page - 1) * per_page, limit: per_page)

    {memories, at, limit} =
      if new_page >= cur_page do
        {memories, -1, per_page * 3 * -1}
      else
        {Enum.reverse(memories), 0, per_page * 3}
      end

    case memories do
      [] ->
        socket
        |> assign(end_of_memories?: at == -1)
        |> stream(:memories, [])

      [_ | _] = memories ->
        socket
        |> assign(end_of_memories?: false)
        |> assign(page: new_page)
        |> stream(:memories, memories, at: at, limit: limit, reset: reset)
    end
  end
end
