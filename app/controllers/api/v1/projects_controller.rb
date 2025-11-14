# frozen_string_literal: true

module Api
  module V1
    class ProjectsController < BaseController
      before_action :authenticate_user

      # GET /api/v1/projects
      def index
        projects = @current_user.projects.active.includes(:parent)

        # Apply filters if provided
        projects = projects.where(status: params[:status]) if params[:status].present?
        projects = projects.where('name LIKE ?', "%#{params[:search]}%") if params[:search].present?

        # Sorting
        sort_column = params[:sort_by] || 'name'
        sort_direction = params[:sort_direction] || 'asc'
        projects = projects.order("#{sort_column} #{sort_direction}")

        # Pagination
        page = params[:page]&.to_i || 1
        per_page = params[:per_page]&.to_i || 25
        per_page = 100 if per_page > 100 # Max limit

        offset = (page - 1) * per_page
        total_count = projects.count
        projects = projects.limit(per_page).offset(offset)

        projects_data = projects.map do |project|
          format_project(project)
        end

        render_success(
          {
            projects: projects_data,
            pagination: {
              page: page,
              per_page: per_page,
              total_count: total_count,
              total_pages: (total_count.to_f / per_page).ceil
            }
          },
          message: 'Projects loaded successfully'
        )
      end

      # GET /api/v1/projects/:id
      def show
        project = @current_user.projects.find_by(identifier: params[:id])
        return render_error('Project not found', error_code: 'PROJECT_NOT_FOUND', status: :not_found) unless project

        project_data = format_project_detail(project)
        render_success({ project: project_data }, message: 'Project loaded successfully')
      end

      # GET /api/v1/projects/:id/custom_fields
      def custom_fields
        project = @current_user.projects.find_by(identifier: params[:id])
        return render_error('Project not found', error_code: 'PROJECT_NOT_FOUND', status: :not_found) unless project

        # Get all custom fields for issues in this project
        issue_custom_fields = project.all_issue_custom_fields

        custom_fields_data = issue_custom_fields.map do |cf|
          format_custom_field(cf)
        end

        # Separate mandatory and optional fields
        mandatory_fields = custom_fields_data.select { |cf| cf[:is_required] }
        # optional_fields = custom_fields_data.reject { |cf| cf[:is_required] }

        render_success(
          {
            # custom_fields: custom_fields_data,
            mandatory_fields: mandatory_fields,
            # optional_fields: optional_fields
          },
          message: 'Custom fields loaded successfully'
        )
      end

      private

      def authenticate_user
        @current_user = find_user_by_api_key
        return unless @current_user
      end

      def format_project(project)
        {
          id: project.id,
          name: project.name,
          identifier: project.identifier,
          description: project.description&.truncate(200),
          status: project.status,
          is_public: project.is_public,
          parent_id: project.parent_id,
          parent_name: project.parent&.name,
          created_on: project.created_on,
          updated_on: project.updated_on,
          homepage: project.homepage,
          # Stats
          issues_count: project.issues.count,
          open_issues_count: project.issues.open.count,
          members_count: project.members.count
        }
      end

      def format_custom_field(custom_field)
        {
          id: custom_field.id,
          name: custom_field.name,
          field_format: custom_field.field_format,
          is_required: custom_field.is_required,
          is_filter: custom_field.is_filter,
          searchable: custom_field.searchable,
          visible: custom_field.visible,
          multiple: custom_field.multiple,
          default_value: custom_field.default_value,
          description: custom_field.description,
          # Possible values for list/select fields
          possible_values: custom_field.possible_values,
          # For validation
          min_length: custom_field.min_length,
          max_length: custom_field.max_length,
          regexp: custom_field.regexp,
          # Field type specific info
          field_type_info: get_field_type_info(custom_field)
        }
      end

      def get_field_type_info(custom_field)
        case custom_field.field_format
        when 'list'
          { type: 'select', options: custom_field.possible_values }
        when 'bool'
          { type: 'boolean', options: ['true', 'false'] }
        when 'date'
          { type: 'date', format: 'YYYY-MM-DD' }
        when 'int'
          { type: 'integer' }
        when 'float'
          { type: 'float' }
        when 'text'
          { type: 'textarea' }
        when 'string'
          { type: 'text_input' }
        when 'link'
          { type: 'url' }
        when 'user'
          { type: 'user_select' }
        when 'version'
          { type: 'version_select' }
        else
          { type: custom_field.field_format }
        end
      end

      def format_project_detail(project)
        {
          id: project.id,
          name: project.name,
          identifier: project.identifier,
          description: project.description,
          status: project.status,
          is_public: project.is_public,
          parent_id: project.parent_id,
          parent_name: project.parent&.name,
          created_on: project.created_on,
          updated_on: project.updated_on,
          homepage: project.homepage,
          # Detailed stats
          issues_count: project.issues.count,
          open_issues_count: project.issues.open.count,
          closed_issues_count: project.issues.where(status_id: IssueStatus.where(is_closed: true).pluck(:id)).count,
          members_count: project.members.count,
          # Trackers
          trackers: project.trackers.map { |t| { id: t.id, name: t.name } },
          # Issue categories
          issue_categories: project.issue_categories.map { |c| { id: c.id, name: c.name } },
          # Versions
          versions: project.versions.map { |v| { id: v.id, name: v.name, status: v.status, due_date: v.due_date } },
          # Custom fields
          custom_fields: project.visible_custom_field_values.map do |cfv|
            {
              id: cfv.custom_field.id,
              name: cfv.custom_field.name,
              value: cfv.value
            }
          end
        }
      end
    end
  end
end
