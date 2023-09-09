defmodule MetamorphicWeb.MemoryLive.Components do
  @moduledoc """
  Components for memories.
  """
  use Phoenix.Component
  use MetamorphicWeb, :verified_routes

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
        if(@page == 1, do: "pt-10", else: "pt-[calc(200vh)]") &&
          "grid grid-cols-2 gap-x-4 gap-y-8 sm:grid-cols-3 sm:gap-x-6 lg:grid-cols-4 xl:gap-x-8"
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

  attr :at, :any, required: true
  attr :id, :any, required: true

  def local_time(assigns) do
    ~H"""
    <time phx-hook="LocalTime" id={"time-#{@id}"} class="hidden"><%= @at %></time>
    """
  end
end
