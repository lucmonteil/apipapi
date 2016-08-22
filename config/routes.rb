Rails.application.routes.draw do

  resources :messages, only: [:create, :new]

  resources :users, only: [:index, :show]

  devise_for :users
  root to: 'users#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
