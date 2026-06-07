defmodule HobbyspotBackend.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias HobbyspotBackend.Repo

  alias HobbyspotBackend.Accounts.{
    Interest,
    User,
    UserInterest,
    UserLocation,
    UserToken,
    UserNotifier
  }

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## Interests

  @doc """
  Lists active interests available to mobile clients.
  """
  def list_interests do
    Interest
    |> where([interest], interest.is_active)
    |> order_by([interest], asc: interest.position)
    |> Repo.all()
  end

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.email_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Registers a user with email and password.
  """
  def register_user_with_password(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Saves onboarding profile fields and default discovery location.
  """
  def complete_user_onboarding(%User{} = user, attrs) do
    attrs = stringify_keys(attrs)
    profile_attrs = Map.get(attrs, "profile", %{})
    location_attrs = Map.get(attrs, "location")
    interest_slugs = Map.get(attrs, "interests")
    completed = onboarding_completed_value(attrs, user)

    Repo.transaction(fn ->
      with {:ok, user} <- update_onboarding_profile(user, profile_attrs, completed),
           {:ok, _location} <- upsert_onboarding_location(user, location_attrs),
           {:ok, _interests} <- replace_user_interests_if_present(user, interest_slugs),
           user <- preload_user_onboarding(user),
           {:ok, user} <- validate_onboarding_completion(user, completed) do
        user
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Replaces the user's selected interests.
  """
  def update_user_interests(%User{} = user, slugs) do
    Repo.transaction(fn ->
      with {:ok, _interests} <- replace_user_interests(user, slugs) do
        preload_user_onboarding(user)
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  def preload_user_onboarding(%User{} = user) do
    Repo.preload(user, [:location, user_interests: :interest], force: true)
  end

  def preload_user_location(%User{} = user), do: preload_user_onboarding(user)

  defp onboarding_completed_value(attrs, user) do
    if Map.has_key?(attrs, "completed") && !is_nil(Map.get(attrs, "completed")) do
      Map.fetch!(attrs, "completed")
    else
      user.onboarding_completed
    end
  end

  defp update_onboarding_profile(%User{} = user, profile_attrs, completed) do
    user
    |> User.onboarding_changeset(profile_attrs, completed)
    |> Repo.update()
  end

  defp upsert_onboarding_location(_user, nil), do: {:ok, nil}

  defp upsert_onboarding_location(%User{} = user, location_attrs) do
    location = Repo.get_by(UserLocation, user_id: user.id) || %UserLocation{}

    attrs =
      location_attrs
      |> stringify_keys()
      |> Map.put("user_id", user.id)

    location
    |> UserLocation.changeset(attrs)
    |> Repo.insert_or_update()
  end

  defp replace_user_interests_if_present(_user, nil), do: {:ok, nil}
  defp replace_user_interests_if_present(user, slugs), do: replace_user_interests(user, slugs)

  defp replace_user_interests(%User{} = user, slugs) do
    with {:ok, interests} <- get_active_interests_by_slugs(slugs) do
      now = DateTime.utc_now(:second)

      Repo.delete_all(
        from(user_interest in UserInterest, where: user_interest.user_id == ^user.id)
      )

      entries =
        Enum.map(interests, fn interest ->
          %{
            id: Ecto.UUID.generate(),
            user_id: user.id,
            interest_id: interest.id,
            notifications_enabled: true,
            inserted_at: now,
            updated_at: now
          }
        end)

      Repo.insert_all(UserInterest, entries)

      {:ok, interests}
    end
  end

  defp get_active_interests_by_slugs(slugs) do
    with {:ok, slugs} <- normalize_interest_slugs(slugs) do
      interests =
        Interest
        |> where([interest], interest.is_active and interest.slug in ^slugs)
        |> order_by([interest], asc: interest.position)
        |> Repo.all()

      found_slugs = MapSet.new(interests, & &1.slug)

      if MapSet.size(found_slugs) == length(slugs) do
        {:ok, interests}
      else
        {:error, changeset_error(:interests, "contains unknown interests")}
      end
    end
  end

  defp normalize_interest_slugs(slugs) when is_list(slugs) do
    slugs =
      slugs
      |> Enum.filter(&is_binary/1)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.uniq()

    if slugs == [] do
      {:error, changeset_error(:interests, "select at least one interest")}
    else
      {:ok, slugs}
    end
  end

  defp normalize_interest_slugs(_slugs) do
    {:error, changeset_error(:interests, "must be a non-empty list")}
  end

  defp validate_onboarding_completion(user, false), do: {:ok, user}

  defp validate_onboarding_completion(user, true) do
    []
    |> maybe_add_required_error(:location, is_nil(user.location))
    |> maybe_add_required_error(:interests, Enum.empty?(user.user_interests))
    |> case do
      [] -> {:ok, user}
      errors -> {:error, changeset_errors(errors)}
    end
  end

  defp maybe_add_required_error(errors, _field, false), do: errors
  defp maybe_add_required_error(errors, field, true), do: [{field, "is required"} | errors]

  defp changeset_error(field, message), do: changeset_errors([{field, message}])

  defp changeset_errors(errors) do
    Enum.reduce(errors, Ecto.Changeset.change(%User{}), fn {field, message}, changeset ->
      Ecto.Changeset.add_error(changeset, field, message)
    end)
  end

  defp stringify_keys(attrs) when is_map(attrs) do
    Map.new(attrs, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

  ## Settings

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `HobbyspotBackend.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `HobbyspotBackend.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the user with the given magic link token.
  """
  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Logs the user in by magic link.

  There are three cases to consider:

  1. The user has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The user has not confirmed their email and no password is set.
     In this case, the user gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The user has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      # Prevent session fixation attacks by disallowing magic links for unconfirmed users with password
      {%User{confirmed_at: nil, hashed_password: hash}, _token} when not is_nil(hash) ->
        raise """
        magic link log in is not allowed for unconfirmed users with a password set!

        This cannot happen with the default implementation, which indicates that you
        might have adapted the code to a different use case. Please make sure to read the
        "Mixing magic link and password registration" section of `mix help phx.gen.auth`.
        """

      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, {user, []}}

      nil ->
        {:error, :not_found}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Delivers the magic link login instructions to the given user.
  """
  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {user, tokens_to_expire}}
      end
    end)
  end
end
