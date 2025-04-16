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

  test "password must be at least 6 characters" do
    user = build(:user, password: "12345", password_confirmation: "12345")
    assert_not user.valid?
    assert_includes user.errors.full_messages, "Password is too short (minimum is 6 characters)"
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
    user = create(:user, password: "correct_password", password_confirmation: "correct_password")
    authenticated_user = User.authenticate(user.email, "correct_password")
    assert_equal user, authenticated_user
  end
  
  test "does not authenticate with invalid credentials" do
    user = create(:user, password: "correct_password", password_confirmation: "correct_password")
    authenticated_user = User.authenticate(user.email, "wrong_password")
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
end 