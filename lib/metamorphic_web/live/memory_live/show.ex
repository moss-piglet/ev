defmodule MetamorphicWeb.MemoryLive.Show do
  use MetamorphicWeb, :live_view

  alias Metamorphic.Accounts
  alias Metamorphic.Encrypted
  alias Metamorphic.Extensions.MemoryProcessor
  alias Metamorphic.Memories
  alias Metamorphic.Memories.Remark
  alias MetamorphicWeb.MemoryLive.Components

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Accounts.private_subscribe(socket.assigns.current_user)
      Memories.private_subscribe(socket.assigns.current_user)
      Memories.connections_subscribe(socket.assigns.current_user)
    end

    {:ok, socket |> assign(page: 1, per_page: 20)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    memory = Memories.get_memory!(id)

    socket =
      socket
      |> assign(:memory, memory)
      |> assign(
        :color,
        get_uconn_color_for_shared_item(memory, socket.assigns.current_user) || :purple
      )
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:memory, memory)
      |> assign(:user, memory.user)
      |> assign(:excited_count, Memories.get_remarks_excited_count(memory))
      |> assign(:loved_count, Memories.get_remarks_loved_count(memory))
      |> assign(:happy_count, Memories.get_remarks_happy_count(memory))
      |> assign(:sad_count, Memories.get_remarks_sad_count(memory))
      |> assign(:thumbsy_count, Memories.get_remarks_thumbsy_count(memory))
      |> assign(:remark, %Remark{})

    {:noreply,
     socket
     |> paginate_remarks(socket.assigns.page)}
  end

  @impl true
  def handle_info({MetamorphicWeb.MemoryLive.FormComponent, {:saved, memory}}, socket) do
    if memory.id == socket.assigns.memory.id do
      {:noreply, assign(socket, :memory, memory)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({MetamorphicWeb.MemoryLive.Show, {:deleted, memory}}, socket) do
    if memory.user_id == socket.assigns.current_user.id do
      {:noreply, stream_delete(socket, :memories, memory)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:memory_updated, memory}, socket) do
    if memory.id == socket.assigns.memory.id do
      {:noreply, assign(socket, :memory, memory)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:memory_deleted, memory}, socket) do
    if socket.assigns.current_user.id == memory.user_id do
      {:noreply, socket}
    else
      {:noreply, push_redirect(socket, to: ~p"/memories")}
    end
  end

  @impl true
  def handle_info({:uconn_deleted, uconn}, socket) do
    user = socket.assigns.current_user

    cond do
      uconn.user_id == user.id || uconn.reverse_user_id == user.id ->
        {:noreply, push_redirect(socket, to: ~p"/memories/#{socket.assigns.memory}")}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_confirmed, uconn}, socket) do
    user = socket.assigns.current_user

    cond do
      uconn.user_id == user.id || uconn.reverse_user_id == user.id ->
        {:noreply, push_redirect(socket, to: ~p"/memories/#{socket.assigns.memory}")}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_username_updated, uconn}, socket) do
    user = socket.assigns.current_user

    cond do
      uconn.user_id == user.id || uconn.reverse_user_id == user.id ->
        {:noreply, push_redirect(socket, to: ~p"/memories/#{socket.assigns.memory}")}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_name_updated, uconn}, socket) do
    user = socket.assigns.current_user

    cond do
      uconn.user_id == user.id || uconn.reverse_user_id == user.id ->
        {:noreply, push_redirect(socket, to: ~p"/memories/#{socket.assigns.memory}")}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_visibility_updated, uconn}, socket) do
    user = socket.assigns.current_user

    cond do
      uconn.user_id == user.id || uconn.reverse_user_id == user.id ->
        {:noreply, push_redirect(socket, to: ~p"/memories/#{socket.assigns.memory}")}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_email_updated, uconn}, socket) do
    user = socket.assigns.current_user

    cond do
      uconn.user_id == user.id || uconn.reverse_user_id == user.id ->
        {:noreply, push_redirect(socket, to: ~p"/memories/#{socket.assigns.memory}")}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_avatar_updated, uconn}, socket) do
    user = socket.assigns.current_user

    cond do
      uconn.user_id == user.id || uconn.reverse_user_id == user.id ->
        {:noreply, push_redirect(socket, to: ~p"/memories/#{socket.assigns.memory}")}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:remark_created, remark}, socket) do
    user = socket.assigns.current_user
    uconn = get_uconn_for_shared_item(remark, user)
    socket = update_remark_reaction_count(socket, remark)

    cond do
      uconn.user_id == user.id || uconn.reverse_user_id == user.id ->
        {:noreply, socket |> stream_insert(:remarks, remark, at: 0)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(
        {_ref, {:ok, :memory_deleted_from_storj, info}},
        socket
      ) do
    socket = put_flash(socket, :success, info)
    {:noreply, redirect(socket, to: "/memories")}
  end

  @impl true
  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("fav", %{"id" => id}, socket) do
    memory = Memories.get_memory!(id)
    user = socket.assigns.current_user

    if user.id not in memory.favs_list do
      {:ok, memory} = Memories.inc_favs(memory)

      Memories.update_memory_fav(
        memory,
        %{favs_list: List.insert_at(memory.favs_list, 0, user.id)},
        user: user
      )

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("unfav", %{"id" => id}, socket) do
    memory = Memories.get_memory!(id)
    user = socket.assigns.current_user

    if user.id in memory.favs_list do
      {:ok, memory} = Memories.decr_favs(memory)

      Memories.update_memory_fav(memory, %{favs_list: List.delete(memory.favs_list, user.id)},
        user: user
      )

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @doc """
  Deletes the memory in ETS and object storage.
  """
  @impl true
  def handle_event("delete", %{"id" => id, "url" => url}, socket) do
    memories_bucket = Encrypted.Session.memories_bucket()
    memory = Memories.get_memory!(id)
    user = socket.assigns.current_user

    if memory.user_id == user.id do
      case Memories.delete_memory(memory, user: user) do
        {:ok, conn, memory} ->
          MemoryProcessor.delete_ets_memory(
            "user:#{memory.user_id}-memory:#{memory.id}-key:#{conn.id}"
          )

          # Handle deleting the object storage memory async.
          make_async_aws_requests(memories_bucket, url)

          info =
            "Your memory has been deleted successfully. Sit back and relax while we delete your memory from the private cloud."

          notify_self({:deleted, memory})

          socket =
            socket
            |> put_flash(:success, info)

          {:noreply, push_redirect(socket, to: ~p"/memories")}

        _rest ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("next-page", _, socket) do
    {:noreply, paginate_remarks(socket, socket.assigns.page + 1)}
  end

  @impl true
  def handle_event("prev-page", %{"_overran" => true}, socket) do
    {:noreply, paginate_remarks(socket, 1)}
  end

  @impl true
  def handle_event("prev-page", _, socket) do
    if socket.assigns.page > 1 do
      {:noreply, paginate_remarks(socket, socket.assigns.page - 1)}
    else
      {:noreply, socket}
    end
  end

  defp page_title(:show), do: "Show Memory"
  defp page_title(:edit), do: "Edit Memory"

  defp update_remark_reaction_count(socket, remark) do
    socket =
      cond do
        remark.mood == :excited ->
          assign(socket, :excited_count, socket.assigns.excited_count + 1)

        remark.mood == :loved ->
          assign(socket, :loved_count, socket.assigns.loved_count + 1)

        remark.mood == :happy ->
          assign(socket, :happy_count, socket.assigns.happy_count + 1)

        remark.mood == :sad ->
          assign(socket, :sad_count, socket.assigns.sad_count + 1)

        remark.mood == :thumbsy ->
          assign(socket, :thumbsy_count, socket.assigns.thumbsy_count + 1)

        true ->
          socket
      end

    socket
  end

  defp make_async_aws_requests(memories_bucket, url) do
    Task.Supervisor.async_nolink(Metamorphic.StorjTask, fn ->
      with {:ok, _resp} <- ex_aws_delete_request(memories_bucket, url) do
        {:ok, :memory_deleted_from_storj, "Memory successfully deleted from the private cloud."}
      else
        _rest ->
          ex_aws_delete_request(memories_bucket, url)
          {:error, :make_async_aws_requests}
      end
    end)
  end

  defp ex_aws_delete_request(memories_bucket, url) do
    ExAws.S3.delete_object(memories_bucket, url)
    |> ExAws.request()
  end

  defp notify_self(msg), do: send(self(), {__MODULE__, msg})

  defp paginate_remarks(socket, new_page, reset \\ false) when new_page >= 1 do
    %{per_page: per_page, page: cur_page} = socket.assigns
    memory = socket.assigns.memory
    remarks = Memories.list_remarks(memory, offset: (new_page - 1) * per_page, limit: per_page)

    {remarks, at, limit} =
      if new_page >= cur_page do
        {remarks, -1, per_page * 3 * -1}
      else
        {Enum.reverse(remarks), 0, per_page * 3}
      end

    case remarks do
      [] ->
        socket
        |> assign(end_of_remarks?: at == -1)
        |> stream(:remarks, [])

      [_ | _] = remarks ->
        socket
        |> assign(end_of_remarks?: false)
        |> assign(page: new_page)
        |> stream(:remarks, remarks, at: at, limit: limit, reset: reset)
    end
  end
end
