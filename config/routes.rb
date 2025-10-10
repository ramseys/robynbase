Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  
  resources :sessions, only: [:new, :create, :destroy]
  get 'map/index'
  get "robyn/index"
  get "songs/index"
  get "songs/quick_query"
  get "gigs/index"
  get "gigs/quick_query"
  get "gigs/on_this_day"
  get "venues/index"
  get "venues/quick_query"
  get "robyn/search_venues"
  get "compositions/index"
  get "compositions/quick_query"
  get "robyn/search"
  get "robyn/search_gigs"
  get "robyn/search_compositions"
  
  # get 'signup', to: 'users#new', as: 'signup'
  get 'login', to: 'sessions#new', as: 'login'
  get 'logout', to: 'sessions#destroy', as: 'logout'
  
  resources :songs do
    collection do
      get :infinite_scroll
    end
  end
  resources :gigs do
    collection do
      get :for_resource
      get :infinite_scroll
    end
  end
  resources :venues do
    collection do
      get :infinite_scroll
    end
  end
  resources :compositions do
    collection do
      get :for_resource
      get :infinite_scroll
    end
  end
  resources :about
  resources :map


  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'robyn#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
