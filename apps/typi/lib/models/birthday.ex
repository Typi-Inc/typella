defmodule Typi.Birthday do
  use Ecto.Schema
  
  import Ecto.Changeset

  schema "birthdays" do
    field :day, :integer
    field :month, :integer
    field :year, :integer
    belongs_to :contact, Typi.Contact
    belongs_to :user, Typi.User

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:day, :month, :year])
    |> validate_required([:day, :month, :year])
  end
end
