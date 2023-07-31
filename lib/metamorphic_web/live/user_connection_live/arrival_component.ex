defmodule MetamorphicWeb.UserConnectionLive.ArrivalComponent do
  @moduledoc false
  use MetamorphicWeb, :live_component

  alias Metamorphic.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle :if={@action == :screen}>Use this form to screen new connections.</:subtitle>
      </.header>

      <.cards_uconns
        id="arrivals_screen"
        stream={@stream}
        current_user={@user}
        key={@key}
        page={@page}
        end_of_timeline?={@end_of_timeline?}
        card_click={fn uconn -> JS.navigate(~p"/users/connections/#{uconn}") end}
      />
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(page: 1, per_page: 10)
     |> assign(assigns)}
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
       |> assign(:recipient_id, changeset.changes.user_id)}
    else
      {:noreply,
       socket
       |> assign_form(changeset)}
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

  defp build_confirm_attrs(uconn, _socket) do
    IO.inspect(uconn, label: "UCONN")
    %{}
  end
end
