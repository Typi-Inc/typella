defmodule Typi.Factory do
  use ExMachina.Ecto, repo: Typi.Repo

  alias Typi.{User, Device, PhoneNumber, Registration}

  def registration_factory do
    %Registration{
      country_code: "+7",
      unique_id: random_uuid,
      digits: "747111" <> random_digits(4),
      region: "KZ"
    }
  end

  def user_factory do
    %User{}
  end

  def phone_number_factory do
    %PhoneNumber{
      country_code: "+7",
      digits: "747111" <> random_digits(4),
      identifier: Ecto.UUID.generate,
      region: "KZ",
      label: "mobile"
    }
  end

  def device_factory do
    %Device{
      manufacturer: "Apple",
      model: "iPhone 6",
      device_id: "iPhone7,2",
      system_name: "iPhone OS",
      system_version: "9.0",
      bundle_id: "com.learnium.mobile",
      version:  "1.1.0",
      readable_version: "1.1.0.89",
      device_name: "Becca's iPhone 6",
      user_agent: "Dalvik/2.1.0 (Linux; U; Android 5.1; Google Nexus 4 - 5.1.0 - API 22 - 768x1280 Build/LMY47D)",
      device_locale: "en-US",
      device_country: "US",
      instance_id: "",
      unique_id: random_uuid
    }
  end

  def random_uuid do
    Ecto.UUID.generate
  end

  def random_digits(length) do
    :erlang.system_time(:micro_seconds)
    |> to_string
    |> String.slice(-length, length)
  end
end
