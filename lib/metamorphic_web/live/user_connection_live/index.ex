defmodule MetamorphicWeb.UserConnectionLive.Index do
  use MetamorphicWeb, :live_view

  alias Metamorphic.Accounts
  alias Metamorphic.Accounts.UserConnection

  @impl true
  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Connections
      <:subtitle>This is your connections dashboard.</:subtitle>
      <:actions :if={!@current_user.confirmed_at}>
        <.button type="button" class="bg-brand-500" phx-click={JS.patch(~p"/users/confirm")}>
          Confirm my account
        </.button>
      </:actions>
    </.header>

    <.flash_group flash={@flash} />

    <div class="w-full sm:w-auto">
      <div class="mt-10 grid grid-cols-2 gap-x-6 gap-y-4">
        <.link
          navigate={~p"/users/connections/new"}
          class="group relative rounded-2xl px-6 py-4 text-sm font-semibold leading-6 text-zinc-900 sm:py-6"
        >
          <span class="absolute inset-0 rounded-2xl bg-zinc-50 transition group-hover:bg-zinc-100 sm:group-hover:scale-105">
          </span>
          <span class="relative flex items-center gap-4 sm:flex-col">
            <.icon name="hero-user-plus" class="h-6 w-6" /> Create
          </span>
        </.link>
        <.link
          navigate={~p"/users/connections"}
          class="group relative rounded-2xl px-6 py-4 text-sm font-semibold leading-6 text-zinc-900 sm:py-6"
        >
          <span class="absolute inset-0 rounded-2xl bg-zinc-50 transition group-hover:bg-zinc-100 sm:group-hover:scale-105">
          </span>
          <span class="relative flex items-center gap-4 sm:flex-col">
            <.icon name="hero-gift-top" class="h-6 w-6" /> Arrivals
          </span>
        </.link>
      </div>
    </div>

    <.modal :if={@live_action in [:new, :edit]} id="new-uc-modal" show on_cancel={JS.patch(~p"/users/connections")}>
      <.live_component
        module={MetamorphicWeb.UserConnectionLive.FormComponent}
        id={@uconn.id || :new}
        title={@page_title}
        action={@live_action}
        uconn={@uconn}
        user={@current_user}
        key={@key}
        patch={~p"/users/connections"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do

    end

    {:ok, assign(socket, :user_connections, Accounts.list_user_connections(socket.assigns.current_user))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Connection")
    |> assign(:uconn, %UserConnection{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Your Connections")
    |> assign(:uconn, nil)
  end
end
