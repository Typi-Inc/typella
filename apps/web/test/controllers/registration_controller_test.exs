defmodule Web.RegistrationControllerTest do
  use Web.ConnCase, async: true

  @valid_attrs %{
    "country_code" => "+7",
    "unique_id" => "9062e0cb-c671-41e2-ab3c-4ce0367d8f08",
    "digits" => "7471113457",
    "region" => "KZ"
  }

  setup %{ conn: conn } do
    { :ok, %{ conn: put_req_header(conn, "accept", "application/json") } }
  end

  test "POST /register", %{ conn: conn } do
    conn = post conn, registration_path(conn, :register), registration: @valid_attrs
    assert json_response(conn, 200)
  end

  # Errors section
  test "POST /register sends error if country_code is not of appropriate format", %{conn: conn} do
    conn = post conn, registration_path(conn, :register),
      registration: Map.put(@valid_attrs, "country_code", "123123123")
    assert json_response(conn, 422) == %{"errors" => %{"registration" => "invalid input"}}
  end

  test "POST /register sends error if digits is not of appropriate format", %{conn: conn} do
    conn = post conn, registration_path(conn, :register),
      registration: Map.put(@valid_attrs, "digits", "123123123123123123123")
    assert json_response(conn, 422) == %{"errors" => %{"registration" => "invalid input"}}
  end

  test "POST /register sends error if regions is not of appropriate format", %{conn: conn} do
    conn = post conn, registration_path(conn, :register),
      registration: Map.put(@valid_attrs, "region", "ADSD")
    assert json_response(conn, 422) == %{"errors" => %{"registration" => "invalid input"}}
  end

  test "POST /register sends error if unique_id is not of appropriate format", %{conn: conn} do
    conn = post conn, registration_path(conn, :register),
      registration: Map.put(@valid_attrs, "unique_id", "ADSD")
    assert json_response(conn, 422) == %{"errors" => %{"registration" => "invalid input"}}
  end

end
