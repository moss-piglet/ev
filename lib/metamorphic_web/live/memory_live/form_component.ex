defmodule MetamorphicWeb.MemoryLive.FormComponent do
  use MetamorphicWeb, :live_component

  alias Metamorphic.Memories

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle :if={@action == :new}>Use this form to create a new memory.</:subtitle>
        <:subtitle :if={@action == :edit}>Use this form to edit your existing memory.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="memory-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:user_id]} type="hidden" value={@user.id} />
        <.input field={@form[:username]} type="hidden" value={decr(@user.username, @user, @key)} />
        <.input
          :if={@action != :edit}
          field={@form[:visibility]}
          type="select"
          options={Ecto.Enum.values(Timeline.Post, :visibility)}
          label="Visibility"
          required
        />

        <div
          :if={@selector == "connections" && @action != :edit && has_any_user_connections?(@user)}
          class="space-y-4 mb-6"
        >
          <p class="font-light text-zinc-800">
            Add or remove people to share with (you must be connected to them). To share with all of your connections, use the "x" to remove any open fields:
          </p>

          <div id="shared_users" phx-hook="SortableInputsFor" class="space-y-2">
            <.inputs_for :let={f_nested} field={@form[:shared_users]}>
              <div class="relative flex space-x-2 drag-item">
                <input type="hidden" name="memory[shared_users_order][]" value={f_nested.index} />
                <.input type="hidden" field={f_nested[:sender_id]} value={@user.id} />
                <.input
                  type="text"
                  field={f_nested[:username]}
                  placeholder="Enter username"
                  autocomplete="off"
                />
                <label class="cursor-pointer">
                  <input
                    type="checkbox"
                    name="memory[shared_users_delete][]"
                    value={f_nested.index}
                    class="hidden"
                  />

                  <.icon name="hero-x-mark" class="w-6 h-6 absolute top-4" />
                </label>
              </div>
            </.inputs_for>
          </div>

          <label class="block cursor-pointer">
            <input type="checkbox" name="memory[shared_users_order][]" class="hidden" />
            <.icon name="hero-plus-circle" /> add more
          </label>

          <input type="hidden" name="memory[shared_users_delete][]" />
        </div>

        <.input :if={@action == :new} field={@form[:body]} type="textarea" label="Body" />
        <.input
          :if={@action == :edit && @memory.visibility == :private}
          field={@form[:body]}
          type="textarea"
          label="Body"
          value={decr_item(@memory.blurb, @user, get_memory_key(@memory), @key, @memory)}
        />
        <.input
          :if={@action == :edit && @memory.visibility == :public}
          field={@form[:body]}
          type="textarea"
          label="Body"
          value={decr_item(@memory.blurb, @user, get_memory_key(@memory), @key, @memory)}
        />
        <.input
          :if={@action == :edit && get_shared_item_identity_atom(@memory, @user) == :self}
          field={@form[:body]}
          type="textarea"
          label="Body"
          value={decr_item(@memory.blurb, @user, get_memory_key(@memory), @key, @memory)}
        />
        <:actions>
          <.button :if={@form.source.valid?} phx-disable-with="Saving...">Save Post</.button>
          <.button :if={!@form.source.valid?} disabled class="opacity-25">Save Post</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{memory: memory} = assigns, socket) do
    changeset = Memories.change_memory(memory, %{}, user: assigns.user)

    if :edit == Map.get(assigns, :action) && memory != nil do
      {:ok,
       socket
       |> assign(:memory_key, get_memory_key(memory))
       |> assign(
         :selector,
         Atom.to_string(memory.visibility)
       )
       |> assign(assigns)
       |> assign_form(changeset)}
    else
      {:ok,
       socket
       |> assign(assigns)
       |> assign(:selector, Map.get(assigns, :selector, "private"))
       |> assign_form(changeset)}
    end
  end

  @impl true
  def handle_event("validate", %{"memory" => memory_params}, socket) do
    changeset =
      socket.assigns.memory
      |> Memories.change_memory(memory_params, user: socket.assigns.user)
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign_form(changeset) |> assign(:selector, memory_params["visibility"])}
  end

  def handle_event("save", %{"memory" => memory_params}, socket) do
    save_memory(socket, socket.assigns.action, memory_params)
  end

  defp save_memory(socket, :edit, memory_params) do
    if can_edit?(socket.assigns.user, socket.assigns.memory) do
      user = socket.assigns.user
      key = socket.assigns.key

      case Memories.update_memory(socket.assigns.memory, memory_params,
             update_memory: true,
             memory_key: socket.assigns.memory_key,
             user: user,
             key: key
           ) do
        {:ok, memory} ->
          notify_parent({:updated, memory})

          {:noreply,
           socket
           |> put_flash(:success, "Memory updated successfully")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign_form(socket, changeset)}
      end
    else
      {:noreply, socket}
    end
  end

  defp save_memory(socket, :new, memory_params) do
    user = socket.assigns.user
    key = socket.assigns.key

    if memory_params["user_id"] == user.id do
      case Memories.create_memory(memory_params, user: user, key: key) do
        {:ok, memory} ->
          notify_parent({:saved, memory})

          {:noreply,
           socket
           |> put_flash(:success, "Memory created successfully")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign_form(socket, changeset)}
      end
    else
      {:noreply, socket}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
