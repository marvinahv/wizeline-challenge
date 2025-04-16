module Api
  module V1
    class BaseController < ApplicationController
      protected
      
      # Returns current authenticated user or nil
      def current_user
        @current_user ||= authenticate_user_from_token
      end
      
      # Checks if user is authenticated
      def authenticate_user!
        unless current_user
          render json: { error: 'Unauthorized' }, status: :unauthorized
        end
      end
      
      # Authenticate user from JWT token in Authorization header
      def authenticate_user_from_token
        token = extract_token_from_header
        return nil unless token
        
        begin
          decoded_token = JWT.decode(
            token,
            Rails.application.credentials.secret_key_base,
            true,
            { algorithm: 'HS256' }
          )
          
          user_id = decoded_token.first['user_id']
          User.find_by(id: user_id)
        rescue JWT::DecodeError, JWT::ExpiredSignature
          nil
        end
      end
      
      # Extract JWT token from Authorization header
      def extract_token_from_header
        header = request.headers['Authorization']
        header&.split(' ')&.last
      end
      
      # Check if user has required role
      def authorize_role!(roles)
        unless current_user && Array(roles).include?(current_user.role)
          render json: { error: 'Forbidden' }, status: :forbidden
        end
      end
    end
  end
end 