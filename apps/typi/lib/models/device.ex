defmodule Typi.Device do
  use Ecto.Schema

  import Ecto.Changeset

  schema "devices" do
    field :manufacturer, :string
    field :model, :string
    field :device_id, :string
    field :system_name, :string
    field :system_version, :string
    field :bundle_id, :string
    field :version, :string
    field :readable_version, :string
    field :device_name, :string
    field :user_agent, :string
    field :device_locale, :string
    field :device_country, :string
    field :instance_id, :string
    field :unique_id, :string
    belongs_to :user, Typi.User

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:manufacturer, :model, :device_id,
      :system_name, :system_version, :bundle_id, :version,
      :readable_version, :device_name, :user_agent, :device_locale,
      :device_country, :instance_id, :unique_id, :user_id])
    |> validate_required([:unique_id])
    |> validate_unique_id
    # TODO related to https://github.com/rebeccahughes/react-native-device-info/issues/67
    |> unique_constraint(:unique_id, name: :devices_instance_id_unique_id_index)
    |> assoc_constraint(:user)
  end

  def validate_unique_id(changeset) do
    changeset
    |> validate_format(:unique_id, ~r/[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}/)
  end
end
