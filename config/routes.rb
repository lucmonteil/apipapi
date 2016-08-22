Rails.application.routes.draw do
  get 'messages/reply'

  resource :messages do
    collection do
      post 'reply'
    end
  end


  devise_for :users
  root to: 'pages#home'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
