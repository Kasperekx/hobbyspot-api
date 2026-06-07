defmodule HobbyspotBackendWeb.Api.UserResponse do
  alias HobbyspotBackend.Accounts
  alias HobbyspotBackend.Accounts.{Interest, UserInterest}

  def user_data(user) do
    user = Accounts.preload_user_onboarding(user)

    %{
      user: user_json(user),
      onboarding: onboarding_json(user)
    }
  end

  def catalog_interest_json(%Interest{} = interest) do
    %{
      id: interest.id,
      slug: interest.slug,
      name: interest.name,
      description: interest.description,
      icon: interest.icon
    }
  end

  defp user_json(user) do
    %{
      id: user.id,
      email: user.email,
      confirmed_at: user.confirmed_at
    }
  end

  defp onboarding_json(user) do
    %{
      profile: %{
        avatar_url: user.avatar_url,
        full_name: user.full_name,
        birth_date: user.birth_date
      },
      location: location_json(user.location),
      interests: selected_interests_json(user.user_interests),
      completed: user.onboarding_completed
    }
  end

  defp location_json(nil), do: nil

  defp location_json(location) do
    %{
      latitude: Decimal.to_float(location.latitude),
      longitude: Decimal.to_float(location.longitude),
      city: location.city,
      country_code: location.country_code,
      label: location.label,
      search_radius_meters: location.search_radius_meters,
      source: location.source
    }
  end

  defp selected_interests_json(user_interests) do
    user_interests
    |> Enum.sort_by(& &1.interest.position)
    |> Enum.map(&selected_interest_json/1)
  end

  defp selected_interest_json(%UserInterest{} = user_interest) do
    interest = user_interest.interest

    %{
      id: interest.id,
      slug: interest.slug,
      name: interest.name,
      notifications_enabled: user_interest.notifications_enabled
    }
  end
end
