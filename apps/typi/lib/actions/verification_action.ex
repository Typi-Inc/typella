defmodule Typi.VerificationAction do
  use Typi.Action
  require Logger

  alias Typi.{User, Device, PhoneNumber, Registration, Repo}

  @one_time_password_config Application.get_env(:typi, :pot)

  def execute(
    %{
      "verification" => %{
        "country_code" => country_code,
        "unique_id" => unique_id,
        "digits" => digits,
        "token" => token
      }
    } = params
  )
  do
    with \
      :ok <- validate_token(token),
      {:ok, registration} <- get_registration(country_code, unique_id, digits),
      {:ok, user} <- update_or_insert_user(params),
      {:ok, _registration} <- Repo.delete(registration)
    do
      {:ok, user}
    else
      {:error, reasons} ->
        {:error, translate_errors(reasons)}
    end
  end

  defp validate_token(token) do
    [
      secret: secret,
      expiration: expiration,
      token_length: token_length
    ] = @one_time_password_config

    is_valid = :pot.valid_totp(token, secret, [
      token_length: token_length,
      interval_length: expiration
    ])
    if is_valid do
      :ok
    else
      {:error, %{verification: {"invalid token", []}}}
    end
  end

  defp get_registration(country_code, unique_id, digits) do
    case Repo.get_by(Registration, %{country_code: country_code, unique_id: unique_id, digits: digits}) do
      nil -> {:error, %{verification: {"not yet registered", []}}}
      registration -> {:ok, registration}
    end
  end

  defp update_or_insert_user(params) do
    query = from u in User,
      join: d in assoc(u, :devices),
      join: p in assoc(u, :phone_numbers),
      where: d.unique_id == ^params["verification"]["unique_id"] or
        (p.country_code == ^params["verification"]["country_code"] and
        p.digits == ^params["verification"]["digits"]),
      preload: [devices: d, phone_numbers: p]

      case Repo.all(query) do
        [] -> insert_user(params)
        [user] -> update_if_needed(user, params)
        _ ->
          Logger.error "the following params appears to have more then one " <>
            "corresponding user #{inspect params}"
          {:error, %{verification: {"server error please contact us", []}}}
      end
  end

  defp insert_user(params) do
    %User{}
    |> User.changeset(params)
    |> Repo.insert
  end

  defp update_if_needed(user, params) do
    case {has_device(user, params), has_phone_number(user, params)} do
      {true, true} ->
        {:ok, user}
      {true, false} ->
        phone_number_changeset =
          params["phone_numbers"]
          |> List.first
          |> (&PhoneNumber.changeset(%PhoneNumber{}, &1)).()
        add_assoc(user, :phone_numbers, phone_number_changeset)
      {false, true} ->
        device_changeset =
          params["devices"]
          |> List.first
          |> (&Device.changeset(%Device{}, &1)).()
        add_assoc(user, :devices, device_changeset)
      _ ->
        Logger.error "The following user seems to have have either device or phone " <>
          "from the following registration, however in reality has " <>
          "does not have both/n#{inspect user}/n#{inspect params}"
    end
  end

  defp has_device(user, params) do
    contains?(user.devices, fn device ->
      device.unique_id == params["verification"]["unique_id"]
    end)
  end

  defp has_phone_number(user, params) do
    contains?(user.phone_numbers, fn phone_number ->
      phone_number.country_code == params["verification"]["country_code"] and
      phone_number.digits == params["verification"]["digits"]
    end)

  end

  defp contains?(list, func) do
    Enum.filter(list, func)
    |> case do
      [] -> false
      _ -> true
    end
  end

  defp add_assoc(user, assoc_key, assoc_changeset) do
    children_changesets =
      Map.get(user, assoc_key)
      |> Enum.map(&Ecto.Changeset.change/1)
      |> Kernel.++([assoc_changeset])

    user
    |> Ecto.Changeset.change
    |> Ecto.Changeset.put_assoc(assoc_key, children_changesets)
    |> Repo.update
  end
end
