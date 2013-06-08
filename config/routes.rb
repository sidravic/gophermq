Gophermq::Application.routes.draw do  
  devise_for :users

  resources :users do
    resources :projects
  end

  resources :projects, :only => [] do
    resources :queues, :except => [:destroy], :controller => "gopher_queues" do
      match "/:queue_name", :to => "gopher_queues#destroy", :via => :delete, :on => :collection
      match "/:queue_name/notify", :to => "gopher_queues#notify", :via => :put, :as => :notify, :on => :collection
      match "/:queue_name/denotify", :to => "gopher_queues#denotify", :via => :put, :as => :denotify, :on => :collection
      match "/:queue_name/subscribe", :to => "gopher_queues#subscribe", :via => :put, :as => :subscribe, :on => :collection
      match "/:queue_name/unsubscribe", :to => "gopher_queues#unsubscribe", :via => :put, :as => :unsubscribe, :on => :collection         

      match "/:queue_name/subscriptions", :to => "subscriptions#create", :via => :post, :as => :subscriptions, :on => :collection
      match "/:queue_name/subscriptions/:id", :to => "subscriptions#destroy", :via => :delete, :as => :subscription, :on => :collection
      match "/:queue_name/subscriptions", :to => "subscriptions#index", :via => :get, :as => :subscriptions, :on => :collection
    end
  end

  match "/queues/:queue_name/jobs", :to => "jobs#index", :via => :get, :as => :queue_jobs  
  match "/queues/:queue_name/jobs", :to => "jobs#create", :via => :post, :as => :queue_jobs
  match "/queues/:queue_name/jobs/:id", :to => "jobs#destroy", :via => :delete, :as => :queue_job
  match "/queues/:queue_name/jobs/:id/fetch", :to => "jobs#fetch", :via => :get, :as => :fetch_queue_job
  match "/queues/:queue_name/jobs/list", :to => "jobs#list", :via => :get, :as => :list_queue_jobs


  

  root :to => "home#welcome", :as => :root


  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
