module Api
  module V1
    class AuthenticationController < BaseController
      # POST /api/v1/auth/login
      def login
        # Validate request parameters
        unless params[:email].present? && params[:password].present?
          errors = []
          errors << "Email can't be blank" unless params[:email].present?
          errors << "Password can't be blank" unless params[:password].present?
          
          return render json: { errors: errors }, status: :unprocessable_entity
        end
        
        # Authenticate user
        user = User.authenticate(params[:email], params[:password])
        
        if user
          # Generate JWT token
          token = user.generate_jwt
          
          # Return user data and token
          render json: {
            token: token,
            user: {
              id: user.id,
              name: user.name,
              email: user.email,
              role: user.role
            }
          }, status: :ok
        else
          # Authentication failed
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end
    end
  end
end 