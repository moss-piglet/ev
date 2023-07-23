defmodule Metamorphic.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :original_post_id, references(:posts, type: :binary_id, on_delete: :delete_all)
      add :username, :string, null: false
      add :body, :string
      add :favs_list, {:array, :binary_id}
      add :reposts_list, {:array, :binary_id}
      add :favs_count, :integer
      add :reposts_count, :integer
      add :repost, :boolean, default: false

      timestamps()
    end

    create index(:posts, [:username])
    create index(:posts, [:repost])
    create index(:posts, [:favs_list])
    create index(:posts, [:reposts_list])
    create unique_index(:posts, [:id, :user_id])
  end
end
