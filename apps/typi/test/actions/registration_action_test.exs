defmodule Typi.RegistrationActionTest do
  use Typi.ActionCase, async: true

  alias Typi.RegistrationAction
  alias Typi.{Registration}

  @valid_attrs %{
    "country_code" => "+7",
    "unique_id" => random_uuid,
    "digits" => "747111" <> random_digits(4),
    "region" => "KZ"
  }

  test "RegistrationAction creates new registration" do
    assert {:ok, _registration} = RegistrationAction.execute(@valid_attrs)
  end

  test "RegistrationAction updates already existing registration" do
    insert(:registration)
    |> atom_keys_to_string_keys
    |> RegistrationAction.execute
    |> assert_one
  end

  # test "/register sends sms via twilio if params are valid", %{conn: conn} do
    # with_mock Typi.ExTwilio.Message, [create: fn([to: to, from: _from, body: body]) ->
    #   assert to == @valid_attrs["country_code"] <> @valid_attrs["digits"]
    # end] do
    #   RegistrationAction.execute(@valid_attrs)
    #   # TODO does not work for some reason
    #   assert called Typi.ExTwilioStub.Message.create
    # end
  # end

  # Errors section
  test "RegistrationAction errors if country_code is not of appropriate format" do
    assert {:error, reasons} =
      @valid_attrs
      |> Map.put("country_code", "123123123")
      |> RegistrationAction.execute

    assert %{errors: %{phone_number: ["invalid phone number"]}} = reasons
  end

  test "RegistrationAction errors if digits are not of appropriate format" do
    assert {:error, reasons} =
      @valid_attrs
      |> Map.put("digits", "123123123123123123123123123")
      |> RegistrationAction.execute

    assert %{errors: %{phone_number: ["invalid phone number"]}} = reasons
  end

  test "RegistrationAction errors if regions is not of appropriate format" do
    assert {:error, reasons} =
      @valid_attrs
      |> Map.put("region", "ADSD")
      |> RegistrationAction.execute

    assert %{errors: %{region: ["should be at most 3 character(s)"]}} = reasons

    assert {:error, reasons} =
      @valid_attrs
      |> Map.put("region", "A")
      |> RegistrationAction.execute

      assert %{errors: %{region: ["should be at least 2 character(s)"]}} = reasons
  end

  test "RegistrationAction errors if unique_id is not of appropriate format" do
    assert {:error, reasons} =
      @valid_attrs
      |> Map.put("unique_id", "A")
      |> RegistrationAction.execute

    assert %{errors: %{unique_id: ["has invalid format"]}} = reasons
  end

  defp assert_one({:ok, registration}) do
    assert [_registration] =
      Repo.all from r in Registration,
        where: r.country_code == ^registration.country_code and
          r.digits == ^registration.digits and r.unique_id == ^registration.unique_id
  end

  defp atom_keys_to_string_keys(map) do
    map
    |> Map.keys
    |> Enum.reduce(%{}, fn key, acc -> Map.put(acc, to_string(key), Map.get(map, key)) end)
  end

end
