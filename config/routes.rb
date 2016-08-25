Rails.application.routes.draw do

  resources :messages, only: [:create, :new]

  post 'messages/sms' => 'messages#receive_sms'

  resources :users, only: [:index, :show]

  get 'users/:id' => 'messages#receive_sms'


  devise_for :users
  root to: 'users#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
