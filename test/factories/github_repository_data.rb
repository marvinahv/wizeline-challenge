FactoryBot.define do
  factory :github_repository_datum do
    association :project
    sequence(:full_name) { |n| "octocat/repo-#{n}" }
    sequence(:name) { |n| "repo-#{n}" }
    description { "A test repository" }
    url { "https://github.com/octocat/repo" }
    stargazers_count { 100 }
    forks_count { 50 }
    open_issues_count { 10 }
    last_synced_at { Time.current }
  end
end 