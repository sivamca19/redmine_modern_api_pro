RedmineApp::Application.routes.draw do
  namespace :api do
    namespace :v1 do
      post 'login', :to => 'auth#login'
      delete 'logout', :to => 'auth#logout'

      get 'dashboard', :to => 'dashboard#index'
      get 'dashboard/project/:project_id', :to => 'dashboard#project_dashboard'

      get 'projects', :to => 'projects#index'
      get 'projects/:id', :to => 'projects#show'
      get 'projects/:id/custom_fields', :to => 'projects#custom_fields'
    end
  end

  get '/api-docs/v1/swagger.json', to: 'api_docs#swagger'
  mount Rswag::Ui::Engine => '/api-docs'
end