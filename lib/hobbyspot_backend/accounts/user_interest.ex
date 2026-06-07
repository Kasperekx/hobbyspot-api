defmodule HobbyspotBackend.Accounts.UserInterest do
  use Ecto.Schema
  import Ecto.Changeset

  alias HobbyspotBackend.Accounts.{Interest, User}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_interests" do
    field :notifications_enabled, :boolean, default: true

    belongs_to :user, User
    belongs_to :interest, Interest

    timestamps(type: :utc_datetime)
  end

  def changeset(user_interest, attrs) do
    user_interest
    |> cast(attrs, [:user_id, :interest_id, :notifications_enabled])
    |> validate_required([:user_id, :interest_id, :notifications_enabled])
    |> assoc_constraint(:user)
    |> assoc_constraint(:interest)
    |> unique_constraint([:user_id, :interest_id])
  end
end
