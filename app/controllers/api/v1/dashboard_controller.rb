# frozen_string_literal: true

module Api
  module V1
    class DashboardController < BaseController
      before_action :authenticate_user
      before_action :find_project, only: [:project_dashboard]

      # GET /api/v1/dashboard
      def index
        dashboard_data = {
          summary: user_summary,
          my_issues: my_issues_stats,
          recent_activity: recent_activity_data
        }

        render_success(dashboard_data, message: 'Dashboard loaded successfully')
      end

      # GET /api/v1/dashboard/project/:project_id
      def project_dashboard
        dashboard_data = {
          project: project_summary,
          issues_by_status: issues_by_status_chart,
          issues_by_tracker: issues_by_tracker_chart,
          issues_by_priority: issues_by_priority_chart,
          issues_by_assignee: issues_by_assignee_chart,
          issues_timeline: issues_timeline_chart,
          activity_chart: project_activity_chart,
          completion_rate: project_completion_rate
        }

        render_success(dashboard_data, message: 'Project dashboard loaded successfully')
      end

      private

      def authenticate_user
        @current_user = find_user_by_api_key
        return unless @current_user
      end

      def find_project
        @project = Project.find_by(identifier: params[:project_id])
        return render_error('Project not found', error_code: 'PROJECT_NOT_FOUND', status: :not_found) unless @project
        return render_error('Access denied', error_code: 'ACCESS_DENIED', status: :forbidden) unless @current_user.allowed_to?(:view_issues, @project)
      end

      # User summary stats
      def user_summary
        {
          total_issues: Issue.where(assigned_to_id: @current_user.id).count,
          open_issues: Issue.open.where(assigned_to_id: @current_user.id).count,
          overdue_issues: Issue.open.where(assigned_to_id: @current_user.id).where('due_date < ?', Date.today).count,
          projects_count: @current_user.projects.active.count
        }
      end

      # My issues statistics
      def my_issues_stats
        {
          by_status: Issue.where(assigned_to_id: @current_user.id)
                          .joins(:status)
                          .group('issue_statuses.name')
                          .count,
          by_priority: Issue.where(assigned_to_id: @current_user.id)
                            .joins(:priority)
                            .group('enumerations.name')
                            .count
        }
      end

      # Recent activity
      def recent_activity_data
        journals = Journal.includes(:user, :issue)
                         .where(issues: { assigned_to_id: @current_user.id })
                         .order(created_on: :desc)
                         .limit(10)

        journals.map do |journal|
          {
            id: journal.id,
            issue_id: journal.issue.id,
            issue_subject: journal.issue.subject,
            user: journal.user.name,
            created_at: journal.created_on,
            notes: journal.notes
          }
        end
      end

      # Project summary
      def project_summary
        {
          id: @project.id,
          name: @project.name,
          description: @project.description,
          status: @project.status,
          total_issues: @project.issues.count,
          open_issues: @project.issues.open.count,
          closed_issues: @project.issues.where(status_id: IssueStatus.where(is_closed: true).pluck(:id)).count
        }
      end

      # Issues by status chart data
      def issues_by_status_chart
        data = @project.issues
                      .joins(:status)
                      .group('issue_statuses.name')
                      .count

        {
          type: 'pie',
          title: 'Issues by Status',
          labels: data.keys,
          data: data.values,
          colors: generate_colors(data.size)
        }
      end

      # Issues by tracker chart data
      def issues_by_tracker_chart
        data = @project.issues
                      .joins(:tracker)
                      .group('trackers.name')
                      .count

        {
          type: 'doughnut',
          title: 'Issues by Tracker',
          labels: data.keys,
          data: data.values,
          colors: generate_colors(data.size)
        }
      end

      # Issues by priority chart data
      def issues_by_priority_chart
        data = @project.issues
                      .joins(:priority)
                      .group('enumerations.name', 'enumerations.position')
                      .order('enumerations.position')
                      .count
                      .transform_keys { |k| k.first } # Extract just the name from [name, position]

        {
          type: 'bar',
          title: 'Issues by Priority',
          labels: data.keys,
          data: data.values,
          colors: ['#dc3545', '#fd7e14', '#ffc107', '#28a745', '#17a2b8']
        }
      end

      # Issues by assignee chart data
      def issues_by_assignee_chart
        data = @project.issues
                      .joins('LEFT JOIN users ON issues.assigned_to_id = users.id')
                      .group('COALESCE(users.login, \'Unassigned\')')
                      .count
                      .sort_by { |_, v| -v }
                      .first(10)
                      .to_h

        {
          type: 'horizontal_bar',
          title: 'Top 10 Assignees',
          labels: data.keys,
          data: data.values,
          colors: generate_colors(data.size)
        }
      end

      # Issues timeline chart (last 30 days)
      def issues_timeline_chart
        start_date = 30.days.ago.to_date
        end_date = Date.today

        created_data = @project.issues
                              .where('created_on >= ?', start_date)
                              .group('DATE(created_on)')
                              .count

        closed_data = @project.issues
                             .where('closed_on >= ?', start_date)
                             .where.not(closed_on: nil)
                             .group('DATE(closed_on)')
                             .count

        dates = (start_date..end_date).to_a
        labels = dates.map { |d| d.strftime('%m/%d') }

        {
          type: 'line',
          title: 'Issues Timeline (Last 30 Days)',
          labels: labels,
          datasets: [
            {
              label: 'Created',
              data: dates.map { |d| created_data[d.to_s] || 0 },
              color: '#28a745',
              fill: false
            },
            {
              label: 'Closed',
              data: dates.map { |d| closed_data[d.to_s] || 0 },
              color: '#6c757d',
              fill: false
            }
          ]
        }
      end

      # Project activity chart (last 7 days)
      def project_activity_chart
        start_date = 7.days.ago.to_date
        end_date = Date.today

        activity_data = Journal.joins(:issue)
                              .where(issues: { project_id: @project.id })
                              .where('journals.created_on >= ?', start_date)
                              .group('DATE(journals.created_on)')
                              .count

        dates = (start_date..end_date).to_a
        labels = dates.map { |d| d.strftime('%a %m/%d') }

        {
          type: 'bar',
          title: 'Activity (Last 7 Days)',
          labels: labels,
          data: dates.map { |d| activity_data[d.to_s] || 0 },
          colors: ['#007bff']
        }
      end

      # Project completion rate
      def project_completion_rate
        total = @project.issues.count
        return { percentage: 0, total: 0, completed: 0 } if total.zero?

        completed = @project.issues.where(status_id: IssueStatus.where(is_closed: true).pluck(:id)).count
        percentage = ((completed.to_f / total) * 100).round(2)

        {
          type: 'progress',
          title: 'Overall Completion',
          percentage: percentage,
          total: total,
          completed: completed,
          remaining: total - completed
        }
      end

      # Generate colors for charts
      def generate_colors(count)
        base_colors = ['#007bff', '#28a745', '#dc3545', '#ffc107', '#17a2b8', '#6c757d', '#fd7e14', '#6f42c1', '#e83e8c', '#20c997']
        (base_colors * ((count / base_colors.size) + 1)).first(count)
      end
    end
  end
end
