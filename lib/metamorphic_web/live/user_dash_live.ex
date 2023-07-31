defmodule MetamorphicWeb.UserDashLive do
  use MetamorphicWeb, :live_view

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Welcome home
      <:subtitle>This is your account dashboard.</:subtitle>
      <:actions :if={!@current_user.confirmed_at}>
        <.button type="button" class="bg-brand-500" phx-click={JS.patch(~p"/users/confirm")}>
          Confirm my account
        </.button>
      </:actions>
    </.header>

    <div class="w-full sm:w-auto">
      <div class="mt-10 grid grid-cols-1 gap-x-6 gap-y-4 sm:grid-cols-4">
        <.link
          navigate={~p"/users/connections"}
          class="group relative rounded-2xl px-6 py-4 text-sm font-semibold leading-6 text-zinc-900 sm:py-6"
        >
          <span class="absolute inset-0 rounded-2xl bg-zinc-50 transition group-hover:bg-zinc-100 sm:group-hover:scale-105">
          </span>
          <span class="relative flex items-center gap-4 sm:flex-col">
            <.icon name="hero-user-group" class="h-6 w-6" /> Connections
          </span>
        </.link>
        <.link
          navigate={~p"/posts/"}
          class="group relative rounded-2xl px-6 py-4 text-sm font-semibold leading-6 text-zinc-900 sm:py-6"
        >
          <span class="absolute inset-0 rounded-2xl bg-zinc-50 transition group-hover:bg-zinc-100 sm:group-hover:scale-105">
          </span>
          <span class="relative flex items-center gap-4 sm:flex-col">
            <.icon name="hero-chat-bubble-oval-left-ellipsis" class="h-6 w-6" /> Timeline
          </span>
        </.link>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Dashboard")}
  end
end
