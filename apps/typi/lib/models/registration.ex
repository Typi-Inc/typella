defmodule Typi.Registration do
  use Ecto.Schema

  import Ecto.Changeset

  schema "registrations" do
    field :country_code, :string
    field :digits, :string
    field :region, :string
    field :unique_id, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:country_code, :digits, :region, :unique_id])
    |> validate_required([:country_code, :digits, :region, :unique_id])
    |> Typi.PhoneNumber.validate_phone_number
    |> Typi.Device.validate_unique_id
  end
end
