require 'yaml'

class ApiDocsController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def swagger
    swagger_root = Rails.root.join('plugins', 'redmine_modern_api_pro', 'swagger', 'v1')

    # Load components first
    components_file = File.join(swagger_root, 'components.yaml')
    components = File.exist?(components_file) ? YAML.load_file(components_file)['components'] : {}

    # Load all other YAMLs (login, logout, etc.)
    api_files = Dir[File.join(swagger_root, '*.yaml')].reject { |f| f.include?('components.yaml') }
    merged_paths = {}

    api_files.each do |file|
      yaml_content = YAML.load_file(file)
      merged_paths.merge!(yaml_content['paths'] || {})
    end

    swagger_doc = {
      openapi: '3.0.3',
      info: {
        title: 'Redmine Modern API Plugin',
        version: 'v1',
        description: 'API documentation for Redmine Modern API Plugin'
      },
      servers: [
        { url: 'http://localhost:3000', description: 'Local Development' },
        { url: request.base_url, description: 'Current Server' }
      ],
      paths: merged_paths,
      components: components
    }

    render json: swagger_doc
  end
end