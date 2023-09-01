defmodule MetamorphicWeb.UserConnectionLive.FormComponent do
  @moduledoc false
  use MetamorphicWeb, :live_component

  alias Metamorphic.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle :if={@action == :new}>Use this form to request a new connection.</:subtitle>
        <:subtitle :if={@action == :edit}>Use this form to edit your existing connection.</:subtitle>
      </.header>

      <.simple_form
        :if={@action == :new}
        for={@form}
        id="uconn-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:connection_id]} type="hidden" value={@user.connection.id} />
        <.input field={@form[:user_id]} type="hidden" value={@recipient_id} />
        <.input field={@form[:reverse_user_id]} type="hidden" value={@user.id} />
        <.input field={@form[:request_username]} type="hidden" value={@request_username} />
        <.input field={@form[:request_email]} type="hidden" value={@request_email} />
        <.input field={@form[:key]} type="hidden" value={@recipient_key} />
        <.input field={@form[:label]} type="hidden" />

        <div class="inline-flex items-center space-x-4">
          <.input
            field={@form[:temp_label]}
            type="text"
            label="Label"
            placeholder="Family, friend, partner, et al"
          />

          <.input
            field={@form[:color]}
            type="select"
            label="Color"
            prompt="Choose label color"
            options={
              Enum.map(Ecto.Enum.values(Accounts.UserConnection, :color), fn x ->
                [
                  key: x |> Atom.to_string() |> String.capitalize(),
                  value: x
                ]
              end)
            }
            data-label="label"
          />
        </div>

        <.input
          field={@form[:selector]}
          type="select"
          label="Find by"
          prompt="Choose how to find"
          options={[Username: "username", Email: "email"]}
        />

        <.input
          :if={@selector == "email"}
          field={@form[:email]}
          type="email"
          label="Email"
          autocomplete="off"
        />

        <.input
          :if={@selector == "username"}
          field={@form[:username]}
          type="text"
          label="Username"
          autocomplete="off"
        />

        <:actions>
          <.button :if={@form.source.valid?} phx-disable-with="Saving...">Send</.button>
          <.button :if={!@form.source.valid?} disabled class="opacity-25">Send</.button>
        </:actions>
      </.simple_form>

      <.simple_form
        :if={@action == :edit}
        for={@form}
        id="uconn-edit-form"
        phx-target={@myself}
        phx-change="validate_update"
        phx-submit="update"
      >
        <div class="inline-flex items-center space-x-4">
          <.input
            field={@form[:temp_label]}
            type="text"
            label="New label"
            placeholder="Family, friend, partner, et al"
          />

          <.input
            field={@form[:color]}
            type="select"
            label="Color"
            prompt="Choose label color"
            options={
              Enum.map(Ecto.Enum.values(Accounts.UserConnection, :color), fn x ->
                [
                  key: x |> Atom.to_string() |> String.capitalize(),
                  value: x
                ]
              end)
            }
            data-label="label"
          />
        </div>
        <.input field={@form[:label]} type="hidden" />
        <.input field={@form[:id]} type="hidden" value={@uconn.id} />

        <:actions>
          <.button :if={@form.source.valid?} phx-disable-with="Updating...">Send</.button>
          <.button :if={!@form.source.valid?} disabled class="opacity-25">Send</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{uconn: uconn} = assigns, socket) do
    changeset = Accounts.change_user_connection(uconn, %{}, selector: nil)

    if :edit == Map.get(assigns, :action) do
      {:ok,
       socket
       |> assign(:temp_label, nil)
       |> assign(assigns)
       |> assign_form(changeset)}
    else
      {:ok,
       socket
       |> assign(:recipient_key, nil)
       |> assign(:recipient_id, nil)
       |> assign(:request_email, nil)
       |> assign(:request_username, nil)
       |> assign(:temp_label, nil)
       |> assign(:selector, nil)
       |> assign(assigns)
       |> assign_form(changeset)}
    end
  end

  @impl true
  def handle_event("validate_update", %{"user_connection" => uconn_params}, socket) do
    user = socket.assigns.user
    key = socket.assigns.key

    changeset =
      socket.assigns.uconn
      |> Accounts.edit_user_connection(uconn_params,
        selector: nil,
        user: user,
        key: key,
        conn_key: decr_attrs_key(user.conn_key, user, socket.assigns.key)
      )
      |> Map.put(:action, :validate)

    if Map.has_key?(changeset.changes, :user_id) do
      {:noreply,
       socket
       |> assign_form(changeset)
       |> assign(:temp_label, Ecto.Changeset.get_change(changeset, :temp_label))}
    else
      {:noreply,
       socket
       |> assign_form(changeset)}
    end
  end

  @impl true
  def handle_event("validate", %{"user_connection" => uconn_params}, socket) do
    user = socket.assigns.user
    key = socket.assigns.key

    changeset =
      socket.assigns.uconn
      |> Accounts.change_user_connection(uconn_params,
        selector: uconn_params["selector"],
        user: user,
        key: key
      )
      |> Map.put(:action, :validate)

    if Map.has_key?(changeset.changes, :user_id) do
      {:noreply,
       socket
       |> assign_form(changeset)
       |> assign(:request_email, changeset.changes.request_email)
       |> assign(:request_username, changeset.changes.request_username)
       |> assign(:recipient_key, changeset.changes.key)
       |> assign(:recipient_id, changeset.changes.user_id)
       |> assign(:temp_label, Ecto.Changeset.get_change(changeset, :temp_label))
       |> assign(:selector, uconn_params["selector"])}
    else
      {:noreply,
       socket
       |> assign_form(changeset)
       |> assign(:selector, uconn_params["selector"])}
    end
  end

  @impl true
  def handle_event("save", %{"user_connection" => uconn_params}, socket) do
    user = socket.assigns.user
    key = socket.assigns.key

    case Accounts.create_user_connection(uconn_params, user: user, key: key) do
      {:ok, uconn} ->
        notify_parent({:saved, uconn})

        {:noreply,
         socket
         |> put_flash(:success, "Connection request sent successfully.")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("update", %{"user_connection" => uconn_params}, socket) do
    user = socket.assigns.user
    key = socket.assigns.key
    uconn = Accounts.get_user_connection!(uconn_params["id"])
    d_conn_key = decr_attrs_key(uconn.key, user, key)

    case Accounts.update_user_connection(uconn, uconn_params,
           user: user,
           key: key,
           conn_key: d_conn_key,
           temp_label: uconn_params["temp_label"]
         ) do
      {:ok, uconn} ->
        notify_parent({:updated, uconn})

        {:noreply,
         socket
         |> put_flash(:success, "Connection updated successfully.")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
