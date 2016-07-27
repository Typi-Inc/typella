defmodule Web.VerificationControllerTest do
  use Web.ConnCase, async: true

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
  @registration_attrs %{
    "country_code" => "+7",
    "unique_id" => "9062e0cb-c671-41e2-ab3c-4ce0367d8f08",
    "digits" => "7471113457",
    "region" => "KZ"
  }

  setup %{conn: conn} do
    {:ok, %{conn: put_req_header(conn, "accept", "application/json")}}
  end

  test "POST /verify", %{conn: conn} do
    insert_registration(@registration_attrs)
    conn = post conn, verification_path(conn, :verify), verification: valid_attrs
    assert json_response(conn, 200)["jwt"]
  end

  test "POST /verify sends error if registration is not found", %{conn: conn} do
    conn = post conn, verification_path(conn, :verify), verification: valid_attrs
    assert json_response(conn, 422) == %{"errors" => %{"verification" => "invalid input"}}
  end

  defp insert_registration(attrs) do
    %Typi.Registration{}
    |> Typi.Registration.changeset(attrs)
    |> Typi.Repo.insert!
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
