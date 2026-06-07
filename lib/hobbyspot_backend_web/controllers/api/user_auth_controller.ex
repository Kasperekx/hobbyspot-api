defmodule HobbyspotBackendWeb.Api.UserAuthController do
  use HobbyspotBackendWeb, :controller

  alias HobbyspotBackend.Accounts
  alias HobbyspotBackendWeb.Api.UserResponse

  def register(conn, %{"user" => user_params}) do
    case Accounts.register_user_with_password(user_params) do
      {:ok, user} ->
        token = Accounts.generate_user_session_token(user)

        conn
        |> put_status(:created)
        |> json(%{data: Map.put(UserResponse.user_data(user), :token, encode_token(token))})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: errors_on(changeset)})
    end
  end

  def login(conn, %{"user" => %{"email" => email, "password" => password}}) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      token = Accounts.generate_user_session_token(user)
      json(conn, %{data: Map.put(UserResponse.user_data(user), :token, encode_token(token))})
    else
      invalid_credentials(conn)
    end
  end

  def login(conn, _params), do: invalid_credentials(conn)

  def me(conn, _params) do
    user = conn.assigns.current_scope.user
    json(conn, %{data: UserResponse.user_data(user)})
  end

  def update_onboarding(conn, %{"onboarding" => onboarding_params}) do
    user = conn.assigns.current_scope.user

    case Accounts.complete_user_onboarding(user, onboarding_params) do
      {:ok, user} ->
        json(conn, %{data: UserResponse.user_data(user)})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: errors_on(changeset)})
    end
  end

  def update_onboarding(conn, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{onboarding: ["can't be blank"]}})
  end

  def logout(conn, _params) do
    if token = conn.assigns.current_user_token do
      Accounts.delete_user_session_token(token)
    end

    send_resp(conn, :no_content, "")
  end

  defp invalid_credentials(conn) do
    conn
    |> put_status(:unauthorized)
    |> json(%{errors: %{detail: "Invalid email or password"}})
  end

  defp encode_token(token), do: Base.url_encode64(token, padding: false)

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
