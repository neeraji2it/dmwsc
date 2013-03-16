Stripetest::Application.routes.draw do
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

  root :to => 'content#index'
  
  resources :stripe do
    resources :index
  end

  resources :seat_reservations, :only => [:create, :update]
  resources :hails, :only => [:create] do
    member do
      put :mark_done
      get :mark_done
    end
  end
  # manually route puts to hails controller to update so don't need the id
  # as the default update does.
  match 'hails' => 'hails#update', :via => :put

  namespace :admin do
    resources :seat_reservations, :only => [:index, :update]
    resources :customer, :only => [:index] do 
      collection do
       get :login_as
      end
    end
    resources :hails, :only => [:index, :update]
    resources :session, :only => [:new, :create, :destroy]
    resources :dashboard, :only => [:index] do 
      collection do
       post :fetch_users
       get :customer_dashboard
      end
    end
  end
  match '/admin' => "admin/session#new"
   match '/admin/logout' => "admin/session#destroy"
  # authentication stuff
  match 'auth/:provider/callback', to: 'sessions#create'
  match 'auth/failure', to: redirect('/')
  match 'signout', to: 'sessions#destroy', as: 'signout'

  match ':controller(/:action(/:id))'
  match ':controller(/:action(/:id))', :controller => /admin\/[^\/]+/
end
