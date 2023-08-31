defmodule MetamorphicWeb.PostLive.Components do
  @moduledoc """
  Components for posts.
  """
  use Phoenix.Component
  use MetamorphicWeb, :verified_routes

  alias Phoenix.LiveView.JS

  import MetamorphicWeb.CoreComponents, only: [avatar: 1, icon: 1, local_time_ago: 1]
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
        if(@end_of_timeline?, do: "pb-10", else: "pb-[calc(200vh)]"),
        if(@page == 1, do: "pt-10", else: "pt-[calc(200vh)]") &&
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
            "transition hover:cursor-pointer hover:bg-brand-50 sm:hover:rounded-2xl sm:hover:scale-105"
        ]}
      >
        <.post
          :if={%Metamorphic.Timeline.Post{} = item}
          post={item}
          current_user={@current_user}
          key={@key}
          color={get_uconn_color_for_shared_post(item, @current_user) || :purple}
        />
      </li>
    </ul>
    <div :if={@end_of_timeline?} class="mt-5 text-[50px] text-center font-thin">
      🎉 You made it to the beginning of time 🎉
    </div>
    """
  end

  attr :current_user, :string, required: true
  attr :key, :string, required: true
  attr :post, Metamorphic.Timeline.Post, required: true

  attr :color, :atom,
    default: :purple,
    values: [:emerald, :orange, :pink, :purple, :rose, :yellow, :zinc]

  def post(assigns) do
    ~H"""
    <div class="sr-only">
      <.link navigate={~p"/posts/#{@post}"}>Show</.link>
    </div>

    <.avatar
      :if={not is_nil(@current_user)}
      src={
        get_user_avatar(
          get_uconn_avatar_for_shared_post(@post, @current_user),
          @key,
          @post,
          @current_user
        )
      }
    />

    <image
      :if={is_nil(@current_user)}
      src={~p"/images/logo.svg"}
      class="inline-block h-12 w-12 rounded-md bg-zinc-100"
    />

    <div class="relative flex-auto">
      <div class="flex items-baseline justify-between gap-x-4">
        <!-- username -->
        <% post_user = get_user_from_post(@post) %>
        <p
          :if={
            (post_user.visibility == :private && is_my_post?(@post, @current_user) &&
               @post.visibility != :public) ||
              @post.visibility == :private
          }
          class="text-sm font-semibold leading-6 text-gray-900"
        >
          <%= decr_post(
            get_post_connection(@post, @current_user).username,
            @current_user,
            get_post_key(@post, @current_user),
            @key,
            @post
          ) %>
        </p>
        <p
          :if={@post.visibility == :public && is_nil(@current_user)}
          class="text-sm font-semibold leading-6 text-gray-900"
        >
          <%= decr_post(
            get_post_connection(@post, @current_user).username,
            @current_user,
            get_post_key(@post, @current_user),
            @key,
            @post
          ) %>
        </p>

        <p
          :if={
            @post.visibility == :public && not is_nil(@current_user) &&
              !has_user_connection?(@post, @current_user) && !is_my_post?(@post, @current_user)
          }
          class="text-sm font-semibold leading-6 text-gray-900"
        >
          <%= decr_post(
            get_post_connection(@post, @current_user).username,
            @current_user,
            get_post_key(@post, @current_user),
            @key,
            @post
          ) %>
        </p>

        <p
          :if={
            @post.visibility == :public && not is_nil(@current_user) &&
              has_user_connection?(@post, @current_user) && !is_my_post?(@post, @current_user) &&
              post_user.visibility == :private
          }
          class="text-sm font-semibold leading-6 text-gray-900"
        >
          <%= decr_post(
            get_post_connection(@post, @current_user).username,
            @current_user,
            get_post_key(@post, @current_user),
            @key,
            @post
          ) %>
        </p>
        <p
          :if={
            @post.visibility == :connections && not is_nil(@current_user) &&
              has_user_connection?(@post, @current_user) && !is_my_post?(@post, @current_user) &&
              post_user.visibility == :private
          }
          class="text-sm font-semibold leading-6 text-gray-900"
        >
          <%= decr_post(
            get_post_connection(@post, @current_user).username,
            @current_user,
            get_post_key(@post, @current_user),
            @key,
            @post
          ) %>
        </p>

        <.link
          :if={
            post_user.visibility != :private && @post.visibility == :connections &&
              get_shared_post_identity_atom(@post, @current_user) != :self
          }
          navigate={~p"/users/profile/#{post_user}"}
          class={"text-sm font-semibold leading-6 #{username_link_text_color(@color)}"}
          title="Click to view profile"
        >
          <%= decr_post(
            get_post_connection(@post, @current_user).username,
            @current_user,
            get_post_key(@post, @current_user),
            @key,
            @post
          ) %>
        </.link>
        <.link
          :if={
            post_user.visibility != :private && @post.visibility == :connections &&
              get_shared_post_identity_atom(@post, @current_user) == :self
          }
          navigate={~p"/users/profile/#{post_user}"}
          class={"text-sm font-semibold leading-6 #{username_link_text_color(:brand)}"}
          title="Click to view your profile"
        >
          <%= decr_post(
            get_post_connection(@post, @current_user).username,
            @current_user,
            get_post_key(@post, @current_user),
            @key,
            @post
          ) %>
        </.link>

        <.link
          :if={
            @post.visibility == :public && has_user_connection?(@post, @current_user) &&
              post_user.visibility != :private
          }
          navigate={~p"/users/profile/#{post_user}"}
          class={"text-sm font-semibold leading-6 #{username_link_text_color(@color)}"}
          title="Click to view profile"
        >
          <%= decr_post(
            get_post_connection(@post, @current_user).username,
            @current_user,
            get_post_key(@post, @current_user),
            @key,
            @post
          ) %>
        </.link>
        <.link
          :if={@post.visibility == :public && is_my_post?(@post, @current_user)}
          navigate={~p"/users/profile/#{post_user}"}
          class={"text-sm font-semibold leading-6 #{username_link_text_color(:brand)}"}
          title="Click to view your profile"
        >
          <%= decr_post(
            get_post_connection(@post, @current_user).username,
            @current_user,
            get_post_key(@post, @current_user),
            @key,
            @post
          ) %>
        </.link>

        <!-- sharing with users badge -->
        <div :if={get_shared_post_identity_atom(@post, @current_user) == :self && !Enum.empty?(@post.shared_users)} class="absolute right-2 -bottom-2 group space-x-1">
          <span
            :for={uconn <- get_shared_post_user_connection(@post, @current_user)}
            :if={uconn}
            class={"inline-flex items-center rounded-full group-hover:bg-purple-100 group-hover:px-2 group-hover:py-1 group-hover:text-xs group-hover:font-medium #{if uconn, do: badge_group_hover_color(uconn.color)} group-hover:space-x-1"}
          >
            <svg
              class={"h-1.5 w-1.5 #{if uconn, do: badge_svg_fill_color(uconn.color)}"}
              viewBox="0 0 6 6"
              aria-hidden="true"
            >
              <circle cx="3" cy="3" r="3" />
            </svg>
            <span class="hidden group-hover:flex">
              <%= get_username_for_uconn(uconn, @current_user, @key) %>
            </span>
          </span>
        </div>

        <!-- timestamp && label badge -->
        <p class="flex-none text-xs text-gray-600">
          <span class="inline-flex items-center space-x-1">
            <span
              :if={get_shared_post_identity_atom(@post, @current_user) == :self}
              class="inline-flex items-center align-middle rounded-full"
            >
              <svg class="h-1.5 w-1.5 fill-brand-500" viewBox="0 0 6 6" aria-hidden="true">
                <circle cx="3" cy="3" r="3" />
              </svg>
            </span>

            <span
              :if={get_shared_post_identity_atom(@post, @current_user) == :connection}
              class={"inline-flex items-center rounded-full group group-hover:bg-purple-100 group-hover:px-2 group-hover:py-1 group-hover:text-xs group-hover:font-medium #{badge_group_hover_color(@color)} group-hover:space-x-1"}
            >
              <svg
                class={"h-1.5 w-1.5 #{badge_svg_fill_color(@color)}"}
                viewBox="0 0 6 6"
                aria-hidden="true"
              >
                <circle cx="3" cy="3" r="3" />
              </svg>
              <span class="hidden group-hover:flex">
                <%= get_shared_post_label(@post, @current_user, @key) %>
              </span>
            </span>

            <.local_time_ago id={@post.id} at={@post.inserted_at} />
          </span>
        </p>
      </div>
      <p class="mt-1 line-clamp-2 text-sm leading-6 text-gray-600">
        <%= decr_post(@post.body, @current_user, get_post_key(@post), @key, @post) %>
      </p>
      <!-- favorite -->
      <div class="inline-flex space-x-2 align-middle">
        <div
          :if={@current_user && can_fav?(@current_user, @post)}
          class="inline-flex align-middle"
          phx-click="fav"
          phx-value-id={@post.id}
        >
          <.icon name="hero-star" class="h-4 w-4 hover:text-brand-600" />
          <span class="ml-1 text-xs"><%= @post.favs_count %></span>
        </div>

        <div
          :if={@current_user && !can_fav?(@current_user, @post)}
          class="inline-flex align-middle"
          phx-click="unfav"
          phx-value-id={@post.id}
        >
          <.icon name="hero-star-solid" class="h-4 w-4 text-brand-600" />
          <span class="ml-1 text-xs"><%= @post.favs_count %></span>
        </div>

        <div :if={!@current_user && @post.favs_count > 0} class="inline-flex align-middle">
          <.icon name="hero-star-solid" class="h-4 w-4 text-brand-600" />
          <span class="ml-1 text-xs"><%= @post.favs_count %></span>
        </div>
        <!-- repost -->
        <div
          :if={@current_user && can_repost?(@current_user, @post)}
          class="inline-flex align-middle"
          phx-click="repost"
          phx-value-id={@post.id}
          phx-value-body={decr_post(@post.body, @current_user, get_post_key(@post), @key, @post)}
          phx-value-username={decr(@current_user.username, @current_user, @key)}
        >
          <.icon name="hero-arrow-path-rounded-square" class="h-4 w-4 hover:text-brand-600" />
          <span class="ml-1 text-xs"><%= @post.reposts_count %></span>
        </div>

        <div
          :if={@current_user && (@post.reposts_count > 0 && !can_repost?(@current_user, @post))}
          class="inline-flex align-middle"
        >
          <.icon name="hero-arrow-path-rounded-square" class="h-4 w-4" />
          <span class="ml-1 text-xs"><%= @post.reposts_count %></span>
        </div>

        <div :if={!@current_user && @post.reposts_count > 0} class="inline-flex align-middle">
          <.icon name="hero-arrow-path-rounded-square" class="h-4 w-4" />
          <span class="ml-1 text-xs"><%= @post.reposts_count %></span>
        </div>
      </div>
      <!-- actions -->
      <div class="inline-flex space-x-2 ml-1 text-xs align-middle">
        <span :if={@current_user && @post.user_id == @current_user.id}>
          <div class="sr-only">
            <.link navigate={~p"/posts/#{@post}"}>Show</.link>
          </div>
          <.link patch={~p"/posts/#{@post}/edit"} class="hover:text-brand-600">Edit</.link>
        </span>
        <.link
          :if={@current_user && @post.user_id == @current_user.id}
          phx-click={JS.push("delete", value: %{id: @post.id})}
          data-confirm="Are you sure?"
          class="hover:text-brand-600"
        >
          Delete
        </.link>
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
