FactoryBot.define do
  factory :user do
    name { "John Doe" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
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
  end
end 