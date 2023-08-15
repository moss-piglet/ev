defmodule MetamorphicWeb.UserSettingsLive do
  use MetamorphicWeb, :live_view

  alias Metamorphic.Accounts
  alias Metamorphic.Encrypted
  alias Metamorphic.Encrypted.Users.Utils
  alias Metamorphic.Extensions.AvatarProcessor

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
    delete_account_changeset = Accounts.change_user_delete_account(user)
    avatar_changeset = Accounts.change_user_avatar(user)

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
      |> assign(:delete_account_form, to_form(delete_account_changeset))
      |> assign(:avatar_form, to_form(avatar_changeset))
      |> assign(:trigger_submit, false)
      |> allow_upload(:avatar,
        accept: ~w(.png .jpeg .jpg),
        max_file_size: 10_000_000,
        auto_upload: true,
        temporary_assigns: [uploaded_files: []]
      )

    {:ok, socket}
  end

  def handle_params(%{} = _params, _url, socket) do
    # Handle the task.async return
    {:noreply, socket}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def handle_event("validate_avatar", params, socket) do
    avatar_form =
      socket.assigns.current_user
      |> Accounts.change_user_avatar(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, avatar_form: avatar_form)}
  end

  def handle_event("update_avatar", _params, socket) do
    user = socket.assigns.current_user
    key = socket.assigns.key
    avatars_bucket = Application.get_env(:metamorphic, :avatars_bucket)
    IO.inspect avatars_bucket, label: "AVATARS BUCKET"

    avatar_url_tuple_list =
      consume_uploaded_entries(
        socket,
        :avatar,
        fn %{path: path} = _meta, entry ->
          # Check the mime_type to avoid malicious file naming
          mime_type = ExMarcel.MimeType.for({:path, path})

          cond do
            mime_type in ["image/jpeg", "image/jpg", "image/png"] ->
              with {:ok, blob} <-
                     Image.open!(path)
                     |> Image.avatar!()
                     |> Image.write(:memory, suffix: ".#{file_ext(entry)}"),
                   {:ok, e_blob} <- prepare_encrypted_blob(blob, user, key),
                   {:ok, file_path} <- prepare_file_path(entry, user.id) do
                make_aws_requests(entry, avatars_bucket, file_path, e_blob, user, key)
              end

            true ->
              {:postpone, :error}
          end
        end
      )

    cond do
      :error in avatar_url_tuple_list ->
        err_msg = "Incorrect file type."
        {:noreply, put_flash(socket, :error, err_msg)}

      :error not in avatar_url_tuple_list ->
        # Get the file path & e_blob from the tuple.
        [{_entry, file_path, e_blob}] = avatar_url_tuple_list

        avatar_params = %{avatar_url: file_path}

        case Accounts.update_user_avatar(user, avatar_params, user: user, key: key) do
          {:ok, _user, conn} ->
            # Put the encrypted avatar blob in ets under the
            # user's connection id.
            AvatarProcessor.put_ets_avatar(conn.id, e_blob)
            info = "Your avatar has been updated successfully."

            avatar_form =
              user
              |> Accounts.change_user_avatar(avatar_params)
              |> to_form()

            {:noreply,
             socket
             |> put_flash(:info, info)
             |> assign(avatar_form: avatar_form)
             |> push_navigate(to: ~p"/users/settings")}

          _rest ->
            {:noreply, socket}
        end
    end
  end

  def handle_event("cancel", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  @doc """
  Deletes the avatar in ETS and object storage.
  """
  def handle_event("delete_avatar", %{"url" => url}, socket) do
    avatars_bucket = Application.get_env(:metamorphic, :avatars_bucket)
    user = socket.assigns.current_user

    with {:ok, _user, conn} <-
           Accounts.update_user_avatar(user, %{avatar_url: nil}, delete_avatar: true),
         true <- AvatarProcessor.delete_ets_avatar(conn.id) do
      # Handle deleting the object storage avatar async.
      with {:ok, _resp} <- ex_aws_delete_request(avatars_bucket, url) do
        info = "Your avatar has been deleted successfully."

        socket =
          socket
          |> put_flash(:info, info)

        {:noreply, push_navigate(socket, to: ~p"/users/settings")}
      else
        _rest -> ex_aws_delete_request(avatars_bucket, url)
      end
    else
      _rest ->
        {:noreply, socket}
    end
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

  def handle_event("validate_delete_account", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    delete_account_form =
      socket.assigns.current_user
      |> Accounts.change_user_delete_account(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply,
     assign(socket,
       delete_account_form: delete_account_form,
       delete_account_form_current_password: password
     )}
  end

  def handle_event("delete_account", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.delete_user_account(user, password, user_params) do
      {:ok, _user} ->
        socket =
          socket
          |> put_flash(:info, "Account deleted successfully.")
          |> redirect(to: ~p"/")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, delete_account_form: to_form(changeset))}
    end
  end

  ## PRIVATE & AWS

  defp file_ext(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    "#{ext}"
  end

  defp filename(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    "#{entry.uuid}.#{ext}"
  end

  defp prepare_file_path(entry, user_id) do
    {:ok, "uploads/user/#{user_id}/avatars/#{filename(entry)}"}
  end

  defp prepare_encrypted_blob(blob, user, key) do
    {:ok, d_conn_key} =
      Encrypted.Users.Utils.decrypt_user_attrs_key(user.conn_key, user, key)

    encrypted_avatar_blob = Encrypted.Utils.encrypt(%{key: d_conn_key, payload: blob})

    cond do
      is_binary(encrypted_avatar_blob) ->
        {:ok, encrypted_avatar_blob}

      !is_binary(encrypted_avatar_blob) ->
        {:error, encrypted_avatar_blob}
    end
  end

  defp make_aws_requests(entry, avatars_bucket, file_path, e_blob, user, key) do
    with {:ok, _resp} <- maybe_delete_old_avatar(avatars_bucket, user, key),
      {:ok, _resp} <- ex_aws_put_request(avatars_bucket, file_path, e_blob) do
        # Return the encrypted_blob in the tuple for putting
        # the encrypted avatar into ets.
        {:ok, {entry, file_path, e_blob}}
    else
      _rest ->
        ex_aws_put_request(avatars_bucket, file_path, e_blob)
    end
  end

  defp ex_aws_delete_request(avatars_bucket, url) do
    ExAws.S3.delete_object(avatars_bucket, url)
    |> ExAws.request()
  end

  defp ex_aws_put_request(avatars_bucket, file_path, e_blob) do
    ExAws.S3.put_object(avatars_bucket, file_path, e_blob)
    |> ExAws.request()
  end

  defp maybe_delete_old_avatar(avatars_bucket, user, key) do
    case user.connection.avatar_url do
      nil ->
        {:ok, "no avatar"}

      _rest ->
        d_url = decr_avatar(user.connection.avatar_url, user, user.conn_key, key)

        with {:ok, resp} <- ex_aws_delete_request(avatars_bucket, d_url) do
          {:ok, resp}
        else
          _rest -> ex_aws_delete_request(avatars_bucket, d_url)
        end
    end
  end
end
