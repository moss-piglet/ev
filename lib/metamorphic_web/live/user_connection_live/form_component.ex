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
        for={@form}
        id="uconn-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:connection_id]} type="hidden" value={@user.connection.id} />
        <.input field={@form[:user_id]} type="hidden" value={@recipient_id} />
        <.input
          field={@form[:request_username]}
          type="hidden"
          value={decr(@user.username, @user, @key)}
        />
        <.input field={@form[:request_email]} type="hidden" value={decr(@user.email, @user, @key)} />
        <.input field={@form[:key]} type="hidden" value={@recipient_key} />

        <.input
          field={@form[:label]}
          type="text"
          label="Label"
          placeholder="Family, friend, partner, et al"
        />

        <.input
          field={@form[:selector]}
          type="select"
          label="Notify by"
          prompt="Choose how to notify"
          options={[Username: "username", Email: "email"]}
        />

        <.input :if={@selector == "email"} field={@form[:email]} type="email" label="Email" />

        <.input :if={@selector == "username"} field={@form[:username]} type="text" label="Username" />

        <:actions>
          <.button :if={@form.source.valid?} phx-disable-with="Saving...">Send</.button>
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
       # |> assign(:uconn_key, get_uconn_key(uconn))
       |> assign(assigns)
       |> assign_form(changeset)}
    else
      {:ok,
       socket
       |> assign(:recipient_key, nil)
       |> assign(:recipient_id, nil)
       |> assign(:selector, nil)
       |> assign(assigns)
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
       |> assign(:recipient_key, changeset.changes.key)
       |> assign(:recipient_id, changeset.changes.user_id)
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
      {:ok, post} ->
        notify_parent({:saved, post})

        {:noreply,
         socket
         |> put_flash(:info, "Connection request sent successfully.")
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
