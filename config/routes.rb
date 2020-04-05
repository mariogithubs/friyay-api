Rails.application.routes.draw do
  mount_griddler

  require 'sidekiq/web'
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == ENV['SIDEKIQ_USERNAME'] && password == ENV['SIDEKIQ_PASSWORD']
  end if Rails.env.production? || Rails.env.staging?
  mount Sidekiq::Web, at: '/sidekiq'

  use_doorkeeper
  devise_for :users
  # root 'welcome#index'

  post 'zencoder-callback' => 'zencoder_callback#create', as: 'zencoder_callback'
  # post 'v2/saml/auth' => 'v2/saml#auth'
  post 'v2/saml/relay' => 'v2/saml#relay'
  # post 'v2/saml/logout' => 'v2/saml#logout'
  get 'v2/saml/metadata' => 'v2/saml#metadata'

  namespace :v2, defaults: { format: :json }, constraints: { subdomain: /api|tiphive-api/ } do
    resources :domain_roles, only: :index
    resources :contexts, only: [:index, :create, :destroy]

    resources :saml do
      collection do
        get :init
        post :auth
        post :logout
      end
    end

    resources :slack do
      collection do
        post :auth
        post :login
        post :get_user_details
        post :connect
        post :get_slack_data
        post :create_topic_connection
        post :update_topic_connection
        post :remove_topic_connection
        post :add_card
        post :disconnect_from_slack
      end
    end

    resource :registrations do
      collection do
        get :confirm
      end
    end

    resources :tiphive_bot, only: [] do
      collection do
        get :get_tiphive_bot_data
        post :get_users_and_topics
        post :get_bot_data_using_command
      end
    end

    resource :passwords
    resource :sessions

    get '/me' => 'users#me'
    post :decode_token, to: 'users#decode_token'

    get '/domains/:tenant_name/show', to: 'domains#show'
    post '/domains/:tenant_name/join', to: 'domains#join'
    post '/domains/remove_user', to: 'domains#remove_user'
    post '/domains/add_user', to: 'domains#add_user'
    resources :domains, only: [:index, :show, :create, :update] do
      collection do
        get :search
      end

      member do
        post :delete_hive
        post :archive_hive
      end
    end

    resources :users do
      resource :domain_roles, only: :update
    end

    resources :users do
      resources :tips

      resources :user_profile, only: [:show, :create]

      collection do
        get :explore
        post :follow_all
      end

      member do
        post :follow
        post :unfollow
        post :update_order
        get  :follows
      end
    end

    resources :roles, only: [] do
      collection do
        post :remove
      end
    end

    resources :topics, only: [:index, :show, :create, :update, :destroy] do
      resources :roles, only: [] do
        collection do
          post :remove
        end
      end

      resources :tips

      collection do
        get :explore
        get :suggested_topics
      end

      member do
        post :share_with_relationships
        post :join
        post :leave
        post :star
        post :unstar
        get :explore_people
        post :move
        post :reorder
      end
    end

    resources :cards, only: [:create, :update]

    resources :subscriptions, only: [:create, :update, :show] do
      collection do
       post :upgrade_request
      end
      member do
        post :update_plan
      end
    end

    resources :transactions, only: [:index, :show] do
      member do
        get "pdf"
      end
    end

    resources :contact_information, only: [:create, :update, :show] do
      collection do
        get "countries"
        get "states"
      end
    end

    resources :attachments, only: [:index, :show, :create, :destroy]

    resources :tip_links, only: [:show, :destroy]

    resources :tips, only: [:index, :show, :create, :update, :destroy] do
      resources :comments, only: [:create, :index]

      resources :topic_assignments, only: [:create] do
        collection do
          post :move
        end
      end

      collection do
        get :index_all
        get :assigned_to
        get '/versions/:id', to: 'tips#fetch_versions'
      end

      member do
        post :share_with_relationships
        post :like
        post :unlike
        post :star
        post :unstar
        post :upvote
        post :downvote
        post :flag
        post :reorder
        post :archive
        post :unarchive
      end
      resources :attachments, only: [:index, :show, :create, :destroy]

      post '/tip_links/fetch', to: 'tip_links#fetch'
    end

    resources :comments, only: [:create, :show, :update, :destroy] do
      member do
        post :flag
        post :reply
      end
    end

    resources :groups, only: [:index, :show, :create, :update, :destroy] do
      resources :group_memberships, only: [:index, :create, :destroy]

      member do
        post :join
        post :request_invitation
        get  :follows
      end
    end

    resources :invitations, only: [:create, :show, :index] do
      collection do
        get :reinvite
        post :search
        post :request_invitation
      end

      member do
        get :connect
      end
    end

    resources :tip_assignments, only: [:create]

    resources :view_assignments, only: [:create]


    resources :connections, only: [:create, :index]
    post '/connections/update', to: 'connections#update'
    delete '/connections', to: 'connections#destroy'

    resources :search, only: [:index]
    resources :sharing_items, only: [:index], defaults: { format: :json }
    patch '/notifications/mark_as_read' => 'notifications#mark_as_read'
    resources :notifications, only: [:index]

    namespace :slack do
      resources :search, only: [:create]
    end

    resources :dashboard, only: [:index]

    resources :label_assignments, except: [:new, :edit]
    resources :labels
    resources :label_categories

    resources :views, only: [:index]
    resources :label_orders
    resources :people_orders

    resources :orders
    resources :topic_orders

    post '/bulk_actions/archive', to: 'bulk_actions#archive'
    post '/bulk_actions/organize', to: 'bulk_actions#organize'
    post '/bulk_actions/share', to: 'bulk_actions#share'
  end
  
  namespace :v2, defaults: { format: :json } do
    namespace :slack do
      resources :slash, only: [:create] do
        collection do
          post :interactive
          post :load_options
          post :add_card
        end
      end
    end
  end

  get '/rmp', to: 'pages#mini_profiler'

  get '*unmatched_route', to: 'application#raise_not_found!'
  post '*unmatched_route', to: 'application#raise_not_found!'
  put '*unmatched_route', to: 'application#raise_not_found!'
  delete '*unmatched_route', to: 'application#raise_not_found!'
end
