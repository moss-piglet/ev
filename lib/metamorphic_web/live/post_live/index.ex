defmodule MetamorphicWeb.PostLive.Index do
  use MetamorphicWeb, :live_view

  alias Metamorphic.Accounts
  alias Metamorphic.Timeline
  alias Metamorphic.Timeline.Post

  alias MetamorphicWeb.PostLive.Components

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Accounts.private_subscribe(socket.assigns.current_user)
      Timeline.private_subscribe(socket.assigns.current_user)
      Timeline.connections_subscribe(socket.assigns.current_user)
    end

    {:ok,
     socket
     |> assign(page: 1, per_page: 20)
     |> paginate_posts(1)}
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
    |> assign(:page_title, "Your Timeline")
    |> assign(:post, nil)
  end

  @impl true
  def handle_info({MetamorphicWeb.PostLive.FormComponent, {:saved, post}}, socket) do
    if post.visibility != :public do
      {:noreply, stream_insert(socket, :posts, post, at: 0)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({MetamorphicWeb.PostLive.FormComponent, {:updated, post}}, socket) do
    if post.visibility != :public do
      {:noreply, stream_insert(socket, :posts, post, at: -1)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({MetamorphicWeb.PostLive.Index, {:deleted, post}}, socket) do
    if post.user_id == socket.assigns.current_user.id do
      {:noreply, stream_delete(socket, :posts, post)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({MetamorphicWeb.PostLive.Index, {:reposted, post}}, socket) do
    if post.user_id == socket.assigns.current_user.id do
      {:noreply, stream_insert(socket, :posts, post, at: 0)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:post_created, post}, socket) do
    if post.visibility != :public do
      {:noreply, stream_insert(socket, :posts, post, at: 0)}
    else
      {:noreply, socket}
    end
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
    {:noreply, stream_delete(socket, :posts, post)}
  end

  @impl true
  def handle_info({:uconn_deleted, uconn}, socket) do
    user = socket.assigns.current_user

    cond do
      uconn.user_id == user.id || uconn.reverse_user_id == user.id ->
        {:noreply, paginate_posts(socket, socket.assigns.page, true)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_deleted, uconn}, socket) do
    user = socket.assigns.current_user

    cond do
      uconn.user_id == user.id && uconn.confirmed_at ->
        {:noreply, paginate_posts(socket, socket.assigns.page, true)}

      uconn.reverse_user_id == user.id && uconn.confirmed_at ->
        {:noreply, paginate_posts(socket, socket.assigns.page, true)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:uconn_confirmed, uconn}, socket) do
    user = socket.assigns.current_user

    cond do
      uconn.user_id == user.id || uconn.reverse_user_id == user.id ->
        {:noreply, paginate_posts(socket, socket.assigns.page, true)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(_, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("top", _, socket) do
    {:noreply, socket |> put_flash(:info, "You reached the top") |> paginate_posts(1)}
  end

  @impl true
  def handle_event("next-page", _, socket) do
    {:noreply, paginate_posts(socket, socket.assigns.page + 1)}
  end

  @impl true
  def handle_event("prev-page", %{"_overran" => true}, socket) do
    {:noreply, paginate_posts(socket, 1)}
  end

  @impl true
  def handle_event("prev-page", _, socket) do
    if socket.assigns.page > 1 do
      {:noreply, paginate_posts(socket, socket.assigns.page - 1)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Timeline.get_post!(id)
    user = socket.assigns.current_user

    if post.user_id == user.id do
      {:ok, post} = Timeline.delete_post(post, user: user)
      notify_self({:deleted, post})

      socket = put_flash(socket, :info, "Post deleted successfully.")
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("fav", %{"id" => id}, socket) do
    post = Timeline.get_post!(id)
    user = socket.assigns.current_user

    if user.id not in post.favs_list do
      {:ok, post} = Timeline.inc_favs(post)

      Timeline.update_post_fav(post, %{favs_list: List.insert_at(post.favs_list, 0, user.id)},
        user: user
      )

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

      Timeline.update_post_fav(post, %{favs_list: List.delete(post.favs_list, user.id)},
        user: user
      )

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("repost", %{"id" => id, "body" => body, "username" => username}, socket) do
    post = Timeline.get_post!(id)
    user = socket.assigns.current_user
    key = socket.assigns.key

    if post.user_id != user.id && user.id not in post.reposts_list do
      {:ok, post} = Timeline.inc_reposts(post)

      {:ok, post} =
        Timeline.update_post_repost(
          post,
          %{
            reposts_list: List.insert_at(post.reposts_list, 0, user.id)
          },
          user: user
        )

      repost_params = %{
        body: body,
        username: username,
        favs_list: post.favs_list,
        reposts_list: post.reposts_list,
        favs_count: post.favs_count,
        reposts_count: post.reposts_count,
        user_id: user.id,
        original_post_id: post.id,
        visibility: post.visibility,
        repost: true
      }

      {:ok, post} = Timeline.create_repost(repost_params, user: user, key: key)
      notify_self({:reposted, post})

      socket = put_flash(socket, :info, "Post reposted successfully.")
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp paginate_posts(socket, new_page, reset \\ false) when new_page >= 1 do
    %{per_page: per_page, page: cur_page} = socket.assigns
    user = socket.assigns.current_user
    posts = Timeline.list_posts(user, offset: (new_page - 1) * per_page, limit: per_page)

    {posts, at, limit} =
      if new_page >= cur_page do
        {posts, -1, per_page * 3 * -1}
      else
        {Enum.reverse(posts), 0, per_page * 3}
      end

    case posts do
      [] ->
        socket
        |> assign(end_of_timeline?: at == -1)
        |> stream(:posts, [])

      [_ | _] = posts ->
        socket
        |> assign(end_of_timeline?: false)
        |> assign(page: if(posts == [], do: cur_page, else: new_page))
        |> stream(:posts, posts, at: at, limit: limit, reset: reset)
    end
  end

  defp notify_self(msg), do: send(self(), {__MODULE__, msg})
end
