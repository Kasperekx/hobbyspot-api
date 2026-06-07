defmodule HobbyspotBackend.Repo.Migrations.AddOnboardingCompletedToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :onboarding_completed, :boolean, null: false, default: false
    end
  end
end
