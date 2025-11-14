# frozen_string_literal: true

module Api
  module V1
    class AuthController < BaseController
      accept_api_auth :login

      # POST /api/v1/login
      def login
        username = params[:username]
        password = params[:password]

        return render_error('Username and password are required', error_code: 'MISSING_CREDENTIALS') if username.blank? || password.blank?

        user = User.try_to_login(username, password)

        if user
          token = user.api_key
          render_success(
            {
              user: {
                id: user.id,
                login: user.login,
                firstname: user.firstname,
                lastname: user.lastname,
                mail: user.mail,
                admin: user.admin
              },
              api_token: token
            },
            message: 'Login successful'
          )
        else
          render_error('Invalid username or password', error_code: 'INVALID_CREDENTIALS', status: :unauthorized)
        end
      end

      # DELETE /api/v1/logout
      def logout
        user = find_user_by_api_key
        return unless user # Error already rendered by find_user_by_api_key

        # Regenerate the API token (invalidates current session but keeps token record)
        if user.api_token&.destroy && user.create_api_token(action: 'api')
          render_success(message: 'Logout successful')
        else
          render_error('Failed to logout', error_code: 'LOGOUT_FAILED', status: :internal_server_error)
        end
      end
    end
  end
end
