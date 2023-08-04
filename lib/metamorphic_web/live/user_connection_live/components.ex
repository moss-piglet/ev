defmodule MetamorphicWeb.UserConnectionLive.Components do
  @moduledoc """
  Components for user connections.
  """
  use Phoenix.Component
  use MetamorphicWeb, :verified_routes

  alias Phoenix.LiveView.JS

  import MetamorphicWeb.CoreComponents, only: [icon: 1, dropdown: 1]
  import MetamorphicWeb.Gettext
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
        />
      </li>
    </ul>
    <div id={"end-of-arrivals"} :if={@end_of_arrivals_timeline?} class="mt-5 text-[50px] text-center">
      🎉 You greeted all your arrivals 🎉
    </div>
    """
  end

  attr :current_user, :string, required: true
  attr :key, :string, required: true
  attr :uconn, Metamorphic.Accounts.UserConnection, required: true

  def arrival(assigns) do
    ~H"""
    <div class="flex w-full items-center justify-between space-x-6 p-2">
      <div class="flex-1 truncate">
        <div class="flex items-center space-x-3">
          <h3 class="truncate text-sm font-medium text-gray-900" title={"username: " <> decr_uconn(@uconn.request_username, @current_user, @uconn.key, @key)}><%= decr_uconn(@uconn.request_username, @current_user, @uconn.key, @key) %></h3>
          <span class="inline-flex flex-shrink-0 items-center rounded-full bg-green-50 px-1.5 py-0.5 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20"><%= decr_uconn(
          @uconn.label,
          @current_user,
          @uconn.key,
          @key
        ) %></span>
        </div>
        <p class="mt-1 truncate text-sm text-gray-500" title={"email: " <> decr_uconn(@uconn.request_email, @current_user, @uconn.key, @key)}><%= decr_uconn(@uconn.request_email, @current_user, @uconn.key, @key) %></p>
        <p class="mt-1 flex justify-start text-xs space-x-4">
        <time datetime={@uconn.inserted_at} class="hidden sm:text-xs sm:block"><%= time_ago(@uconn.inserted_at) %></time>
        </p>
      </div>
      <.dropdown id={"dropdown-" <> @uconn.id} svg_arrows={false}>
        <:img src={~p"/images/logo.svg"}/>

        <:link :if={@current_user && @uconn.user_id == @current_user.id} phx_click={JS.push("accept_uconn", value: %{id: @uconn.id})} data_confirm={nil}>Accept</:link>
        <:link :if={@current_user && @uconn.user_id == @current_user.id} phx_click={JS.push("decline_uconn", value: %{id: @uconn.id})} data_confirm={"Are you sure you wish to decline this request?"}>Decline</:link>
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

    <div id={"end-of-connections"} :if={@end_of_connections_timeline?} class="mt-5 text-[50px] text-center">
      🎉 You've reached the end of your connections 🎉
    </div>
    """
  end

  attr :current_user, :string, required: true
  attr :key, :string, required: true
  attr :uconn, Metamorphic.Accounts.UserConnection, required: true

  def connection(assigns) do
    ~H"""
    <div class="flex flex-1 flex-col p-8">
      <img class="mx-auto h-32 w-32 flex-shrink-0 rounded-full" src="https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=4&w=256&h=256&q=60" alt="">
      <%#= inspect @uconn %>
      <h3 class="mt-6 text-sm font-medium text-gray-900">Jane Cooper</h3>
      <dl class="mt-1 flex flex-grow flex-col justify-between">
        <dt class="sr-only">Email</dt>
        <dd class="text-sm text-gray-500"><%= decr_uconn(@uconn.connection.email, @current_user, @key) %></dd>
        <dt class="sr-only">Label</dt>
        <dd class="mt-3">
          <span class="inline-flex items-center rounded-full bg-brand-50 px-2 py-1 text-xs font-medium text-brand-700 ring-1 ring-inset ring-brand-600/20">
          <%= @uconn.label %></span>
        </dd>
      </dl>
    </div>
    <div>
      <div class="-mt-px flex divide-x divide-gray-200">
        <div class="flex w-0 flex-1">
          <a href="mailto:janecooper@example.com" class="relative -mr-px inline-flex w-0 flex-1 items-center justify-center gap-x-3 rounded-bl-lg border border-transparent py-4 text-sm font-semibold text-gray-900">
            <svg class="h-5 w-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path d="M3 4a2 2 0 00-2 2v1.161l8.441 4.221a1.25 1.25 0 001.118 0L19 7.162V6a2 2 0 00-2-2H3z" />
              <path d="M19 8.839l-7.77 3.885a2.75 2.75 0 01-2.46 0L1 8.839V14a2 2 0 002 2h14a2 2 0 002-2V8.839z" />
            </svg>
            Email
          </a>
        </div>
        <div class="-ml-px flex w-0 flex-1">
          <a href="tel:+1-202-555-0170" class="relative inline-flex w-0 flex-1 items-center justify-center gap-x-3 rounded-br-lg border border-transparent py-4 text-sm font-semibold text-gray-900">
            <svg class="h-5 w-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd" d="M2 3.5A1.5 1.5 0 013.5 2h1.148a1.5 1.5 0 011.465 1.175l.716 3.223a1.5 1.5 0 01-1.052 1.767l-.933.267c-.41.117-.643.555-.48.95a11.542 11.542 0 006.254 6.254c.395.163.833-.07.95-.48l.267-.933a1.5 1.5 0 011.767-1.052l3.223.716A1.5 1.5 0 0118 15.352V16.5a1.5 1.5 0 01-1.5 1.5H15c-1.149 0-2.263-.15-3.326-.43A13.022 13.022 0 012.43 8.326 13.019 13.019 0 012 5V3.5z" clip-rule="evenodd" />
            </svg>
            Call
          </a>
        </div>
      </div>
    </div>
    """
  end
end
