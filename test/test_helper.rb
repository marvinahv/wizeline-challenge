ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Set ActiveJob to use the test adapter in the test environment
ActiveJob::Base.queue_adapter = :test

# Configure ActiveRecord encryption for tests
ActiveRecord::Encryption.configure(
  primary_key: "test_primary_key_for_tests_only_0123456789",
  deterministic_key: "test_deterministic_key_for_tests_only_0123456789",
  key_derivation_salt: "test_derivation_salt_for_tests_only_0123456789"
)

# Configure VCR for API request recording and playback
require 'vcr'
require 'webmock/minitest'

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
  
  # Filter out sensitive data such as API tokens
  config.filter_sensitive_data('<GITHUB_TOKEN>') { ENV['TEST_USER_GITHUB_TOKEN'] }
  
  # Allow VCR to record real HTTP requests by default
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body]
  }
  
  # Disallow real HTTP connections when no cassette is being used
  config.allow_http_connections_when_no_cassette = false
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    # Comment out fixtures as we'll be using FactoryBot instead
    # fixtures :all
    
    # Include FactoryBot methods
    include FactoryBot::Syntax::Methods

    # Add more helper methods to be used by all tests here...
  end
end
