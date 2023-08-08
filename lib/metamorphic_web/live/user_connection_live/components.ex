defmodule MetamorphicWeb.UserConnectionLive.Components do
  @moduledoc """
  Components for user connections.
  """
  use Phoenix.Component
  use MetamorphicWeb, :verified_routes

  alias Phoenix.LiveView.JS

  import MetamorphicWeb.CoreComponents, only: [dropdown: 1]
  import MetamorphicWeb.Helpers

  attr :id, :string, required: true
  attr :stream, :list, required: true
  attr :card_click, :any, default: nil, doc: "the function for handling phx-click on each card"
  attr :page, :integer, required: true
  attr :end_of_arrivals_timeline?, :boolean, required: true
  attr :current_user, :string, required: true
  attr :key, :string, required: true

  slot :action, doc: "the slot for showing user actions in the last table column"

  def cards_greeter(assigns) do
    ~H"""
    <span
      :if={@page > 1}
      class="text-3xl fixed bottom-2 right-2 bg-zinc-900 text-white rounded-lg p-3 text-center min-w-[65px] z-50 opacity-80"
    >
      <span class="text-sm">pg</span>
      <%= @page %>
    </span>
    <ul
      id={@id}
      phx-update="stream"
      phx-viewport-top={@page > 1 && "prev-page-arrivals"}
      phx-viewport-bottom={!@end_of_arrivals_timeline? && "next-page-arrivals"}
      phx-page-loading
      class={[
        if(@end_of_arrivals_timeline?, do: "pb-10", else: "pb-[calc(25vh)]"),
        if(@page == 1, do: "pt-10", else: "pt-[calc(25vh)]") &&
          "grid grid-cols-1 gap-6 divide-y divide-brand-100"
      ]}
    >
      <li
        :for={{id, item} <- @stream}
        id={id}
        phx-click={@card_click.(item)}
        class={[
          "col-span-1 divide-y divide-brand-200 gap-x-4 py-2 px-2",
          @card_click &&
            "transition hover:bg-brand-50 sm:hover:rounded-2xl sm:hover:scale-105"
        ]}
      >
        <.arrival
          :if={%Metamorphic.Accounts.UserConnection{} = item}
          uconn={item}
          current_user={@current_user}
          key={@key}
          list_id={id}
        />
      </li>
    </ul>
    <div :if={@end_of_arrivals_timeline?} id="end-of-arrivals" class="mt-5 text-[42px] text-center font-thin">
      😌 You greeted everyone 😌
    </div>
    """
  end

  attr :current_user, :string, required: true
  attr :key, :string, required: true
  attr :uconn, Metamorphic.Accounts.UserConnection, required: true
  attr :list_id, :string

  def arrival(assigns) do
    ~H"""
    <div class="flex w-full items-center justify-between space-x-6 p-2">
      <div class="flex-1 truncate">
        <div class="flex items-center space-x-3">
          <h3
            class="truncate text-sm font-medium text-gray-900"
            title={"username: " <> decr_uconn(@uconn.request_username, @current_user, @uconn.key, @key)}
          >
            <%= decr_uconn(@uconn.request_username, @current_user, @uconn.key, @key) %>
          </h3>
          <span class="inline-flex flex-shrink-0 items-center rounded-full bg-brand-50 px-1.5 py-0.5 text-xs font-medium text-brand-700 ring-1 ring-inset ring-brand-600/20">
            <%= decr_uconn(@uconn.label, @current_user, @uconn.key, @key) %>
          </span>
        </div>
        <p
          class="mt-1 truncate text-sm text-gray-500"
          title={"email: " <> decr_uconn(@uconn.request_email, @current_user, @uconn.key, @key)}
        >
          <%= decr_uconn(@uconn.request_email, @current_user, @uconn.key, @key) %>
        </p>
        <p class="mt-1 flex justify-start text-xs space-x-4">
          <time datetime={@uconn.inserted_at} class="hidden sm:text-xs sm:block">
            <%= time_ago(@uconn.inserted_at) %>
          </time>
        </p>
      </div>
      <.dropdown id={"dropdown-" <> @uconn.id} svg_arrows={false}>
        <:img src={~p"/images/logo.svg"} />

        <:link
          :if={@current_user && @uconn.user_id == @current_user.id}
          phx_click={JS.push("accept_uconn", value: %{id: @uconn.id})}
          data_confirm={nil}
        >
          Accept
        </:link>
        <:link
          :if={@current_user && @uconn.user_id == @current_user.id}
          phx_click={JS.push("decline_uconn", value: %{id: @uconn.id})}
          data_confirm="Are you sure you wish to decline this request?"
        >
          Decline
        </:link>
      </.dropdown>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :stream, :list, required: true
  attr :card_click, :any, default: nil, doc: "the function for handling phx-click on each card"
  attr :page, :integer, required: true
  attr :end_of_connections_timeline?, :boolean, required: true
  attr :current_user, :string, required: true
  attr :key, :string, required: true

  slot :action, doc: "the slot for showing user actions in the last table column"

  def cards_connections(assigns) do
    ~H"""
    <span
      :if={@page > 1}
      class="text-3xl fixed bottom-2 right-2 bg-zinc-900 text-white rounded-lg p-3 text-center min-w-[65px] z-50 opacity-80"
    >
      <span class="text-sm">pg</span>
      <%= @page %>
    </span>
    <ul
      id={@id}
      phx-update="stream"
      phx-viewport-top={@page > 1 && "prev-page-connections"}
      phx-viewport-bottom={!@end_of_connections_timeline? && "next-page-connections"}
      phx-page-loading
      class={[
        if(@end_of_connections_timeline?, do: "pb-10", else: "pb-[calc(25vh)]"),
        if(@page == 1, do: "pt-10", else: "pt-[calc(25vh)]") &&
          "grid grid-cols-1 gap-4 sm:grid-cols-2 md:grid-cols-3 divide-y divide-brand-100"
      ]}
    >
      <li
        :for={{id, item} <- @stream}
        id={id}
        phx-click={@card_click.(item)}
        class={[
          "col-span-1 flex flex-col divide-y divide-gray-200 rounded-lg bg-white text-center shadow",
          @card_click &&
            "transition hover:bg-brand-50 sm:hover:rounded-2xl sm:hover:scale-105"
        ]}
      >
        <.connection
          :if={%Metamorphic.Accounts.UserConnection{} = item}
          uconn={item}
          current_user={@current_user}
          key={@key}
        />
      </li>
    </ul>

    <div
      :if={@end_of_connections_timeline?}
      id="end-of-connections"
      class="mt-5 text-[42px] text-center font-thin"
    >
      🌲 You are loved, and so are they 🌲
    </div>
    """
  end

  attr :current_user, :string, required: true
  attr :key, :string, required: true
  attr :uconn, Metamorphic.Accounts.UserConnection, required: true

  def connection(assigns) do
    ~H"""
    <div class="flex flex-1 flex-col p-8">
      <img class="mx-auto h-32 w-32 flex-shrink-0 rounded-full" src={~p"/images/logo.svg"} alt="" />
      <h3 class="mt-6 text-sm font-medium text-gray-900">
        <%= decr_uconn(@uconn.connection.username, @current_user, @uconn.key, @key) %>
      </h3>
      <dl class="mt-1 flex flex-grow flex-col justify-between">
        <dt class="sr-only">Email</dt>
        <dd class="text-sm text-gray-500">
          <%= decr_uconn(@uconn.connection.email, @current_user, @uconn.key, @key) %>
        </dd>
        <dt class="sr-only">Label</dt>
        <dd class="mt-3">
          <span class="inline-flex items-center rounded-full bg-brand-50 px-2 py-1 text-xs font-medium text-brand-700 ring-1 ring-inset ring-brand-600/20">
            <%= decr_uconn(@uconn.label, @current_user, @uconn.key, @key) %>
          </span>
        </dd>
      </dl>
    </div>
    """
  end
end
