defmodule Metamorphic.Timeline do
  @moduledoc """
  The Timeline context.
  """

  import Ecto.Query, warn: false

  alias Metamorphic.Accounts
  alias Metamorphic.Accounts.{Connection, User, UserConnection}
  alias Metamorphic.Repo
  alias Metamorphic.Timeline.{Post, UserPost}

  @doc """
  Returns the list of non-public posts for
  the user.

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """
  def list_posts(user, opts) do
    limit = Keyword.fetch!(opts, :limit)
    offset = Keyword.get(opts, :offset, 0)

    post_list =
      from(p in Post,
        join: up in UserPost,
        on: up.post_id == p.id,
        where: p.visibility == :private and p.user_id == ^user.id,
        offset: ^offset,
        limit: ^limit,
        order_by: [desc: p.inserted_at],
        preload: [:user_posts]
      )
      |> Repo.all()

    posts =
      (post_list ++ list_own_connection_posts(user, opts) ++ list_connection_posts(user, opts))
      |> Enum.filter(fn post -> post.__meta__ != :deleted end)
      |> Enum.uniq_by(fn post -> post end)
      |> Enum.sort_by(fn p -> p.inserted_at end, :desc)

    posts
  end

  def list_own_connection_posts(user, opts) do
    limit = Keyword.fetch!(opts, :limit)
    offset = Keyword.get(opts, :offset, 0)

    from(p in Post,
      join: up in UserPost,
      on: up.post_id == p.id,
      join: u in User,
      on: up.user_id == u.id,
      where: p.visibility == :connections and p.user_id == ^user.id,
      offset: ^offset,
      limit: ^limit,
      order_by: [desc: p.inserted_at],
      preload: [:user_posts]
    )
    |> Repo.all()
  end

  def list_connection_posts(user, opts) do
    limit = Keyword.fetch!(opts, :limit)
    offset = Keyword.get(opts, :offset, 0)

    from(p in Post,
      join: up in UserPost,
      on: up.post_id == p.id,
      join: u in User,
      on: up.user_id == u.id,
      join: c in Connection,
      on: c.user_id == u.id,
      join: uc in UserConnection,
      on: uc.connection_id == c.id,
      where: uc.user_id == ^user.id or uc.reverse_user_id == ^user.id,
      where: not is_nil(uc.confirmed_at),
      where: p.visibility == :connections,
      offset: ^offset,
      limit: ^limit,
      order_by: [desc: p.inserted_at],
      preload: [:user_posts]
    )
    |> Repo.all()
  end

  def list_public_posts(opts) do
    limit = Keyword.fetch!(opts, :limit)
    offset = Keyword.get(opts, :offset, 0)

    from(p in Post,
      where: p.visibility == :public,
      offset: ^offset,
      limit: ^limit,
      order_by: [desc: p.inserted_at],
      preload: [:user_posts]
    )
    |> Repo.all()
    |> Enum.filter(fn post -> post.__meta__ != :deleted end)
    |> Enum.uniq_by(fn post -> post end)
  end

  def inc_favs(%Post{id: id}) do
    {1, [post]} =
      from(p in Post, where: p.id == ^id, select: p)
      |> Repo.update_all(inc: [favs_count: 1])

    {:ok, post |> Repo.preload([:user_posts])}
  end

  def decr_favs(%Post{id: id}) do
    {1, [post]} =
      from(p in Post, where: p.id == ^id, select: p)
      |> Repo.update_all(inc: [favs_count: -1])

    {:ok, post |> Repo.preload([:user_posts])}
  end

  def inc_reposts(%Post{id: id}) do
    {1, [post]} =
      from(p in Post, where: p.id == ^id, select: p)
      |> Repo.update_all(inc: [reposts_count: 1])

    {:ok, post |> Repo.preload([:user_posts])}
  end

  @doc """
  Gets a single post.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!(123)
      %Post{}

      iex> get_post!(456)
      ** (Ecto.NoResultsError)

  """
  def get_post!(id), do: Repo.get!(Post, id) |> Repo.preload([:user_posts])

  def get_post(id) do
    if :new == id || "new" == id do
      nil
    else
      Repo.get(Post, id) |> Repo.preload([:user_posts])
    end
  end

  def get_all_shared_posts(user_id) do
    Repo.all(
      from p in Post,
        where: p.user_id == ^user_id,
        where: p.visibility == :connections,
        preload: [:user_posts]
    )
  end

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(%{field: value})
      {:ok, %Post{}}

      iex> create_post(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(attrs \\ %{}, opts \\ []) do
    post = Post.changeset(%Post{}, attrs, opts)
    user = Accounts.get_user!(opts[:user].id)
    p_attrs = post.changes.user_post_map

    {:ok, %{insert_post: post, insert_user_post: _user_post_conn}} =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:insert_post, post)
      |> Ecto.Multi.insert(:insert_user_post, fn %{insert_post: post} ->
        UserPost.changeset(%UserPost{}, %{
          key: p_attrs.key
        })
        |> Ecto.Changeset.put_assoc(:post, post)
        |> Ecto.Changeset.put_assoc(:user, user)
      end)
      |> Repo.transaction_on_primary()

    conn = Accounts.get_connection_from_post(post, user)

    {:ok, conn, post |> Repo.preload([:user_posts])}
    |> broadcast(:post_created)
  end

  @doc """
  Creates a repost.

  ## Examples

      iex> create_repost(%{field: value})
      {:ok, %Post{}}

      iex> create_repost(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_repost(attrs \\ %{}, opts \\ []) do
    post = Post.repost_changeset(%Post{}, attrs, opts)
    user = Accounts.get_user!(opts[:user].id)
    p_attrs = post.changes.user_post_map

    {:ok, %{insert_post: post, insert_user_post: _user_post_conn}} =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:insert_post, post)
      |> Ecto.Multi.insert(:insert_user_post, fn %{insert_post: post} ->
        UserPost.changeset(%UserPost{}, %{
          key: p_attrs.key
        })
        |> Ecto.Changeset.put_assoc(:post, post)
        |> Ecto.Changeset.put_assoc(:user, user)
      end)
      |> Repo.transaction_on_primary()

    conn = Accounts.get_connection_from_post(post, user)

    {:ok, conn, post |> Repo.preload([:user_posts])}
    |> broadcast(:post_reposted)
  end

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post(%Post{} = post, attrs, opts \\ []) do
    post = Post.changeset(post, attrs, opts)
    user = Accounts.get_user!(opts[:user].id)
    p_attrs = post.changes.user_post_map

    {:ok, %{update_post: post, update_user_post: _user_post_conn}} =
      Ecto.Multi.new()
      |> Ecto.Multi.update(:update_post, post)
      |> Ecto.Multi.update(:update_user_post, fn %{update_post: post} ->
        UserPost.changeset(get_user_post(post), %{
          key: p_attrs.key
        })
        |> Ecto.Changeset.put_assoc(:post, post)
        |> Ecto.Changeset.put_assoc(:user, user)
      end)
      |> Repo.transaction_on_primary()

    conn = Accounts.get_connection_from_post(post, user)

    {:ok, conn, post |> Repo.preload([:user_posts])}
    |> broadcast(:post_updated)
  end

  def update_post_fav(%Post{} = post, attrs, opts \\ []) do
    user = Accounts.get_user!(opts[:user].id)

    {:ok, {:ok, post}} =
      Repo.transaction_on_primary(fn ->
        Post.changeset(post, attrs, opts)
        |> Repo.update()
      end)

    conn = Accounts.get_connection_from_post(post, user)

    {:ok, conn, post |> Repo.preload([:user_posts])}
    |> broadcast(:post_updated)
  end

  def update_post_repost(%Post{} = post, attrs, opts \\ []) do
    user = Accounts.get_user!(opts[:user].id)

    {:ok, {:ok, post}} =
      Repo.transaction_on_primary(fn ->
        Post.changeset(post, attrs, opts)
        |> Repo.update()
      end)

    conn = Accounts.get_connection_from_post(post, user)

    {:ok, conn, post |> Repo.preload([:user_posts])}
    |> broadcast(:post_updated)
  end

  defp get_user_post(post) do
    Enum.at(post.user_posts, 0)
    |> Repo.preload([:post, :user])
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(post)
      {:ok, %Post{}}

      iex> delete_post(post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post(%Post{} = post, opts \\ []) do
    user = Accounts.get_user!(opts[:user].id)

    conn = Accounts.get_connection_from_post(post, user)

    {:ok, {:ok, post}} =
      Repo.transaction_on_primary(fn ->
        Repo.delete(post)
      end)

    {:ok, conn, post}
    |> broadcast(:post_deleted)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(post)
      %Ecto.Changeset{data: %Post{}}

  """
  def change_post(%Post{} = post, attrs \\ %{}, opts \\ []) do
    Post.changeset(post, attrs, opts)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Metamorphic.PubSub, "posts")
  end

  def private_subscribe(user) do
    Phoenix.PubSub.subscribe(Metamorphic.PubSub, "priv_posts:#{user.id}")
  end

  def connections_subscribe(user) do
    Phoenix.PubSub.subscribe(Metamorphic.PubSub, "conn_posts:#{user.id}")
  end

  defp broadcast({:ok, conn, post}, event, _user_conn \\ %{}) do
    case post.visibility do
      :public -> public_broadcast({:ok, post}, event)
      :private -> private_broadcast({:ok, post}, event)
      :connections -> connections_broadcast({:ok, conn, post}, event)
    end
  end

  defp public_broadcast({:error, _reason} = error, _event), do: error

  defp public_broadcast({:ok, post}, event) do
    Phoenix.PubSub.broadcast(Metamorphic.PubSub, "posts", {event, post})
    {:ok, post}
  end

  defp private_broadcast({:error, _reason} = error, _event), do: error

  defp private_broadcast({:ok, post}, event) do
    Phoenix.PubSub.broadcast(Metamorphic.PubSub, "priv_posts:#{post.user_id}", {event, post})
    {:ok, post}
  end

  defp connections_broadcast({:error, _reason} = error, _event), do: error

  defp connections_broadcast({:ok, conn, post}, event) do
    Enum.each(conn.user_connections, fn uconn ->
      Phoenix.PubSub.broadcast(Metamorphic.PubSub, "conn_posts:#{uconn.user_id}", {event, post})

      Phoenix.PubSub.broadcast(
        Metamorphic.PubSub,
        "conn_posts:#{uconn.reverse_user_id}",
        {event, post}
      )
    end)

    {:ok, post}
  end
end
