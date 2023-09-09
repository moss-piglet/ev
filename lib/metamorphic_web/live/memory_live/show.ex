defmodule MetamorphicWeb.MemoryLive.Show do
  use MetamorphicWeb, :live_view

  alias Metamorphic.Accounts
  alias Metamorphic.Encrypted
  alias Metamorphic.Extensions.MemoryProcessor
  alias Metamorphic.Memories

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Accounts.private_subscribe(socket.assigns.current_user)
      Memories.private_subscribe(socket.assigns.current_user)
      Memories.connections_subscribe(socket.assigns.current_user)
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    memory = Memories.get_memory!(id)

    {:noreply,
     socket
     |> assign(:color, get_uconn_color_for_shared_item(memory, socket.assigns.current_user) || :purple)
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:memory, memory)}
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
  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  @doc """
  Deletes the avatar in ETS and object storage.
  """
  @impl true
  def handle_event("delete", %{"id" => id, "url" => url}, socket) do
    memories_bucket = Encrypted.Session.memories_bucket()
    memory = Memories.get_memory!(id)
    user = socket.assigns.current_user

    if memory.user_id == user.id do
      conn = Accounts.get_connection_from_item(memory, user)
      with {:ok, memory} <- Memories.delete_memory(memory, user: user),
        true <- MemoryProcessor.delete_ets_memory("user:#{memory.user_id}-memory:#{memory.id}-key:#{conn.id}") do
          # Handle deleting the object storage avatar async.
          with {:ok, _resp} <- ex_aws_delete_request(memories_bucket, url) do
            info = "Your memory has been deleted successfully."
            notify_self({:deleted, memory})

            socket =
              socket
              |> put_flash(:success, info)

            {:noreply, push_navigate(socket, to: ~p"/memories")}
          else
            _rest -> ex_aws_delete_request(memories_bucket, url)
          end
      else
        _rest ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  defp page_title(:show), do: "Show Memory"
  defp page_title(:edit), do: "Edit Memory"

  defp ex_aws_delete_request(memories_bucket, url) do
    ExAws.S3.delete_object(memories_bucket, url)
    |> ExAws.request()
  end

  defp notify_self(msg), do: send(self(), {__MODULE__, msg})
end
