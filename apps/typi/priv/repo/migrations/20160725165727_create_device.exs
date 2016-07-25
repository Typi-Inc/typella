defmodule Typi.Repo.Migrations.CreateDevice do
  use Ecto.Migration

  def change do
    create table(:devices) do
      add :manufacturer, :string
      add :model, :string
      add :device_id, :string
      add :system_name, :string
      add :system_version, :string
      add :bundle_id, :string
      add :version, :string
      add :readable_version, :string
      add :device_name, :string
      add :user_agent, :string
      add :device_locale, :string
      add :device_country, :string
      add :instance_id, :string
      add :unique_id, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:devices, [:user_id])
    # TODO decide what to do here
    create unique_index(:devices, [:unique_id, :instance_id])
    # https://github.com/rebeccahughes/react-native-device-info/issues/67
    # create unique_index(:devices, [:instance_id])
  end
end
