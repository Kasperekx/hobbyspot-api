defmodule HobbyspotBackend.Repo.Migrations.AddOnboardingProfileFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :avatar_url, :string
      add :full_name, :string
      add :birth_date, :date
    end
  end
end
