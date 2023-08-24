defmodule MetamorphicWeb.PostLive.PublicShow do
  use MetamorphicWeb, :live_view

  alias Metamorphic.Timeline
  import MetamorphicWeb.PostLive.Components, only: [local_time_full: 1]

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Timeline.subscribe()
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
  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  defp page_title(:show), do: "Public Show Post"
  defp page_title(:edit), do: "Edit Post"
end
