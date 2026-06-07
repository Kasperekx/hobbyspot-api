defmodule HobbyspotBackend.Repo.Migrations.CreateUserLocations do
  use Ecto.Migration

  def change do
    create table(:user_locations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :latitude, :decimal, precision: 9, scale: 6, null: false
      add :longitude, :decimal, precision: 9, scale: 6, null: false
      add :city, :string
      add :country_code, :string, size: 2
      add :label, :string
      add :search_radius_meters, :integer, null: false, default: 5000
      add :source, :string, null: false, default: "manual"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_locations, [:user_id])

    create constraint(:user_locations, :latitude_must_be_valid,
             check: "latitude >= -90 AND latitude <= 90"
           )

    create constraint(:user_locations, :longitude_must_be_valid,
             check: "longitude >= -180 AND longitude <= 180"
           )

    create constraint(:user_locations, :search_radius_meters_must_be_valid,
             check: "search_radius_meters >= 100 AND search_radius_meters <= 100000"
           )

    create constraint(:user_locations, :source_must_be_valid,
             check: "source IN ('manual', 'gps')"
           )

    execute """
            ALTER TABLE user_locations
            ADD COLUMN coordinates geography(Point, 4326)
            GENERATED ALWAYS AS (
              ST_SetSRID(
                ST_MakePoint(longitude::double precision, latitude::double precision),
                4326
              )::geography
            ) STORED
            """,
            "ALTER TABLE user_locations DROP COLUMN coordinates"

    execute "CREATE INDEX user_locations_coordinates_gist_index ON user_locations USING GIST (coordinates)",
            "DROP INDEX IF EXISTS user_locations_coordinates_gist_index"
  end
end
