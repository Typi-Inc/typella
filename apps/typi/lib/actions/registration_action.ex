defmodule Typi.RegistrationAction do

  alias Typi.{ Registration, Repo }

  @one_time_password_config Application.get_env(:typi, :pot)
  @twilio_api Application.get_env(:typi, :twilio_api)
  @twilio_phone_number Application.get_env(:ex_twilio, :phone_number)

  def execute(params) do
    with \
      {:ok, changeset} <- validate_params(params),
      {:ok, registration} <- insert_if_needed(changeset)
    do
      send_one_time_password(params)
      {:ok, registration}
    else
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp validate_params(params) do
    changeset =
      %Registration{}
      |> Registration.changeset(params)

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  defp insert_if_needed(changeset) do
    changeset
    |> Ecto.Changeset.apply_changes
    |> Map.take([ :country_code, :digits, :unique_id ])
    |> get_registration
    |> case do
      nil ->
        Repo.insert(changeset)
      registration ->
        {:ok, registration}
    end
  end

  defp send_one_time_password(%{ "country_code" => country_code, "digits" => digits }) do
    [
      secret: secret,
      expiration: expiration,
      token_length: token_length
    ] = @one_time_password_config

    token = :pot.totp(secret, [
      token_length: token_length,
      interval_length: expiration
    ])

    @twilio_api.Message.create([
      to: country_code <> digits,
      from: @twilio_phone_number,
      body: token
    ])
  end

  defp get_registration(attrs) do
    Repo.get_by(Registration, attrs)
  end
end
