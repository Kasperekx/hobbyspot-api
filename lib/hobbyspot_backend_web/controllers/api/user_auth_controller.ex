defmodule HobbyspotBackendWeb.Api.UserAuthController do
  use HobbyspotBackendWeb, :controller

  alias HobbyspotBackend.Accounts

  def register(conn, %{"user" => user_params}) do
    case Accounts.register_user_with_password(user_params) do
      {:ok, user} ->
        token = Accounts.generate_user_session_token(user)

        conn
        |> put_status(:created)
        |> json(%{data: %{token: encode_token(token), user: user_json(user)}})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: errors_on(changeset)})
    end
  end

  def login(conn, %{"user" => %{"email" => email, "password" => password}}) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      token = Accounts.generate_user_session_token(user)
      json(conn, %{data: %{token: encode_token(token), user: user_json(user)}})
    else
      invalid_credentials(conn)
    end
  end

  def login(conn, _params), do: invalid_credentials(conn)

  def me(conn, _params) do
    user = conn.assigns.current_scope.user
    json(conn, %{data: %{user: user_json(user)}})
  end

  def update_onboarding(conn, %{"user" => user_params}) do
    user = conn.assigns.current_scope.user

    case Accounts.complete_user_onboarding(user, user_params) do
      {:ok, user} ->
        json(conn, %{data: %{user: user_json(user)}})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: errors_on(changeset)})
    end
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

  defp user_json(user) do
    %{
      id: user.id,
      email: user.email,
      avatar_url: user.avatar_url,
      full_name: user.full_name,
      birth_date: user.birth_date,
      confirmed_at: user.confirmed_at,
      onboarding_completed: user.onboarding_completed
    }
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
