Rails.application.routes.draw do
  devise_for :users,
      controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  root to: 'pages#home'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :messages, only: [:create, :new]

  post 'messages/sms' => 'messages#receive_sms'

  resources :users, only: [:index, :show]

  get 'interface' => 'users#clean_show'
  post 'interface' => 'users#clean_show'
end
