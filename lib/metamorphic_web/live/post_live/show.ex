defmodule MetamorphicWeb.PostLive.Show do
  use MetamorphicWeb, :live_view

  alias Metamorphic.Timeline

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Timeline.private_subscribe(socket.assigns.current_user)
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:post, Timeline.get_post!(id))}
  end

  @impl true
  def handle_info({MetamorphicWeb.PostLive.FormComponent, {:saved, post}}, socket) do
    if post.id == socket.assigns.post.id do
      {:noreply, assign(socket, :post, post)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:post_updated, post}, socket) do
    if post.id == socket.assigns.post.id do
      {:noreply, assign(socket, :post, post)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_deleted, uconn}, socket) do
    user = socket.assigns.current_user

    cond do
      uconn.user_id == user.id || uconn.reverse_user_id == user.id ->
        {:noreply, push_redirect(socket, to: ~p"/posts/#{socket.assigns.post}")}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_confirmed, uconn}, socket) do
    user = socket.assigns.current_user

    cond do
      uconn.user_id == user.id || uconn.reverse_user_id == user.id ->
        {:noreply, push_redirect(socket, to: ~p"/posts/#{socket.assigns.post}")}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_username_updated, uconn}, socket) do
    user = socket.assigns.current_user

    cond do
      uconn.user_id == user.id || uconn.reverse_user_id == user.id ->
        {:noreply, push_redirect(socket, to: ~p"/posts/#{socket.assigns.post}")}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_name_updated, uconn}, socket) do
    user = socket.assigns.current_user

    cond do
      uconn.user_id == user.id || uconn.reverse_user_id == user.id ->
        {:noreply, push_redirect(socket, to: ~p"/posts/#{socket.assigns.post}")}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_visibility_updated, uconn}, socket) do
    user = socket.assigns.current_user

    cond do
      uconn.user_id == user.id || uconn.reverse_user_id == user.id ->
        {:noreply, push_redirect(socket, to: ~p"/posts/#{socket.assigns.post}")}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_email_updated, uconn}, socket) do
    user = socket.assigns.current_user

    cond do
      uconn.user_id == user.id || uconn.reverse_user_id == user.id ->
        {:noreply, push_redirect(socket, to: ~p"/posts/#{socket.assigns.post}")}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_avatar_updated, uconn}, socket) do
    user = socket.assigns.current_user

    cond do
      uconn.user_id == user.id || uconn.reverse_user_id == user.id ->
        {:noreply, push_redirect(socket, to: ~p"/posts/#{socket.assigns.post}")}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  defp page_title(:show), do: "Show Post"
  defp page_title(:edit), do: "Edit Post"
end
