defmodule Typi.PostalAddress do
  use Ecto.Schema

  import Ecto.Changeset

  schema "postal_addresses" do
    field :identifier, :string
    field :city, :string
    field :country, :string
    field :label, :string
    field :postal_code, :string
    field :state, :string
    field :street, :string
    belongs_to :contact, Typi.Contact
    belongs_to :user, Typi.User

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:identifier, :city, :country, :label, :postal_code, :state, :street])
    |> validate_required([:identifier, :city, :country, :label, :postal_code, :state, :street])
  end
end
