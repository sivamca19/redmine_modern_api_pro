# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      skip_before_action :verify_authenticity_token
      skip_before_action :check_if_login_required

      rescue_from StandardError, with: :handle_standard_error
      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :handle_invalid_record
      rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing

      protected

      # Render success response
      def render_success(data = {}, message: nil, status: :ok)
        response = { success: true }
        response[:message] = message if message
        response.merge!(data)
        render json: response, status: status
      end

      # Render error response
      def render_error(message, error_code: nil, status: :bad_request, details: nil)
        response = {
          success: false,
          message: message
        }
        response[:error] = error_code if error_code
        response[:details] = details if details
        render json: response, status: status
      end

      # Find user by API key from header
      def find_user_by_api_key
        api_key = request.headers['X-Redmine-API-Key']
        if api_key.blank?
          render_error('API key is required', error_code: 'MISSING_API_KEY', status: :unauthorized)
          return nil
        end

        user = User.find_by_api_key(api_key)
        unless user
          render_error('Invalid API key', error_code: 'INVALID_API_KEY', status: :unauthorized)
          return nil
        end

        user
      end

      private

      # Handle 404 Not Found
      def handle_not_found(exception)
        render_error(
          exception.message,
          error_code: 'NOT_FOUND',
          status: :not_found
        )
      end

      # Handle validation errors
      def handle_invalid_record(exception)
        render_error(
          'Validation failed',
          error_code: 'VALIDATION_ERROR',
          status: :unprocessable_entity,
          details: exception.record.errors.full_messages
        )
      end

      # Handle missing parameters
      def handle_parameter_missing(exception)
        render_error(
          "Missing parameter: #{exception.param}",
          error_code: 'MISSING_PARAMETER',
          status: :bad_request
        )
      end

      # Handle generic errors
      def handle_standard_error(exception)
        Rails.logger.error "API Error: #{exception.class} - #{exception.message}"
        Rails.logger.error exception.backtrace.join("\n")

        render_error(
          'An unexpected error occurred',
          error_code: 'INTERNAL_ERROR',
          status: :internal_server_error
        )
      end
    end
  end
end
