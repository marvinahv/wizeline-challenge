require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "valid user" do
    user = build(:user)
    assert user.valid?
  end

  test "requires name" do
    user = build(:user, name: nil)
    assert_not user.valid?
    assert_includes user.errors.full_messages, "Name can't be blank"
  end

  test "requires email" do
    user = build(:user, email: nil)
    assert_not user.valid?
    assert_includes user.errors.full_messages, "Email can't be blank"
  end

  test "requires valid email format" do
    user = build(:user, email: "invalid-email")
    assert_not user.valid?
    assert_includes user.errors.full_messages, "Email is invalid"
  end

  test "requires unique email" do
    create(:user, email: "duplicate@example.com")
    user = build(:user, email: "duplicate@example.com")
    assert_not user.valid?
    assert_includes user.errors.full_messages, "Email has already been taken"
  end

  test "requires password" do
    user = build(:user, password: nil)
    assert_not user.valid?
    assert_includes user.errors.full_messages, "Password can't be blank"
  end

  test "password must be at least 8 characters" do
    user = build(:user, password: "Pass1!", password_confirmation: "Pass1!")
    assert_not user.valid?
    assert_includes user.errors.full_messages, "Password is too short (minimum is 8 characters)"
  end
  
  test "password must include uppercase, lowercase, number and symbol" do
    # Missing uppercase
    user = build(:user, password: "password1!", password_confirmation: "password1!")
    assert_not user.valid?
    
    # Missing lowercase
    user = build(:user, password: "PASSWORD1!", password_confirmation: "PASSWORD1!")
    assert_not user.valid?
    
    # Missing number
    user = build(:user, password: "Password!", password_confirmation: "Password!")
    assert_not user.valid?
    
    # Missing symbol
    user = build(:user, password: "Password1", password_confirmation: "Password1")
    assert_not user.valid?
    
    # Valid password
    user = build(:user, password: "Password1!", password_confirmation: "Password1!")
    assert user.valid?
  end

  test "requires valid role" do
    user = build(:user, role: "invalid_role")
    assert_not user.valid?
    assert_includes user.errors.full_messages, "Role is not included in the list"
  end

  test "accepts valid roles" do
    %w[admin project_manager developer].each do |role|
      user = build(:user, role: role)
      assert user.valid?, "#{role} should be a valid role"
    end
  end

  # Authentication tests
  test "authenticates with valid credentials" do
    user = create(:user, password: "StrongP@ss123", password_confirmation: "StrongP@ss123")
    authenticated_user = User.authenticate(user.email, "StrongP@ss123")
    assert_equal user, authenticated_user
  end
  
  test "does not authenticate with invalid credentials" do
    user = create(:user, password: "StrongP@ss123", password_confirmation: "StrongP@ss123")
    authenticated_user = User.authenticate(user.email, "WrongP@ss123")
    assert_nil authenticated_user
  end
  
  test "generates JWT token" do
    user = create(:user)
    token = user.generate_jwt
    assert_not_nil token
    
    decoded_token = JWT.decode(
      token, 
      Rails.application.credentials.secret_key_base, 
      true, 
      { algorithm: 'HS256' }
    ).first
    
    assert_equal user.id, decoded_token["user_id"]
    assert_equal user.role, decoded_token["role"]
    assert decoded_token["exp"] > Time.now.to_i
  end
  
  test "generates different tokens for different users" do
    user1 = create(:user)
    user2 = create(:user)
    
    token1 = user1.generate_jwt
    token2 = user2.generate_jwt
    
    assert_not_equal token1, token2
  end
  
  test "creates users with different roles" do
    admin = create(:user, :admin)
    project_manager = create(:user, :project_manager)
    developer = create(:user, :developer)
    
    assert_equal "admin", admin.role
    assert_equal "project_manager", project_manager.role
    assert_equal "developer", developer.role
  end
  
  # GitHub integration tests
  test "github_connected? returns false when github_token is nil" do
    user = build(:user, github_token: nil)
    assert_not user.github_connected?
  end
  
  test "github_connected? returns false when github_token is blank" do
    user = build(:user, github_token: "")
    assert_not user.github_connected?
  end
  
  test "github_connected? returns true when github_token is present" do
    user = build(:user, github_token: "github_pat_123456789")
    assert user.github_connected?
  end
  
  test "github_token is encrypted" do
    token = "github_pat_123456789"
    user = create(:user, github_token: token)
    
    # Reload user from database
    user.reload
    
    # Token should be decrypted when accessed through the model
    assert_equal token, user.github_token
    
    # Direct SQL query should show the token is not stored in plaintext
    raw_token_from_db = ActiveRecord::Base.connection.execute(
      "SELECT github_token FROM users WHERE id = #{user.id}"
    ).first["github_token"]
us
    # puts "Token: #{token}"
    # puts "Raw token from DB: #{raw_token_from_db}"
    
    assert_not_equal token, raw_token_from_db
  end
end 