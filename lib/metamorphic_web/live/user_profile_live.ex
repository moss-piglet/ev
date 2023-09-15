defmodule MetamorphicWeb.UserProfileLive do
  use MetamorphicWeb, :live_view

  alias Metamorphic.Accounts

  def render(%{live_action: :show} = assigns) do
    ~H"""
    <div
      :if={
        @current_user && Map.get(@user.connection, :profile) &&
          @user.connection.profile.visibility == :connections && @user.id != @current_user.id
      }
      id="uconn_profile"
    >
      <div>
        <div>
          <img
            class="h-32 w-full object-cover lg:h-48"
            src="https://images.unsplash.com/photo-1444628838545-ac4016a5418a?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=1950&q=80"
            alt=""
          />
        </div>
        <div class="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
          <div class="-mt-12 sm:-mt-16 sm:flex sm:items-end sm:space-x-5">
            <div class="flex">
              <.avatar
                :if={@user.id != @current_user.id && @user.connection.profile.show_avatar?}
                src={get_user_avatar(get_uconn_for_users(@user, @current_user), @key)}
                alt=""
                class="h-32 w-32 ring-4 ring-white rounded-full"
              />
              <img
                :if={!@user.connection.profile.show_avatar?}
                class="h-32 w-32 ring-4 ring-white rounded-full bg-white"
                src={~p"/images/logo.svg"}
                alt=""
              />
            </div>
            <div class="mt-12 sm:flex sm:min-w-0 sm:flex-1 sm:items-center sm:justify-end sm:space-x-6 sm:pb-1">
              <div class="mt-6 min-w-0 flex-1 sm:hidden md:block">
                <h1
                  :if={@user.connection.profile.show_name?}
                  class="truncate text-2xl font-bold text-gray-900"
                >
                  <%= decr_item(
                    @user.connection.profile.name,
                    @current_user,
                    @user.connection.profile.profile_key,
                    @key,
                    @user.connection.profile
                  ) %>
                </h1>
                <p class="inline-flex text-sm font-medium text-gray-600">
                  @<%= decr_item(
                    @user.connection.profile.username,
                    @current_user,
                    @user.connection.profile.profile_key,
                    @key,
                    @user.connection.profile
                  ) %>
                </p>
                <span
                  :if={uconn = get_uconn_for_users(@user, @current_user)}
                  class={"inline-flex items-center rounded-full #{badge_color(uconn.color)} px-2 py-1 text-xs font-medium #{if uconn, do: badge_group_hover_color(uconn.color)} space-x-1"}
                >
                  <span class="flex">
                    <%= decr_uconn(
                      get_uconn_for_users(@user, @current_user).label,
                      @current_user,
                      get_uconn_for_users(@user, @current_user).key,
                      @key
                    ) %>
                  </span>
                </span>
              </div>
              <div class="mt-6 flex flex-col justify-stretch space-y-3 sm:flex-row sm:space-x-4 sm:space-y-0">
                <.link
                  :if={@user.connection.profile.show_email?}
                  type="button"
                  href={"mailto:#{decr_item(
                      @user.connection.profile.email,
                      @current_user,
                      @user.connection.profile.profile_key,
                      @key,
                      @user.connection.profile
                    )}"}
                  class="inline-flex justify-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
                >
                  <svg
                    class="-ml-0.5 mr-1.5 h-5 w-5 text-gray-400"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path d="M3 4a2 2 0 00-2 2v1.161l8.441 4.221a1.25 1.25 0 001.118 0L19 7.162V6a2 2 0 00-2-2H3z" />
                    <path d="M19 8.839l-7.77 3.885a2.75 2.75 0 01-2.46 0L1 8.839V14a2 2 0 002 2h14a2 2 0 002-2V8.839z" />
                  </svg>
                  <span>
                    <%= decr_uconn(
                      get_uconn_for_users(@user, @current_user).connection.email,
                      @current_user,
                      get_uconn_for_users(@user, @current_user).key,
                      @key
                    ) %>
                  </span>
                </.link>
              </div>
            </div>
          </div>
          <div class="mt-6 hidden min-w-0 flex-1 sm:block md:hidden">
            <h1
              :if={@user.connection.profile.show_name?}
              class="truncate text-2xl font-bold text-gray-900"
            >
              <%= decr_item(
                @user.connection.profile.name,
                @current_user,
                @user.connection.profile.profile_key,
                @key,
                @user.connection.profile
              ) %>
            </h1>
            <p class="inline-flex text-sm font-medium text-gray-600">
              @<%= decr_item(
                @user.connection.profile.username,
                @current_user,
                @user.connection.profile.profile_key,
                @key,
                @user.connection.profile
              ) %>
            </p>
            <span
              :if={uconn = get_uconn_for_users(@user, @current_user)}
              class={"inline-flex items-center rounded-full #{badge_color(uconn.color)} px-2 py-1 text-xs font-medium #{if uconn, do: badge_group_hover_color(uconn.color)} space-x-1"}
            >
              <span class="flex">
                <%= decr_uconn(
                  get_uconn_for_users(@user, @current_user).label,
                  @current_user,
                  get_uconn_for_users(@user, @current_user).key,
                  @key
                ) %>
              </span>
            </span>
          </div>
        </div>
      </div>

      <div :if={@user.connection.profile.about} class="mt-16 border-b border-zinc-200 pb-5">
        <h3 class="text-base font-semibold leading-6 text-zinc-900">About</h3>
        <p class="mt-2 max-w-4xl text-md font-light text-zinc-500">
          <%= decr_item(
            @user.connection.profile.about,
            @current_user,
            @user.connection.profile.profile_key,
            @key,
            @user.connection.profile
          ) %>
        </p>
      </div>

      <div :if={@user.connection.profile.show_public_memories?} class="mt-16  pb-5">
        <h3 class="text-base font-semibold leading-6 text-zinc-900">Memories</h3>
        <ul
          role="list"
          class="mt-2 grid grid-cols-2 gap-x-4 gap-y-8 sm:grid-cols-3 sm:gap-x-6 lg:grid-cols-4 xl:gap-x-8"
        >
          <li class="relative">
            <div class="group aspect-h-7 aspect-w-10 block w-full overflow-hidden rounded-lg bg-zinc-100 focus-within:ring-2 focus-within:ring-brand-500 focus-within:ring-offset-2 focus-within:ring-offset-zinc-100">
              <img
                src="https://images.unsplash.com/photo-1582053433976-25c00369fc93?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=512&q=80"
                alt=""
                class="pointer-events-none object-cover group-hover:opacity-75"
              />
              <button type="button" class="absolute inset-0 focus:outline-none">
                <span class="sr-only">View details for IMG_4985.HEIC</span>
              </button>
            </div>
          </li>
          <!-- More files... -->
        </ul>
      </div>

      <.back :if={@current_user} navigate={~p"/users/dash"}>Back to dash</.back>
    </div>

    <div :if={
      is_nil(@current_user) && Map.get(@user.connection, :profile) &&
        @user.connection.profile.visibility == :public
    }>
      <div>
        <div>
          <img
            class="h-32 w-full object-cover lg:h-48"
            src="https://images.unsplash.com/photo-1444628838545-ac4016a5418a?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=1950&q=80"
            alt=""
          />
        </div>
        <div class="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
          <div class="-mt-12 sm:-mt-16 sm:flex sm:items-end sm:space-x-5">
            <div class="flex">
              <.avatar
                :if={@user.connection.profile.show_avatar?}
                src={get_public_user_avatar(@user, @user.connection.profile)}
                alt=""
                class="h-32 w-32 ring-4 ring-white rounded-full"
              />

              <img
                :if={!@user.connection.profile.show_avatar?}
                class="h-32 w-32 ring-4 ring-white rounded-full bg-white"
                src={~p"/images/logo.svg"}
                alt=""
              />
            </div>
            <div class="mt-12 sm:flex sm:min-w-0 sm:flex-1 sm:items-center sm:justify-end sm:space-x-6 sm:pb-1">
              <div class="mt-6 min-w-0 flex-1 sm:hidden md:block">
                <h1
                  :if={@user.connection.profile.show_name?}
                  class="truncate text-2xl font-bold text-gray-900"
                >
                  <%= decr_public_item(
                    @user.connection.profile.name,
                    @user.connection.profile.profile_key
                  ) %>
                </h1>
                <p class="inline-flex text-sm font-medium text-gray-600">
                  @<%= decr_public_item(
                    @user.connection.profile.username,
                    @user.connection.profile.profile_key
                  ) %>
                </p>
              </div>
              <div class="mt-6 flex flex-col justify-stretch space-y-3 sm:flex-row sm:space-x-4 sm:space-y-0">
                <.link
                  :if={@user.connection.profile.show_email?}
                  type="button"
                  href={"mailto:#{decr_public_item(@user.connection.profile.email, @user.connection.profile.profile_key)}"}
                  class="inline-flex justify-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
                >
                  <svg
                    class="-ml-0.5 mr-1.5 h-5 w-5 text-gray-400"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path d="M3 4a2 2 0 00-2 2v1.161l8.441 4.221a1.25 1.25 0 001.118 0L19 7.162V6a2 2 0 00-2-2H3z" />
                    <path d="M19 8.839l-7.77 3.885a2.75 2.75 0 01-2.46 0L1 8.839V14a2 2 0 002 2h14a2 2 0 002-2V8.839z" />
                  </svg>
                  <span>
                    <%= decr_public_item(
                      @user.connection.profile.email,
                      @user.connection.profile.profile_key
                    ) %>
                  </span>
                </.link>
              </div>
            </div>
          </div>
          <div class="mt-6 hidden min-w-0 flex-1 sm:block md:hidden">
            <h1
              :if={@user.connection.profile.show_name?}
              class="truncate text-2xl font-bold text-gray-900"
            >
              <%= decr_public_item(
                @user.connection.profile.name,
                @user.connection.profile.profile_key
              ) %>
            </h1>
            <p class="inline-flex text-sm font-medium text-gray-600">
              @<%= decr_public_item(
                @user.connection.profile.username,
                @user.connection.profile.profile_key
              ) %>
            </p>
          </div>
        </div>
      </div>

      <div :if={@user.connection.profile.about} class="mt-16 border-b border-zinc-200 pb-5">
        <h3 class="text-base font-semibold leading-6 text-zinc-900">About</h3>
        <p class="mt-2 max-w-4xl text-md font-light text-zinc-500">
          <%= decr_public_item(@user.connection.profile.about, @user.connection.profile.profile_key) %>
        </p>
      </div>

      <div :if={@user.connection.profile.show_public_memories?} class="mt-16  pb-5">
        <h3 class="text-base font-semibold leading-6 text-zinc-900">Memories</h3>
        <ul
          role="list"
          class="mt-2 grid grid-cols-2 gap-x-4 gap-y-8 sm:grid-cols-3 sm:gap-x-6 lg:grid-cols-4 xl:gap-x-8"
        >
          <li class="relative">
            <div class="group aspect-h-7 aspect-w-10 block w-full overflow-hidden rounded-lg bg-zinc-100 focus-within:ring-2 focus-within:ring-brand-500 focus-within:ring-offset-2 focus-within:ring-offset-zinc-100">
              <img
                src="https://images.unsplash.com/photo-1582053433976-25c00369fc93?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=512&q=80"
                alt=""
                class="pointer-events-none object-cover group-hover:opacity-75"
              />
              <button type="button" class="absolute inset-0 focus:outline-none">
                <span class="sr-only">View details for IMG_4985.HEIC</span>
              </button>
            </div>
          </li>
          <!-- More files... -->
        </ul>
      </div>

      <.back :if={!@current_user} navigate={~p"/users/register"}>Get started</.back>
    </div>

    <div
      :if={
        @current_user && Map.get(@user.connection, :profile) &&
          (@user.connection.profile.visibility == :public && @user.id != @current_user.id)
      }
      id="uconn_profile"
    >
      <div>
        <div>
          <img
            class="h-32 w-full object-cover lg:h-48"
            src="https://images.unsplash.com/photo-1444628838545-ac4016a5418a?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=1950&q=80"
            alt=""
          />
        </div>
        <div class="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
          <div class="-mt-12 sm:-mt-16 sm:flex sm:items-end sm:space-x-5">
            <div class="flex">
              <.avatar
                :if={@user.id != @current_user.id && @user.connection.profile.show_avatar?}
                src={get_public_user_avatar(@user, @user.connection.profile)}
                alt=""
                class="h-32 w-32 ring-4 ring-white rounded-full"
              />
              <img
                :if={!@user.connection.profile.show_avatar?}
                class="h-32 w-32 ring-4 ring-white rounded-full bg-white"
                src={~p"/images/logo.svg"}
                alt=""
              />
            </div>
            <div class="mt-12 sm:flex sm:min-w-0 sm:flex-1 sm:items-center sm:justify-end sm:space-x-6 sm:pb-1">
              <div class="mt-6 min-w-0 flex-1 sm:hidden md:block">
                <h1
                  :if={@user.connection.profile.show_name?}
                  class="truncate text-2xl font-bold text-gray-900"
                >
                  <%= decr_public_item(
                    @user.connection.profile.name,
                    @user.connection.profile.profile_key
                  ) %>
                </h1>
                <p class="inline-flex text-sm font-medium text-gray-600">
                  @<%= decr_public_item(
                    @user.connection.profile.username,
                    @user.connection.profile.profile_key
                  ) %>
                </p>
                <span
                  :if={uconn = get_uconn_for_users(@user, @current_user)}
                  class={"inline-flex items-center rounded-full #{badge_color(uconn.color)} px-2 py-1 text-xs font-medium #{if uconn, do: badge_group_hover_color(uconn.color)} space-x-1"}
                >
                  <span class="flex">
                    <%= decr_uconn(
                      get_uconn_for_users(@user, @current_user).label,
                      @current_user,
                      get_uconn_for_users(@user, @current_user).key,
                      @key
                    ) %>
                  </span>
                </span>
              </div>
              <div class="mt-6 flex flex-col justify-stretch space-y-3 sm:flex-row sm:space-x-4 sm:space-y-0">
                <.link
                  :if={@user.connection.profile.show_email?}
                  type="button"
                  href={"mailto:#{decr_public_item(@user.connection.profile.email, @user.connection.profile.profile_key)}"}
                  class="inline-flex justify-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
                >
                  <svg
                    class="-ml-0.5 mr-1.5 h-5 w-5 text-gray-400"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path d="M3 4a2 2 0 00-2 2v1.161l8.441 4.221a1.25 1.25 0 001.118 0L19 7.162V6a2 2 0 00-2-2H3z" />
                    <path d="M19 8.839l-7.77 3.885a2.75 2.75 0 01-2.46 0L1 8.839V14a2 2 0 002 2h14a2 2 0 002-2V8.839z" />
                  </svg>
                  <span>
                    <%= decr_public_item(
                      @user.connection.profile.email,
                      @user.connection.profile.profile_key
                    ) %>
                  </span>
                </.link>
              </div>
            </div>
          </div>
          <div class="mt-6 hidden min-w-0 flex-1 sm:block md:hidden">
            <h1
              :if={@user.connection.profile.show_name?}
              class="truncate text-2xl font-bold text-gray-900"
            >
              <%= decr_public_item(
                @user.connection.profile.name,
                @user.connection.profile.profile_key
              ) %>
            </h1>
            <p class="inline-flex text-sm font-medium text-gray-600">
              @<%= decr_public_item(
                @user.connection.profile.username,
                @user.connection.profile.profile_key
              ) %>
            </p>
            <span
              :if={uconn = get_uconn_for_users(@user, @current_user)}
              class={"inline-flex items-center rounded-full #{badge_color(uconn.color)} px-2 py-1 text-xs font-medium #{if uconn, do: badge_group_hover_color(uconn.color)} space-x-1"}
            >
              <span class="flex">
                <%= decr_uconn(
                  get_uconn_for_users(@user, @current_user).label,
                  @current_user,
                  get_uconn_for_users(@user, @current_user).key,
                  @key
                ) %>
              </span>
            </span>
          </div>
        </div>
      </div>

      <div :if={@user.connection.profile.about} class="mt-16 border-b border-zinc-200 pb-5">
        <h3 class="text-base font-semibold leading-6 text-zinc-900">About</h3>
        <p class="mt-2 max-w-4xl text-md font-light text-zinc-500">
          <%= decr_public_item(@user.connection.profile.about, @user.connection.profile.profile_key) %>
        </p>
      </div>

      <div :if={@user.connection.profile.show_public_memories?} class="mt-16  pb-5">
        <h3 class="text-base font-semibold leading-6 text-zinc-900">Memories</h3>
        <ul
          role="list"
          class="mt-2 grid grid-cols-2 gap-x-4 gap-y-8 sm:grid-cols-3 sm:gap-x-6 lg:grid-cols-4 xl:gap-x-8"
        >
          <li class="relative">
            <div class="group aspect-h-7 aspect-w-10 block w-full overflow-hidden rounded-lg bg-zinc-100 focus-within:ring-2 focus-within:ring-brand-500 focus-within:ring-offset-2 focus-within:ring-offset-zinc-100">
              <img
                src="https://images.unsplash.com/photo-1582053433976-25c00369fc93?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=512&q=80"
                alt=""
                class="pointer-events-none object-cover group-hover:opacity-75"
              />
              <button type="button" class="absolute inset-0 focus:outline-none">
                <span class="sr-only">View details for IMG_4985.HEIC</span>
              </button>
            </div>
          </li>
          <!-- More files... -->
        </ul>
      </div>

      <.back :if={@current_user} navigate={~p"/users/dash"}>Back to dash</.back>
    </div>

    <div :if={
      @current_user && Map.get(@user.connection, :profile) &&
        @user.id == @current_user.id
    }>
      <.header :if={@user.id == @current_user.id}>
        <div class="flex items-center gap-x-6">
          <.avatar
            :if={@user.id == @current_user.id && @user.connection.profile.show_avatar?}
            src={get_user_avatar(@user, @key)}
            alt=""
            class="h-16 w-16 flex-none rounded-full ring-1 ring-gray-900/10"
          />
          <img
            :if={!@user.connection.profile.show_avatar?}
            class="h-32 w-32 ring-4 ring-white rounded-full bg-white"
            src={~p"/images/logo.svg"}
            alt=""
          />
          <h1>
            <div class="text-sm leading-6 text-gray-500">
              Profile
              <span class="text-gray-700"><%= decr(@user.username, @current_user, @key) %></span>
            </div>
            <div class="mt-1 text-base font-semibold leading-6 text-gray-900">
              <%= decr(@user.email, @current_user, @key) %>
            </div>
          </h1>
        </div>

        <:subtitle>
          This is your user profile on <.local_time_now id={@user.id} />.
        </:subtitle>
      </.header>

      <.back :if={@current_user} navigate={~p"/users/dash"}>Back to dash</.back>
    </div>
    """
  end

  def mount(%{"slug" => slug} = _params, _session, socket) do
    if connected?(socket) do
      if socket.assigns.current_user do
        Accounts.private_subscribe(socket.assigns.current_user)
      else
        Accounts.subscribe()
      end
    end


    user = Accounts.get_user_from_profile_slug!(slug)

    socket =
      socket
      |> assign(:slug, slug)
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:user, user)

    {:ok, socket}
  end

  def handle_info({:uconn_visibility_updated, uconn}, socket) do
    user = socket.assigns.current_user

    cond do
      uconn.user_id == user.id ->
        {:noreply, assign(socket, :user, Accounts.get_user_with_preloads(uconn.reverse_user_id))}

      uconn.reverse_user_id == user.id ->
        {:noreply, assign(socket, :user, Accounts.get_user_with_preloads(uconn.user_id))}

      true ->
        {:noreply, socket}
    end
  end

  def handle_info({:uconn_updated, uconn}, socket) do
    current_user = socket.assigns.current_user
    user = socket.assigns.user

    cond do
      is_nil(current_user) ->
        {:noreply, assign(socket, :user, Accounts.get_user_with_preloads(user.id))}

      uconn.user_id == current_user.id ->
        {:noreply, assign(socket, :user, Accounts.get_user_with_preloads(uconn.reverse_user_id))}

      uconn.reverse_user_id == current_user.id ->
        {:noreply, assign(socket, :user, Accounts.get_user_with_preloads(uconn.user_id))}

      true ->
        {:noreply, assign(socket, :user, Accounts.get_user_with_preloads(user.id))}
    end
  end

  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  defp page_title(:show), do: "Profile"
end
