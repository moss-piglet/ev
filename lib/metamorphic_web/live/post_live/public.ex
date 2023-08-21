defmodule MetamorphicWeb.PostLive.Public do
  use MetamorphicWeb, :live_view

  alias Metamorphic.Accounts
  alias Metamorphic.Timeline
  alias Metamorphic.Timeline.Post

  alias MetamorphicWeb.PostLive.Components

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Accounts.subscribe()
      Timeline.subscribe()
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
    |> assign(:page_title, "Public Timeline")
    |> assign(:post, nil)
  end

  @impl true
  def handle_info({MetamorphicWeb.PostLive.FormComponent, {:saved, post}}, socket) do
    {:noreply, stream_insert(socket, :posts, post)}
  end

  @impl true
  def handle_info({MetamorphicWeb.PostLive.FormComponent, _message}, socket) do
    {:noreply, socket}
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
    {:noreply, stream_delete(socket, :posts, post)}
  end

  @impl true
  def handle_info({:public_uconn_deleted, _uconn}, socket) do
    {:noreply, paginate_posts(socket, socket.assigns.page, true)}
  end

  @impl true
  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("top", _, socket) do
    {:noreply, socket |> put_flash(:success, "You reached the top") |> paginate_posts(1)}
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

    if post.user_id == socket.assigns.current_user.id do
      {:ok, _} = Timeline.delete_post(post, user: socket.assigns.current_user)

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
        Timeline.update_post_repost(post, %{
          reposts_list: List.insert_at(post.reposts_list, 0, user.id)
        })

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

      Timeline.create_repost(repost_params, user: user, key: key)

      socket = put_flash(socket, :success, "Post reposted successfully.")
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp paginate_posts(socket, new_page, reset \\ false) when new_page >= 1 do
    %{per_page: per_page, page: cur_page} = socket.assigns
    posts = Timeline.list_public_posts(offset: (new_page - 1) * per_page, limit: per_page)

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
end
