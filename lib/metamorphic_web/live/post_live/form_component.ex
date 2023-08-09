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

        <.input :if={@action == :new} field={@form[:body]} type="textarea" label="Body" />
        <.input
          :if={@action == :edit && @post.visibility == :private}
          field={@form[:body]}
          type="textarea"
          label="Body"
          value={decr_post(@post.body, @user, get_post_key(@post), @key, @post)}
        />
        <.input
          :if={@action == :edit && @post.visibility == :public}
          field={@form[:body]}
          type="textarea"
          label="Body"
          value={decr_post(@post.body, @user, get_post_key(@post), @key, @post)}
        />
        <.input
          :if={@action == :edit && get_shared_post_identity_atom(@post, @user) == :self}
          field={@form[:body]}
          type="textarea"
          label="Body"
          value={decr_post(@post.body, @user, get_post_key(@post), @key, @post)}
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

    if :edit == Map.get(assigns, :action) do
      {:ok,
       socket
       |> assign(:post_key, get_post_key(post))
       |> assign(assigns)
       |> assign_form(changeset)}
    else
      {:ok,
       socket
       |> assign(assigns)
       |> assign_form(changeset)}
    end
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    changeset =
      socket.assigns.post
      |> Timeline.change_post(post_params, user: socket.assigns.user)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
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
           |> put_flash(:info, "Post updated successfully")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign_form(socket, changeset)}
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
           |> put_flash(:info, "Post created successfully")
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
