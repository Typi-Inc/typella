defmodule Typi.EmailAddress do
  use Ecto.Schema

  import Ecto.Changeset

  schema "email_addresses" do
    field :identifier, :string
    field :label, :string
    field :value, :string
    belongs_to :contact, Typi.Contact
    belongs_to :user, Typi.User

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:identifier, :label, :value])
    |> validate_required([:identifier, :label, :value])
  end
end
