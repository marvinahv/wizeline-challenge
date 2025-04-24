FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "Project #{n}" }
    description { "A sample project description" }
    association :owner, factory: [:user, :admin]
    association :manager, factory: [:user, :project_manager]
    github_repo { nil } # Default to nil
    
    trait :with_github_repo do
      github_repo { "octocat/Hello-World" }
    end
  end
end 