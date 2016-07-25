defmodule Typi.Repo.Migrations.CreateEmailAddress do
  use Ecto.Migration

  def change do
    create table(:email_addresses) do
      add :identifier, :string
      add :label, :string
      add :value, :string
      add :contact_id, references(:contacts, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:email_addresses, [:contact_id])
    create index(:email_addresses, [:user_id])
    create unique_index(:email_addresses, [:value])
  end
end
