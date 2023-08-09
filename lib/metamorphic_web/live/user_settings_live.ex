defmodule MetamorphicWeb.UserSettingsLive do
  use MetamorphicWeb, :live_view

  alias Metamorphic.Accounts

  alias Metamorphic.Encrypted.Users.Utils

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Account Settings
      <:subtitle>Manage your account email address and password settings</:subtitle>
      <:actions :if={!@current_user.confirmed_at}>
        <.button type="button" class="bg-brand-600" phx-click={JS.patch(~p"/users/confirm")}>
          Confirm my account
        </.button>
      </:actions>
    </.header>

    <div class="space-y-12 divide-y">
      <div>
        <.simple_form for={@email_form} id="email_form" phx-submit="update_email">
          <.input
            field={@email_form[:email]}
            type="email"
            label="Email"
            value={decr(@current_user.email, @current_user, @key)}
            required
          />
          <.input
            field={@email_form[:current_password]}
            name="current_password"
            id="current_password_for_email"
            type="password"
            label="Current password"
            value={@email_form_current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Email</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form
          for={@password_form}
          id="password_form"
          action={~p"/users/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <.input
            field={@password_form[:email]}
            type="hidden"
            id="hidden_user_email"
            value={decr(@current_email, @current_user, @key)}
          />
          <.input field={@password_form[:password]} type="password" label="New password" required />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Confirm new password"
          />
          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label="Current password"
            id="current_password_for_password"
            value={@current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Password</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form for={@username_form} id="username_form" phx-submit="update_username">
          <.input
            field={@username_form[:username]}
            type="text"
            label="Username"
            value={decr(@current_user.username, @current_user, @key)}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Username</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form for={@visibility_form} id="visibility_form" phx-submit="update_visibility">
          <.input
            field={@username_form[:visibility]}
            type="select"
            options={Ecto.Enum.values(Accounts.User, :visibility)}
            label="Visibility"
            required
            description?={true}
          >
          <:description_block>
              <div class="space-y-4">
                <dl class="divide-y divide-gray-100">
                  <div class="px-4 py-6 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-0">
                    <dt class="text-sm font-medium leading-6 text-zinc-500">Public</dt>
                    <dd class="mt-1 text-sm leading-6 text-gray-700 sm:col-span-2 sm:mt-0">
                      Metamorphic users can send you connection requests and anyone can view your profile.
                    </dd>
                  </div>
                  <div class="px-4 py-6 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-0">
                    <dt class="text-sm font-medium leading-6 text-zinc-500">Private</dt>
                    <dd class="mt-1 text-sm leading-6 text-gray-700 sm:col-span-2 sm:mt-0">
                      Nobody can send you connection requests and only you can view your profile. You can still send connection requests and make new connections.
                    </dd>
                  </div>
                  <div class="px-4 py-6 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-0">
                    <dt class="text-sm font-medium leading-6 text-zinc-500">Connections</dt>
                    <dd class="mt-1 text-sm leading-6 text-gray-700 sm:col-span-2 sm:mt-0">
                      Metamorphic users can send you connection requests and only you and your connections can view your profile.
                    </dd>
                  </div>
                </dl>
              </div>
            </:description_block>
          </.input>
          <:actions>
            <.button phx-disable-with="Changing...">Change Visibility</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.info_banner
          :if={!@current_user.confirmed_at}
          navigate={~p"/users/confirm"}
          nav_title="Confirm"
        >
          Confirm your account to enable the "forgot password" feature.
        </.info_banner>

        <.simple_form
          :if={@current_user.confirmed_at}
          for={@forgot_password_form}
          id="forgot_password_form"
          phx-submit="update_forgot_password"
        >
          <.input
            field={@forgot_password_form[:is_forgot_pwd?]}
            type="checkbox"
            label={if @current_user.is_forgot_pwd?, do: "Disable forgot password?", else: "Enable forgot password?"}
            description?={true}
          >
            <:description_block>
              <div class="space-y-4">
                <dl class="divide-y divide-gray-100">
                  <div class="px-4 py-6 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-0">
                    <dt class="text-sm font-medium leading-6 text-zinc-500">Action</dt>
                    <dd :if={!@current_user.is_forgot_pwd?} class="mt-1 text-sm leading-6 text-gray-700 sm:col-span-2 sm:mt-0">
                      Enable the forgot password feature.
                    </dd>
                    <dd :if={@current_user.is_forgot_pwd?} class="mt-1 text-sm leading-6 text-gray-700 sm:col-span-2 sm:mt-0">
                      Disable the forgot password feature.
                    </dd>
                  </div>
                  <div class="px-4 py-6 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-0">
                    <dt class="text-sm font-medium leading-6 text-zinc-500">Details</dt>
                    <dd :if={!@current_user.is_forgot_pwd?} class="mt-1 text-sm leading-6 text-gray-700 sm:col-span-2 sm:mt-0">
                      More convenience! Regain access to your account if you forget your password.
                      The key to your data will be stored encrypted at-rest in the database.
                    </dd>
                    <dd :if={@current_user.is_forgot_pwd?} class="mt-1 text-sm leading-6 text-gray-700 sm:col-span-2 sm:mt-0">
                      More privacy! Only you can access your account (provided you don't share your password with anyone 👀).
                      The key to your data will be deleted from the database (currently being stored encrypted at-rest) and your account will be returned to its original asymmetric encryption.
                    </dd>
                  </div>
                  <div class="px-4 py-6 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-0">
                    <dt class="text-sm font-medium leading-6 text-zinc-500">Note</dt>
                    <dd :if={!@current_user.is_forgot_pwd?} class="mt-1 text-sm leading-6 text-gray-700 sm:col-span-2 sm:mt-0">
                      When enabled it's possible for an authorized authority to gain access to your data. This is rare, and unlikely to happen, so we recommend enabling this feature to prevent the chance of getting locked out of your account.
                    </dd>
                    <dd :if={@current_user.is_forgot_pwd?} class="mt-1 text-sm leading-6 text-gray-700 sm:col-span-2 sm:mt-0">
                      When disabled it's impossible for an authorized authority to gain access to your data. But, if you forget your password there's no way we can get you back into your account.
                    </dd>
                  </div>
                </dl>
              </div>
            </:description_block>
          </.input>
          <:actions>
            <.button phx-disable-with="Changing...">Change</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, %{"key" => key} = _session, socket) do
    user = socket.assigns.current_user
    email = Utils.decrypt_user_data(user.email, user, key)

    socket =
      case Accounts.update_user_email(user, email, token, key) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)
    username_changeset = Accounts.change_user_username(user)
    visibility_changeset = Accounts.change_user_visibility(user)
    forgot_password_changeset = Accounts.change_user_forgot_password(user)

    socket =
      socket
      |> assign(:page_title, "Settings")
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:username_form, to_form(username_changeset))
      |> assign(:visibility_form, to_form(visibility_changeset))
      |> assign(:forgot_password_form, to_form(forgot_password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user
    key = socket.assigns.key
    d_email = Utils.decrypt_user_data(user.email, user, key)

    case Accounts.apply_user_email(user, password, user_params,
           key: key,
           user: user,
           d_email: d_email
         ) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          d_email,
          user_params["email"],
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params, change_password: true)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user
    key = socket.assigns.key

    case Accounts.update_user_password(user, password, user_params,
           change_password: true,
           key: key,
           user: user
         ) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("validate_username", params, socket) do
    %{"user" => user_params} = params

    username_form =
      socket.assigns.current_user
      |> Accounts.change_user_username(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, username_form: username_form)}
  end

  def handle_event("update_username", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_user
    key = socket.assigns.key

    case Accounts.update_user_username(user, user_params,
           change_username: true,
           key: key,
           user: user
         ) do
      {:ok, user} ->
        username_form =
          user
          |> Accounts.change_user_username(user_params)
          |> to_form()

        info = "Your username has been updated successfully."

        {:noreply,
         socket
         |> put_flash(:info, info)
         |> assign(username_form: username_form)
         |> redirect(to: ~p"/users/settings")}

      {:error, changeset} ->
        info = "That username may already be taken."

        {:noreply,
         socket
         |> put_flash(:error, info)
         |> assign(username_form: to_form(changeset))
         |> redirect(to: ~p"/users/settings")}
    end
  end

  def handle_event("validate_visibility", params, socket) do
    %{"user" => user_params} = params

    username_form =
      socket.assigns.current_user
      |> Accounts.change_user_visibility(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, username_form: username_form)}
  end

  def handle_event("update_visibility", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_visibility(user, user_params) do
      {:ok, user} ->
        visibility_form =
          user
          |> Accounts.change_user_username(user_params)
          |> to_form()

        info = "Your visibility has been updated successfully."

        {:noreply,
         socket
         |> put_flash(:info, info)
         |> assign(visibility_form: visibility_form)
         |> redirect(to: ~p"/users/settings")}

      {:error, changeset} ->
        info = "Woops, something went wrong."

        {:noreply,
         socket
         |> put_flash(:error, info)
         |> assign(visibility_form: to_form(changeset))
         |> redirect(to: ~p"/users/settings")}
    end
  end

  def handle_event("validate_forgot_password", params, socket) do
    %{"user" => user_params} = params

    forgot_password_form =
      socket.assigns.current_user
      |> Accounts.change_user_forgot_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, forgot_password_form: forgot_password_form)}
  end

  def handle_event("update_forgot_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_user
    key = socket.assigns.key

    if user.confirmed_at do
      case Accounts.update_user_forgot_password(user, user_params,
             change_forgot_password: true,
             key: key,
             user: user
           ) do
        {:ok, user} ->
          forgot_password_form =
            user
            |> Accounts.change_user_forgot_password(user_params)
            |> to_form()

          info = "Your forgot password setting has been updated successfully."

          {:noreply,
           socket
           |> put_flash(:info, info)
           |> assign(forgot_password_form: forgot_password_form)
           |> redirect(to: ~p"/users/settings")}

        {:error, changeset} ->
          %{is_forgot_pwd?: [{info, []}]} =
            Ecto.Changeset.traverse_errors(changeset, fn msg ->
              msg
            end)

          info = "Woops, your forgot password setting " <> info <> "."

          {:noreply,
           socket
           |> put_flash(:error, info)
           |> assign(forgot_password_form: to_form(changeset))
           |> redirect(to: ~p"/users/settings")}
      end
    else
      info = "Woops, you need to confirm your account first."

      {:noreply,
       socket
       |> put_flash(:error, info)
       |> redirect(to: ~p"/users/settings")}
    end
  end
end
