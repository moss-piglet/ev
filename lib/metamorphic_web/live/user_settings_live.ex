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
        <.button type="button" class="bg-brand-500" phx-click={JS.patch(~p"/users/confirm")}>
          Confirm my account
        </.button>
      </:actions>
    </.header>

    <.flash_group flash={@flash} />

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
        <.info_banner :if={!@current_user.confirmed_at} navigate={~p"/users/confirm"} nav_title={"Confirm"}>
          Confirm your account to enable the ability to reset your password if you forget it.
        </.info_banner>

        <.simple_form
          for={@forgot_password_form}
          id="forgot_password_form"
          phx-submit="update_forgot_password"
          :if={@current_user.confirmed_at}
        >
          <.input
            field={@forgot_password_form[:is_forgot_pwd?]}
            type="checkbox"
            label="Enable forgot password?"
            description="This gives you the ability to reset your password in case you forget it. Keep in mind, when enabled, your account is slightly less secure because we have to store your key with symmetric encryption. This means a legal authority could access your account data with the proper authorization while this setting is enabled. Disable this at any time to delete the stored encrypted record of your key and return your account to its full security (only your password can decrypt your key) — just don't forget your password."
          />
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
    forgot_password_changeset = Accounts.change_user_forgot_password(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:username_form, to_form(username_changeset))
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
  end
end
