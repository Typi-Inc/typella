defmodule Typi.Repo.Migrations.CreateRegistration do
  use Ecto.Migration

  def change do
    create table(:registrations) do
      add :country_code, :string
      add :digits, :string
      add :region, :string
      add :unique_id, :string

      timestamps()
    end

    create unique_index(:registrations, [:country_code, :digits, :unique_id])
  end
end
