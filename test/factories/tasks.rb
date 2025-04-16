FactoryBot.define do
  factory :task do
    description { "This is a sample task description" }
    status { "todo" }
    association :project
    
    # Associate with a developer user
    association :assignee, factory: [:user, :developer]
  end
end 