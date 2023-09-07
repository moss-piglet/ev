defmodule Metamorphic.Memories do
  @moduledoc """
  The Memories context.
  """
  import Ecto.Query, warn: false

  alias Ecto.Adapters.SQL.Sandbox.Connection
  alias Metamorphic.Repo

  alias Metamorphic.Accounts
  alias Metamorphic.Memories.{Memory, UserMemory}

  @doc """
  Creates a memory.

  ## Examples

      iex> create_memory(%{field: value})
      {:ok, %Memory{}}

      iex> create_memory(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_memory(attrs \\ %{}, opts \\ []) do
    memory = Memory.changeset(%Memory{}, attrs, opts)
    user = Accounts.get_user!(opts[:user].id)
    p_attrs = memory.changes.user_memory_map

    {:ok, %{insert_memory: memory, insert_user_memory: _user_memory_conn}} =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:insert_memory, memory)
      |> Ecto.Multi.insert(:insert_user_memory, fn %{insert_memory: memory} ->
        UserMemory.changeset(%UserMemory{}, %{
          key: p_attrs.key
        })
        |> Ecto.Changeset.put_assoc(:memory, memory)
        |> Ecto.Changeset.put_assoc(:user, user)
      end)
      |> Repo.transaction_on_primary()

    conn = Accounts.get_connection_from_item(memory, user)

    {:ok, conn, memory |> Repo.preload([:user_memories])}
    |> broadcast(:memory_created)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Metamorphic.PubSub, "memories")
  end

  def private_subscribe(user) do
    Phoenix.PubSub.subscribe(Metamorphic.PubSub, "priv_memories:#{user.id}")
  end

  def connections_subscribe(user) do
    Phoenix.PubSub.subscribe(Metamorphic.PubSub, "conn_memories:#{user.id}")
  end

  defp broadcast({:ok, conn, memory}, event, _user_conn \\ %{}) do
    case memory.visibility do
      :public -> public_broadcast({:ok, memory}, event)
      :private -> private_broadcast({:ok, memory}, event)
      :connections -> connections_broadcast({:ok, conn, memory}, event)
    end
  end

  defp public_broadcast({:ok, memory}, event) do
    Phoenix.PubSub.broadcast(Metamorphic.PubSub, "memories", {event, memory})
    {:ok, memory}
  end

  defp private_broadcast({:ok, memory}, event) do
    Phoenix.PubSub.broadcast(
      Metamorphic.PubSub,
      "priv_memories:#{memory.user_id}",
      {event, memory}
    )

    {:ok, memory}
  end

  defp connections_broadcast({:ok, conn, memory}, event) do
    if Enum.empty?(memory.shared_users) do
      Enum.each(conn.user_connections, fn uconn ->
        Phoenix.PubSub.broadcast(
          Metamorphic.PubSub,
          "conn_memories:#{uconn.user_id}",
          {event, memory}
        )

        Phoenix.PubSub.broadcast(
          Metamorphic.PubSub,
          "conn_memories:#{uconn.reverse_user_id}",
          {event, memory}
        )
      end)

      {:ok, memory}
    else
      Enum.each(conn.user_connections, fn uconn ->
        Enum.each(memory.shared_users, fn shared_user ->
          cond do
            uconn.user_id == shared_user.user_id || uconn.reverse_user_id == shared_user.user_id ->
              Phoenix.PubSub.broadcast(
                Metamorphic.PubSub,
                "conn_memories:#{uconn.user_id}",
                {event, memory}
              )

              Phoenix.PubSub.broadcast(
                Metamorphic.PubSub,
                "conn_memories:#{uconn.reverse_user_id}",
                {event, memory}
              )

            true ->
              nil
          end
        end)
      end)

      {:ok, memory}
    end
  end
end
