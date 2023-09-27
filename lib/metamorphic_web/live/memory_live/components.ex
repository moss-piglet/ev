defmodule MetamorphicWeb.MemoryLive.Components do
  @moduledoc """
  Components for memories.
  """
  use Phoenix.Component
  use MetamorphicWeb, :verified_routes

  import MetamorphicWeb.CoreComponents, only: [avatar: 1, local_time_ago: 1]

  import MetamorphicWeb.Helpers

  attr :id, :string, required: true
  attr :stream, :list, required: true
  attr :card_click, :any, default: nil, doc: "the function for handling phx-click on each card"
  attr :page, :integer, required: true
  attr :end_of_memories?, :boolean, required: true
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
      phx-viewport-bottom={!@end_of_memories? && "next-page"}
      phx-page-loading
      class={[
        if(@end_of_memories?, do: "pb-10", else: "pb-[calc(200vh)]"),
        if(@page == 1, do: "pt-10", else: "pt-[calc(200vh)]") <>
          " grid grid-cols-2 gap-x-4 gap-y-8 sm:grid-cols-3 sm:gap-x-6 lg:grid-cols-4 xl:gap-x-8"
      ]}
    >
      <li :for={{id, item} <- @stream} class="relative" id={id} phx-click={@card_click.(item)}>
        <.memory
          :if={%Metamorphic.Memories.Memory{} = item}
          memory={item}
          current_user={@current_user}
          key={@key}
          color={get_uconn_color_for_shared_item(item, @current_user) || :purple}
        />
      </li>
    </ul>
    <div :if={@end_of_memories?} class="mt-5 text-[50px] text-center font-thin">
      😌 You made it to the beginning of your memory 😌
    </div>
    """
  end

  attr :id, :string, required: true
  attr :stream, :list, required: true
  attr :card_click, :any, default: nil, doc: "the function for handling phx-click on each card"
  attr :page, :integer, required: true
  attr :end_of_memories?, :boolean, required: true
  attr :current_user, :string, required: true
  attr :user, :string, required: true
  attr :key, :string, required: true

  slot :action, doc: "the slot for showing user actions in the last table column"

  def public_cards(assigns) do
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
      phx-viewport-bottom={!@end_of_memories? && "next-page"}
      phx-page-loading
      class={[
        if(@end_of_memories?, do: "pb-10", else: "pb-[calc(200vh)]"),
        if(@page == 1, do: "pt-10", else: "pt-[calc(200vh)]") <>
          " grid grid-cols-2 gap-x-4 gap-y-8 sm:grid-cols-3 sm:gap-x-6 lg:grid-cols-4 xl:gap-x-8"
      ]}
    >
      <li :for={{id, item} <- @stream} class="relative" id={id} phx-click={@card_click.(item)}>
        <.public_memory
          :if={%Metamorphic.Memories.Memory{} = item}
          memory={item}
          current_user={@current_user}
          user={@user}
          key={@key}
          color={get_uconn_color_for_shared_item(item, @user) || :purple}
        />
      </li>
    </ul>
    <div :if={@end_of_memories?} class="mt-5 text-[50px] text-center font-thin">
      😌 Public Memories are coming soon 😌
    </div>
    """
  end

  attr :current_user, :string, required: true
  attr :key, :string, required: true
  attr :memory, Metamorphic.Memories.Memory, required: true

  attr :color, :atom,
    default: :purple,
    values: [:emerald, :orange, :pink, :purple, :rose, :yellow, :zinc]

  def memory(assigns) do
    ~H"""
    <div>
      <div class="group aspect-h-7 aspect-w-10 block w-full overflow-hidden rounded-lg bg-gray-100 focus-within:ring-2 focus-within:ring-brand-500 focus-within:ring-offset-2 focus-within:ring-offset-gray-100 transition hover:cursor-pointer hover:bg-brand-50 sm:hover:rounded-lg sm:hover:scale-105">
        <img
          src={
            get_user_memory(
              get_uconn_for_shared_item(@memory, @current_user),
              @key,
              @memory,
              @current_user
            )
          }
          alt=""
          class="pointer-events-none object-cover group-hover:opacity-75"
        />
        <button type="button" class="absolute inset-0 focus:outline-none">
          <span class="sr-only">coming soon</span>
        </button>
      </div>
    </div>
    """
  end

  attr :current_user, :string, required: true
  attr :user, :string, required: true
  attr :key, :string, required: true
  attr :memory, Metamorphic.Memories.Memory, required: true

  attr :color, :atom,
    default: :purple,
    values: [:emerald, :orange, :pink, :purple, :rose, :yellow, :zinc]

  def public_memory(assigns) do
    ~H"""
    <div>
      <div class="group aspect-h-7 aspect-w-10 block w-full overflow-hidden rounded-lg bg-gray-100 focus-within:ring-2 focus-within:ring-brand-500 focus-within:ring-offset-2 focus-within:ring-offset-gray-100 transition hover:cursor-pointer hover:bg-brand-50 sm:hover:rounded-lg sm:hover:scale-105">
        <img
          src={
            get_public_user_memory(
              @user,
              @memory,
              nil
            )
          }
          alt=""
          class="pointer-events-none object-cover group-hover:opacity-75"
        />
        <button type="button" class="absolute inset-0 focus:outline-none">
          <span class="sr-only">coming soon</span>
        </button>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :stream, :list, required: true
  attr :page, :integer, required: true
  attr :end_of_remarks?, :boolean, required: true
  attr :user, :any, required: true, doc: "the user for the memory"
  attr :current_user, :any, required: true, doc: "the current user of the session"
  attr :key, :string, required: true
  attr :card_click, :any, default: nil, doc: "the function for handling phx-click on each card"

  def remarks(assigns) do
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
      phx-viewport-bottom={!@end_of_remarks? && "next-page"}
      phx-page-loading
      class={[
        if(@end_of_remarks?, do: "pb-10", else: "pb-[calc(100vh)]"),
        if(@page == 1, do: "pt-2", else: "pt-[calc(100vh)]")
      ]}
    >
      <li
        :for={{id, item} <- @stream}
        id={id}
        phx-click={@card_click.(item)}
        class={[
          "group relative flex gap-x-4 space-y-2",
          @card_click &&
            "transition sm:hover:rounded-2xl sm:hover:scale-105"
        ]}
      >
        <.remark
          :if={%Metamorphic.Memories.Remark{} = item}
          remark={item}
          current_user={@current_user}
          user={@user}
          key={@key}
          color={get_uconn_color_for_shared_item(item, @user) || :purple}
        />
      </li>
    </ul>
    <div :if={@end_of_remarks?} class="mt-5 text-[50px] text-center font-thin">
      🎉 You made it to the beginning of the conversation 🎉
    </div>
    """
  end

  def remark(assigns) do
    ~H"""
    <div class="absolute left-0 top-0 flex w-6 justify-center -bottom-6"></div>

    <.avatar
      :if={not is_nil(@current_user)}
      src={
        get_user_avatar(
          get_uconn_for_shared_item(@remark, @current_user),
          @key,
          @remark,
          @current_user
        )
      }
      size="h-6 w-6"
      class="relative mt-3 h-6 w-6 flex-none rounded-full bg-gray-50"
    />
    <div class="flex-auto rounded-md p-3 ring-1 ring-inset ring-gray-200">
      <div class="flex justify-between gap-x-4">
        <div class="py-0.5 text-xs leading-5 text-gray-500">
          <span class="font-medium text-gray-900">
            <%= maybe_show_remark_username(
              decr_item(
                get_item_connection(@remark, @current_user).username,
                @current_user,
                get_remark_key(@remark, @current_user),
                @key,
                @remark
              )
            ) %>
          </span>
          remarked
        </div>
        <time datetime="2023-01-23T15:56" class="flex-none py-0.5 text-xs leading-5 text-gray-500">
          <.local_time_ago id={@remark.id <> "-created"} at={@remark.inserted_at} />
        </time>
      </div>
      <p class="text-sm leading-6 text-gray-500">
        <%= maybe_show_remark_body(
          decr_item(
            @remark.body,
            @current_user,
            get_remark_key(@remark, @current_user),
            @key,
            @remark
          )
        ) %>
      </p>
    </div>
    """
  end

  attr :at, :any, required: true
  attr :id, :any, required: true

  def local_time(assigns) do
    ~H"""
    <time phx-hook="LocalTime" id={"time-#{@id}"} class="hidden"><%= @at %></time>
    """
  end
end
