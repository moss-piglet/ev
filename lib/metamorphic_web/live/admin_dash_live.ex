defmodule MetamorphicWeb.AdminDashLive do
  use MetamorphicWeb, :live_view

  alias Metamorphic.Accounts
  alias Metamorphic.Memories

  def render(assigns) do
    ~H"""
    <div>
      <h3 class="text-base font-semibold leading-6 text-gray-900">Stats</h3>
      <dl class="mt-5 grid grid-cols-1 gap-5 sm:grid-cols-3">
        <div class="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6">
          <dt class="truncate text-sm font-medium text-gray-500">Total Accounts</dt>
          <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-900"><%= @user_count %></dd>
        </div>
        <div class="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6">
          <dt class="truncate text-sm font-medium text-gray-500">Total Confirmed</dt>
          <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-900">
            <%= @confirmed_user_count %>
          </dd>
        </div>
        <div class="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6">
          <dt class="truncate text-sm font-medium text-gray-500">Total Subscribers</dt>
          <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-900">TBD</dd>
        </div>
        <div class="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6">
          <dt class="truncate text-sm font-medium text-gray-500">Total Memories</dt>
          <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-900">
            <%= @memory_count %>
          </dd>
        </div>
      </dl>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Accounts.admin_subscribe(socket.assigns.current_user)
      Memories.admin_subscribe(socket.assigns.current_user)
    end

    socket =
      socket
      |> assign(:user_count, Accounts.count_all_users())
      |> assign(:confirmed_user_count, Accounts.count_all_confirmed_users())
      |> assign(:memory_count, Memories.count_all_memories())

    {:ok, socket |> assign(:page_title, "Admin Dashboard")}
  end

  def handle_info({:account_registered, _user}, socket) do
    {:noreply, assign(socket, :user_count, socket.assigns.user_count + 1)}
  end

  def handle_info({:account_confirmed, _user}, socket) do
    {:noreply, assign(socket, :confirmed_user_count, socket.assigns.confirmed_user_count + 1)}
  end

  def handle_info({:account_deleted, _user}, socket) do
    {:noreply,
     socket
     |> assign(:user_count, socket.assigns.user_count - 1)
     |> assign(:confirmed_user_count, socket.assigns.confirmed_user_count - 1)}
  end

  def handle_info({:memory_created, _memory}, socket) do
    {:noreply, assign(socket, :memory_count, socket.assigns.memory_count + 1)}
  end

  def handle_info({:memory_deleted, _memory}, socket) do
    {:noreply, assign(socket, :memory_count, socket.assigns.memory_count - 1)}
  end
end
