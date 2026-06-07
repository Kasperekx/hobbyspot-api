defmodule HobbyspotBackend.Accounts.Interest do
  use Ecto.Schema
  import Ecto.Changeset

  alias HobbyspotBackend.Accounts.UserInterest

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "interests" do
    field :slug, :string
    field :name, :string
    field :description, :string
    field :icon, :string
    field :is_active, :boolean, default: true
    field :position, :integer

    has_many :user_interests, UserInterest

    timestamps(type: :utc_datetime)
  end

  def changeset(interest, attrs) do
    interest
    |> cast(attrs, [:slug, :name, :description, :icon, :is_active, :position])
    |> validate_required([:slug, :name, :description, :icon, :is_active, :position])
    |> validate_length(:slug, max: 80)
    |> validate_length(:name, max: 120)
    |> validate_length(:icon, max: 80)
    |> validate_number(:position, greater_than: 0)
    |> unique_constraint(:slug)
  end
end
