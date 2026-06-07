defmodule HobbyspotBackend.Accounts.UserLocation do
  use Ecto.Schema
  import Ecto.Changeset

  alias HobbyspotBackend.Accounts.User

  @sources ~w(manual gps)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_locations" do
    field :latitude, :decimal
    field :longitude, :decimal
    field :city, :string
    field :country_code, :string
    field :label, :string
    field :search_radius_meters, :integer, default: 5000
    field :source, :string, default: "manual"

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  def changeset(location, attrs) do
    location
    |> cast(attrs, [
      :user_id,
      :latitude,
      :longitude,
      :city,
      :country_code,
      :label,
      :search_radius_meters,
      :source
    ])
    |> validate_required([:user_id, :latitude, :longitude, :search_radius_meters, :source])
    |> validate_number(:latitude, greater_than_or_equal_to: -90, less_than_or_equal_to: 90)
    |> validate_number(:longitude, greater_than_or_equal_to: -180, less_than_or_equal_to: 180)
    |> validate_number(:search_radius_meters,
      greater_than_or_equal_to: 100,
      less_than_or_equal_to: 100_000
    )
    |> validate_inclusion(:source, @sources)
    |> validate_length(:city, max: 160)
    |> validate_length(:country_code, is: 2)
    |> validate_length(:label, max: 160)
    |> assoc_constraint(:user)
    |> unique_constraint(:user_id)
  end
end
