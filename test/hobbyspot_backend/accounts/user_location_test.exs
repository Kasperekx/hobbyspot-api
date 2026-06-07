defmodule HobbyspotBackend.Accounts.UserLocationTest do
  use HobbyspotBackend.DataCase, async: true

  import HobbyspotBackend.AccountsFixtures

  alias HobbyspotBackend.Accounts.UserLocation

  describe "changeset/2" do
    test "accepts a valid onboarding location" do
      user = user_fixture()

      attrs = %{
        user_id: user.id,
        latitude: Decimal.new("52.2297"),
        longitude: Decimal.new("21.0122"),
        city: "Warszawa",
        country_code: "PL",
        label: "Warszawa",
        search_radius_meters: 5000,
        source: "manual"
      }

      changeset = UserLocation.changeset(%UserLocation{}, attrs)

      assert changeset.valid?
      assert {:ok, location} = Repo.insert(changeset)
      assert location.user_id == user.id
      assert Decimal.equal?(location.latitude, Decimal.new("52.2297"))
      assert Decimal.equal?(location.longitude, Decimal.new("21.0122"))
      assert location.search_radius_meters == 5000
      assert location.source == "manual"
    end

    test "rejects invalid coordinates and radius" do
      changeset =
        UserLocation.changeset(%UserLocation{}, %{
          latitude: Decimal.new("91.0"),
          longitude: Decimal.new("181.0"),
          search_radius_meters: 0,
          source: "manual"
        })

      assert "must be less than or equal to 90" in errors_on(changeset).latitude
      assert "must be less than or equal to 180" in errors_on(changeset).longitude
      assert "must be greater than or equal to 100" in errors_on(changeset).search_radius_meters
    end
  end
end
