defmodule Web.VerificationController do
  use Web.Web, :controller

  plug :scrub_params, "verification" when action in [:verify]

  def verify(conn, %{"verification" => params}) do
    case Typi.verify(params) do
      {:ok, user} ->
        {:ok, jwt, _full_claims} = Guardian.encode_and_sign(user, :token)

        conn
        |> put_status(:ok)
        |> json(%{ jwt: jwt })
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{ errors: %{ verification: "invalid input" } })
    end
  end
end
