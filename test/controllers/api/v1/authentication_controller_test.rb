require 'test_helper'

class Api::V1::AuthenticationControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, password: "Password1!", password_confirmation: "Password1!")
  end

  test "should authenticate user with valid credentials" do
    post api_v1_auth_login_path, params: { 
      email: @user.email, 
      password: "Password1!" 
    }, as: :json

    assert_response :success
    
    # Verify response structure
    json_response = JSON.parse(response.body)
    assert_not_nil json_response['token']
    assert_not_nil json_response['user']
    assert_equal @user.id, json_response['user']['id']
    assert_equal @user.name, json_response['user']['name']
    assert_equal @user.email, json_response['user']['email']
    assert_equal @user.role, json_response['user']['role']
    
    # Password should not be included
    assert_nil json_response['user']['password_digest']
  end

  test "should not authenticate user with invalid credentials" do
    post api_v1_auth_login_path, params: { 
      email: @user.email, 
      password: "WrongPassword1!" 
    }, as: :json

    assert_response :unauthorized
    
    json_response = JSON.parse(response.body)
    assert_equal "Invalid email or password", json_response['error']
  end

  test "should not authenticate with missing credentials" do
    post api_v1_auth_login_path, params: {}, as: :json

    assert_response :unprocessable_entity
    
    json_response = JSON.parse(response.body)
    assert_includes json_response['errors'], "Email can't be blank"
    assert_includes json_response['errors'], "Password can't be blank"
  end
end 