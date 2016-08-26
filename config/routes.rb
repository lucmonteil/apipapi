Rails.application.routes.draw do

  resources :messages, only: [:create, :new]

  post 'messages/sms' => 'messages#receive_sms'


  resources :users, only: [:index, :show]

  devise_for :users,
    controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }

  root to: 'pages#home'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
