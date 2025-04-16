FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "Project #{n}" }
    description { "A sample project description" }
    association :owner, factory: [:user, :admin]
    association :manager, factory: [:user, :project_manager]
  end
end 