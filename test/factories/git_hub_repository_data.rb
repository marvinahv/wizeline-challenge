FactoryBot.define do
  factory :git_hub_repository_datum do
    project { nil }
    full_name { "MyString" }
    name { "MyString" }
    description { "MyText" }
    url { "MyString" }
    stargazers_count { 1 }
    forks_count { 1 }
    open_issues_count { 1 }
    last_synced_at { "2025-04-24 11:41:29" }
  end
end
