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
        <.input field={@form[:user_id]} type="hidden" value={@user.id} />
        <.input field={@form[:connection_id]} type="hidden" value={@user.connection.id} />
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
    changeset = Accounts.change_user_connection(uconn)

    if :edit == Map.get(assigns, :action) do
      {:ok,
       socket
       #|> assign(:uconn_key, get_uconn_key(uconn))
       |> assign(assigns)
       |> assign_form(changeset)}
    else
      {:ok,
       socket
       |> assign(assigns)
       |> assign_form(changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
