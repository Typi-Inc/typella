defmodule Typi.Repo.Migrations.CreatePhoneNumber do
  use Ecto.Migration

  def change do
    create table(:phone_numbers) do
      add :country_code, :string, null: false
      add :digits, :string, null: false
      add :identifier, :string
      add :region, :string
      add :label, :string
      add :contact_id, references(:contacts, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:phone_numbers, [:contact_id])
    create index(:phone_numbers, [:user_id])
    create unique_index(:phone_numbers, [:country_code, :digits])
  end
end
