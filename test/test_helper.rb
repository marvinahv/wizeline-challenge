ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Configure ActiveRecord encryption for tests
ActiveRecord::Encryption.configure(
  primary_key: "test_primary_key_for_tests_only_0123456789",
  deterministic_key: "test_deterministic_key_for_tests_only_0123456789",
  key_derivation_salt: "test_derivation_salt_for_tests_only_0123456789"
)

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
