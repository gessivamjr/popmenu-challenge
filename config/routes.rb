Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "restaurant#index"

  resources :restaurant, only: %i[index show create update destroy] do
    resources :menu, only: %i[index show create update destroy] do
      resources :menu_item, only: %i[index show create update destroy]
    end
  end

  post "restaurant/import", to: "restaurant_import#import"
end
