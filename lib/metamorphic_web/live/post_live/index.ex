defmodule MetamorphicWeb.PostLive.Index do
  use MetamorphicWeb, :live_view

  alias Metamorphic.Timeline
  alias Metamorphic.Timeline.Post

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Timeline.subscribe()
    {:ok, stream(socket, :posts, Timeline.list_posts())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Post")
    |> assign(:post, Timeline.get_post!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Post")
    |> assign(:post, %Post{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Posts")
    |> assign(:post, nil)
  end

  @impl true
  def handle_info({MetamorphicWeb.PostLive.FormComponent, {:saved, post}}, socket) do
    {:noreply, stream_insert(socket, :posts, post)}
  end

  @impl true
  def handle_info({:post_created, post}, socket) do
    {:noreply, stream_insert(socket, :posts, post, at: 0)}
  end

  @impl true
  def handle_info({:post_reposted, post}, socket) do
    {:noreply, stream_insert(socket, :posts, post, at: 0)}
  end

  @impl true
  def handle_info({:post_updated, post}, socket) do
    {:noreply, stream_insert(socket, :posts, post, at: -1)}
  end

  @impl true
  def handle_info({:post_deleted, post}, socket) do
    if post.user_id == socket.assigns.current_user.id do
      {:noreply, stream_delete(socket, :posts, post)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Timeline.get_post!(id)

    if post.user_id == socket.assigns.current_user.id do
      {:ok, _} = Timeline.delete_post(post)

      {:noreply, stream_delete(socket, :posts, post)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("fav", %{"id" => id}, socket) do
    post = Timeline.get_post!(id)
    user = socket.assigns.current_user
    if user.id not in post.favs_list do
      {:ok, post} = Timeline.inc_favs(post)
      Timeline.update_post(post, %{favs_list: List.insert_at(post.favs_list, 0, user.id)})
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("unfav", %{"id" => id}, socket) do
    post = Timeline.get_post!(id)
    user = socket.assigns.current_user
    if user.id in post.favs_list do
      {:ok, post} = Timeline.decr_favs(post)
      Timeline.update_post(post, %{favs_list: List.delete(post.favs_list, user.id)})
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("repost", %{"id" => id, "body" => body, "username" => username}, socket) do
    post = Timeline.get_post!(id)
    user = socket.assigns.current_user

    if post.user_id != user.id && user.id not in post.reposts_list do
      {:ok, post} = Timeline.inc_reposts(post)
      {:ok, post} = Timeline.update_post(post, %{reposts_list: List.insert_at(post.reposts_list, 0, user.id)})

      repost_params = %{
        body: body,
        username: username,
        favs_list: post.favs_list,
        reposts_list: post.reposts_list,
        favs_count: post.favs_count,
        reposts_count: post.reposts_count,
        user_id: user.id,
        original_post_id: post.id,
        repost: true
      }

      Timeline.repost(repost_params)

      socket = put_flash(socket, :info, "Post reposted successfully.")
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp can_fav?(id, post) do
    if id not in post.favs_list do
      true
    else
      false
    end
  end

  defp repost?(id, post) do
    if post.user_id != id && id not in post.reposts_list do
      true
    else
      false
    end
  end
end
