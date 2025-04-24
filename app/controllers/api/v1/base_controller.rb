module Api
  module V1
    class BaseController < ApplicationController
      around_action :log_db_queries, if: -> { Rails.env.development? }
      
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
          # Include related associations to prevent N+1 queries on commonly accessed user relationships
          User.includes(:owned_projects, :managed_projects).find_by(id: user_id)
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
      
      private
      
      # Log DB queries to identify N+1 problems in development
      def log_db_queries
        queries = []
        counter = 0
        
        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, _start, _finish, _id, payload|
          queries << payload[:sql] unless payload[:sql].include?('SCHEMA') || payload[:sql].include?('pg_catalog')
          counter += 1
        end
        
        yield
        
        ActiveSupport::Notifications.unsubscribe(subscriber)
        
        # Save to development log if there are more than 10 queries (potential N+1)
        if counter > 10
          Rails.logger.debug "========== N+1 Query Potential Detected =========="
          Rails.logger.debug "#{counter} queries executed for #{request.method} #{request.path}"
          Rails.logger.debug queries.join("\n")
          Rails.logger.debug "=================================================="
        end
      end
    end
  end
end 