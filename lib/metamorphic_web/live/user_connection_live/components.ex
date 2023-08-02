defmodule MetamorphicWeb.UserConnectionLive.Components do
  @moduledoc """
  Components for user connections.
  """
  use Phoenix.Component
  use MetamorphicWeb, :verified_routes

  alias Phoenix.LiveView.JS
  import MetamorphicWeb.Gettext
  import MetamorphicWeb.Helpers

  attr :id, :string, required: true
  attr :stream, :list, required: true
  attr :card_click, :any, default: nil, doc: "the function for handling phx-click on each card"
  attr :page, :integer, required: true
  attr :end_of_timeline?, :boolean, required: true
  attr :current_user, :string, required: true
  attr :key, :string, required: true

  slot :action, doc: "the slot for showing user actions in the last table column"

  def cards(assigns) do
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
      phx-viewport-top={@page > 1 && "prev-page"}
      phx-viewport-bottom={!@end_of_timeline? && "next-page"}
      phx-page-loading
      class={[
        if(@end_of_timeline?, do: "pb-10", else: "pb-[calc(25vh)]"),
        if(@page == 1, do: "pt-10", else: "pt-[calc(25vh)]") &&
          "divide-y divide-brand-100"
      ]}
    >
      <li
        :for={{id, item} <- @stream}
        id={id}
        phx-click={@card_click.(item)}
        class={[
          "group flex gap-x-4 py-5 px-2",
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
    <div :if={@end_of_timeline?} class="mt-5 text-[50px] text-center">
      🎉 You made it to the beginning of time 🎉
    </div>
    """
  end

  attr :current_user, :string, required: true
  attr :key, :string, required: true
  attr :uconn, Metamorphic.Accounts.UserConnection, required: true

  def arrival(assigns) do
    ~H"""
    <img
      class="h-12 w-12 flex-none rounded-full text-center"
      src={~p"/images/logo.svg"}
      alt="Metamorphic egg logo"
    />
    <div class="flex-auto">
      <div class="flex items-baseline justify-between gap-x-4">
        <p class="text-sm font-semibold leading-6 text-gray-900">
          <%= decr_uconn(@uconn.request_email, @current_user, @uconn.key, @key) %>
          <span class="inline-flex items-center rounded-full bg-blue-50 px-2 py-1 text-xs font-medium text-blue-700 ring-1 ring-inset ring-blue-700/10"> <%= decr_uconn(
          @uconn.label,
          @current_user,
          @uconn.key,
          @key
        ) %></span>
        </p>
        <p class="flex-none text-xs text-gray-600">
          <time datetime={@uconn.inserted_at}><%= time_ago(@uconn.inserted_at) %></time>
        </p>
      </div>
      <p class="mt-1 line-clamp-2 text-sm leading-6 text-gray-600">
        username <span class="font-medium text-gray-900"><%= decr_uconn(@uconn.request_username, @current_user, @uconn.key, @key) %></span>
      </p>
      <!-- actions -->
      <div :if={@current_user && @uconn.user_id == @current_user.id} class="mt-2 flex justify-between text-xs align-middle">

        <.link
          :if={@current_user && @uconn.user_id == @current_user.id}
          phx-click={JS.push("accept_uconn", value: %{id: @uconn.id})}
          data-confirm="Are you sure you wish to accept this request?"
          class="inline-flex items-center rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20 transition hover:cursor-pointer hover:scale-105"
        >
          Accept
        </.link>
        <.link
          :if={@current_user && @uconn.user_id == @current_user.id}
          phx-click={JS.push("decline_uconn", value: %{id: @uconn.id})}
          data-confirm="Are you sure you wish to decline this request?"
          class="inline-flex items-center rounded-md bg-red-50 px-2 py-1 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-600/20 transition hover:cursor-pointer hover:scale-105"
        >
          Decline
        </.link>
      </div>
    </div>
    """
  end
end
