defmodule MetamorphicWeb.AdminDashLive do
  use MetamorphicWeb, :live_view

  alias Metamorphic.Accounts

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
      </dl>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Accounts.admin_subscribe(socket.assigns.current_user)
    end

    socket =
      socket
      |> assign(:user_count, Accounts.count_all_users())
      |> assign(:confirmed_user_count, Accounts.count_all_confirmed_users())

    {:ok, socket |> assign(:page_title, "Admin Dashboard")}
  end

  def handle_info({:account_registered, _user}, socket) do
    {:noreply, assign(socket, :user_count, Accounts.count_all_users())}
  end

  def handle_info({:account_confirmed, _user}, socket) do
    {:noreply, assign(socket, :confirmed_user_count, Accounts.count_all_confirmed_users())}
  end

  def handle_info({:account_deleted, _user}, socket) do
    {:noreply,
     socket
     |> assign(:user_count, Accounts.count_all_users())
     |> assign(:confirmed_user_count, Accounts.count_all_confirmed_users())}
  end
end
