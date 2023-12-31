defmodule MetamorphicWeb.PostLive.FormComponent do
  use MetamorphicWeb, :live_component

  alias Metamorphic.Timeline

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle :if={@action == :new}>Use this form to create a new post.</:subtitle>
        <:subtitle :if={@action == :edit}>Use this form to edit your existing post.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="post-form"
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
                <input type="hidden" name="post[shared_users_order][]" value={f_nested.index} />
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
                    name="post[shared_users_delete][]"
                    value={f_nested.index}
                    class="hidden"
                  />

                  <.icon name="hero-x-mark" class="w-6 h-6 absolute top-4" />
                </label>
              </div>
            </.inputs_for>
          </div>

          <label class="block cursor-pointer">
            <input type="checkbox" name="post[shared_users_order][]" class="hidden" />
            <.icon name="hero-plus-circle" /> add more
          </label>

          <input type="hidden" name="post[shared_users_delete][]" />
        </div>

        <.input :if={@action == :new} field={@form[:body]} type="textarea" label="Body" />
        <.input
          :if={@action == :edit && @post.visibility == :private}
          field={@form[:body]}
          type="textarea"
          label="Body"
          value={decr_item(@post.body, @user, get_post_key(@post), @key, @post)}
        />
        <.input
          :if={@action == :edit && @post.visibility == :public}
          field={@form[:body]}
          type="textarea"
          label="Body"
          value={decr_item(@post.body, @user, get_post_key(@post), @key, @post)}
        />
        <.input
          :if={@action == :edit && get_shared_item_identity_atom(@post, @user) == :self}
          field={@form[:body]}
          type="textarea"
          label="Body"
          value={decr_item(@post.body, @user, get_post_key(@post), @key, @post)}
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
  def update(%{post: post} = assigns, socket) do
    changeset = Timeline.change_post(post, %{}, user: assigns.user)

    if :edit == Map.get(assigns, :action) && post != nil do
      {:ok,
       socket
       |> assign(:post_key, get_post_key(post))
       |> assign(
         :selector,
         Atom.to_string(post.visibility)
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
  def handle_event("validate", %{"post" => post_params}, socket) do
    changeset =
      socket.assigns.post
      |> Timeline.change_post(post_params, user: socket.assigns.user)
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign_form(changeset) |> assign(:selector, post_params["visibility"])}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    save_post(socket, socket.assigns.action, post_params)
  end

  defp save_post(socket, :edit, post_params) do
    if can_edit?(socket.assigns.user, socket.assigns.post) do
      user = socket.assigns.user
      key = socket.assigns.key

      case Timeline.update_post(socket.assigns.post, post_params,
             update_post: true,
             post_key: socket.assigns.post_key,
             user: user,
             key: key
           ) do
        {:ok, post} ->
          notify_parent({:updated, post})

          {:noreply,
           socket
           |> put_flash(:success, "Post updated successfully")
           |> push_patch(to: socket.assigns.patch)}
      end
    else
      {:noreply, socket}
    end
  end

  defp save_post(socket, :new, post_params) do
    user = socket.assigns.user
    key = socket.assigns.key

    if post_params["user_id"] == user.id do
      case Timeline.create_post(post_params, user: user, key: key) do
        {:ok, post} ->
          notify_parent({:saved, post})

          {:noreply,
           socket
           |> put_flash(:success, "Post created successfully")
           |> push_patch(to: socket.assigns.patch)}
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
