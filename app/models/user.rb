class User < ApplicationRecord
  has_many :messages, dependent: :destroy
  has_many :requests, dependent: :destroy
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable
  devise :recoverable, :rememberable, :trackable, :validatable
  devise :omniauthable, omniauth_providers: [:uber]

  def self.find_for_uber_oauth(auth)
    user_params = auth.to_h.slice("provider", "uid")
    user_params.merge! auth.info.slice(:email, :first_name)
    user_params[:uber_picture] = auth.info.picture
    user_params[:uber_token] = auth.credentials.token
    user_params[:uber_refresh_token] = auth.credentials.refresh_token
    user_params[:expires] = auth.credentials.expires

    user = User.where(provider: auth.provider, uid: auth.uid).first
    user ||= User.where(email: auth.info.email).first # User did a regular sign up in the past.
    if user
      user.update(user_params)
    else
      user = User.new(user_params)
      user.password = Devise.friendly_token[0,20]  # Fake password for validation
      user.save
    end

    return user
  end
end
