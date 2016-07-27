defmodule Typi.VerificationActionTest do
  use Typi.ActionCase, async: true

  alias Typi.VerificationAction
  alias Typi.{User, Device, PhoneNumber, Registration}

  @one_time_password_config Application.get_env(:typi, :pot)
  @valid_attrs %{
    "verification" => %{
      "country_code" => "+7",
      "digits" => "7471113457",
      "unique_id" => "9062e0cb-c671-41e2-ab3c-4ce0367d8f08",
    },
    "devices" => [
      %{
        "manufacturer" => "Apple",
        "model" => "iPhone 6",
        "device_id" => "iPhone7,2",
        "system_name" => "iPhone OS",
        "system_version" => "9.0",
        "bundle_id" => "com.learnium.mobile",
        "version" =>  "1.1.0",
        "readable_version" => "1.1.0.89",
        "device_name" => "Becca's iPhone 6",
        "user_agent" => "Dalvik/2.1.0 (Linux; U; Android 5.1; Google Nexus 4 - 5.1.0 - API 22 - 768x1280 Build/LMY47D)",
        "device_locale" => "en-US",
        "device_country" => "US",
        "instance_id" => "",
        "unique_id" => "9062e0cb-c671-41e2-ab3c-4ce0367d8f08"
      }
    ],
    "phone_numbers" => [
      %{
        "country_code" => "+7",
        "digits" => "7471113457",
        "identifier" => "",
        "region" => "KZ",
        "label" => "mobile"
      }
    ]
  }

  test "VerificationAction errors if registration is not found" do
    assert {:error, reasons} = VerificationAction.execute(valid_attrs)
    assert %{errors: %{verification: ["not yet registered" ]}} = reasons
  end

  test "VerificationAction errors when incorrect country_code/number is passed" do
    registration = insert(:registration)
    assert {:error, reasons} =
      valid_attrs
      |> update_phone_number_prop(:country_code, "+1")
      |> VerificationAction.execute

    assert %{errors: %{verification: ["not yet registered" ]}} = reasons
    assert_no_user_in_db(registration)
  end

  test "VerificationAction errors if incorrect token is passed" do
    registration = insert(:registration)
    assert {:error, reasons} =
      valid_attrs
      |> set_token(valid_attrs["verification"]["token"] <> "1")
      |> VerificationAction.execute

    assert %{errors: %{verification: ["invalid token" ]}} = reasons
    assert_no_user_in_db(registration)
  end

  test "VerificationAction creates new user" do
    registration = insert(:registration)
    assert {:ok, _user} =
      valid_attrs
      |> update_device_prop("unique_id", registration.unique_id)
      |> update_phone_number_prop("digits", registration.digits)
      |> VerificationAction.execute

    assert_user_in_db(registration)
  end

  test "VerificationAction does not create new user if device and phone already exists" do
    registration = insert(:registration)
    insert_user(registration)
    assert {:ok, _user} =
      valid_attrs
      |> update_device_prop("unique_id", registration.unique_id)
      |> update_phone_number_prop("digits", registration.digits)
      |> VerificationAction.execute

    assert_user_in_db(registration, 1, 1)
  end

  test "VerificationAction appends phone to user, when user does not contain phone" do
    registration = build(:registration)
    insert_user(registration)
    registration = registration
    |> Map.put(:digits, get_different_digits(registration.digits))
    |> Repo.insert!

    assert {:ok, _user} =
      valid_attrs
      |> update_device_prop("unique_id", registration.unique_id)
      |> update_phone_number_prop("digits", registration.digits)
      |> VerificationAction.execute

    assert_user_in_db(registration, 1, 2)
  end

  test "VerificationAction appends device to user, when user does not contain device" do
    registration = build(:registration)
    insert_user(registration)
    registration = registration
    |> Map.put(:unique_id, Ecto.UUID.generate)
    |> Repo.insert!

    assert {:ok, _user} =
      valid_attrs
      |> update_device_prop("unique_id", registration.unique_id)
      |> update_phone_number_prop("digits", registration.digits)
      |> VerificationAction.execute

    assert_user_in_db(registration, 2, 1)
  end

  test "VerificationAction deletes registration when user is successfully created/updated" do
    registration = insert(:registration)
    assert {:ok, _user} =
      valid_attrs
      |> update_phone_number_prop("digits", registration.digits)
      |> update_device_prop("unique_id", registration.unique_id)
      |> VerificationAction.execute

    refute Repo.get(Registration, registration.id)
  end

  defp assert_no_user_in_db(registration) do
    refute Repo.get_by(PhoneNumber, Map.take(registration, [:country_code, :digits, :region]))
    refute Repo.get_by(Device, Map.take(registration, [:unique_id]))
    assert [] = Repo.all from u in User,
      join: d in assoc(u, :devices),
      where: d.unique_id == ^registration.unique_id
  end

  defp assert_user_in_db(registration, devices_count \\ 1, phone_numbers_count \\ 1) do
    assert [_device] = Repo.all from d in Device, where: d.unique_id == ^registration.unique_id
    assert [_phone_number] = Repo.all from p in PhoneNumber,
      where: p.country_code == ^registration.country_code and p.digits == ^registration.digits
    assert [user] = Repo.all from u in User,
      join: d in assoc(u, :devices),
      join: p in assoc(u, :phone_numbers),
      where: d.unique_id == ^registration.unique_id or
        (p.country_code == ^registration.country_code and p.digits == ^registration.digits),
      preload: [devices: d, phone_numbers: p]
    assert length(user.devices) == devices_count
    assert length(user.phone_numbers) == phone_numbers_count
  end

  defp get_different_digits(digits) do
    digits
    |> String.to_integer
    |> Kernel.+(1)
    |> to_string
  end

  defp insert_user(registration) do
    %User{
      phone_numbers: [
        params_for(:phone_number, digits: registration.digits)
      ],
      devices: [
        params_for(:device, unique_id: registration.unique_id)
      ]
    } |> Repo.insert!
  end

  defp update_device_prop(attrs, key, value) do
    attrs
    |> Map.merge(%{
      "verification" => attrs["verification"] |> Map.put(key, value),
      "devices" => [
        attrs["devices"]
        |> List.first
        |> Map.put(key, value)
      ]
    })
  end

  defp update_phone_number_prop(attrs, key, value) do
    attrs
    |> Map.merge(%{
      "verification" => attrs["verification"] |> Map.put(key, value),
      "phone_numbers" => [
        attrs["phone_numbers"]
        |> List.first
        |> Map.put(key, value)
      ]
    })
  end

  defp valid_attrs do
    [
      secret: secret,
      expiration: expiration,
      token_length: token_length
    ] = @one_time_password_config

    token = :pot.totp(secret, [
      token_length: token_length,
      interval_length: expiration
    ])
    set_token(@valid_attrs, token)
  end

  defp set_token(attrs, token) do
    Map.merge(attrs, %{
      "verification" => %{
        "token" => token
      }
    }, fn _k, v1, v2 -> Map.merge(v1, v2) end)
  end
end
