defmodule Typi.User do
  use Ecto.Schema

  import Ecto.Changeset

  schema "users" do
    has_one :birthday, Typi.Birthday
    has_many :contacts, Typi.Contact
    has_many :devices, Typi.Device
    has_many :email_addresses, Typi.EmailAddress
    has_many :phone_numbers, Typi.PhoneNumber
    has_many :postal_addresses, Typi.PostalAddress

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [])
    |> validate_required([])
    |> cast_assoc(:phone_numbers)
    |> cast_assoc(:devices)
  end
end
