FactoryBot.define do
  factory :user do
    name { "John Doe" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "Password1!" }
    password_confirmation { "Password1!" }
    role { "developer" }
    
    # Admin user trait
    trait :admin do
      name { "Admin User" }
      role { "admin" }
    end
    
    # Project manager trait
    trait :project_manager do
      name { "Project Manager" }
      role { "project_manager" }
    end
    
    # Developer trait
    trait :developer do
      name { "Developer User" }
      role { "developer" }
    end
    
    # User with GitHub connected
    trait :with_github do
      github_token { ENV["TEST_USER_GITHUB_TOKEN"] }
    end
  end
end 