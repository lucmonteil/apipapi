class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def uber
    user = User.find_for_uber_oauth(request.env['omniauth.auth'])

    if user.persisted?
      sign_in_and_redirect user, event: :authentication
      set_flash_message(:notice, :success, kind: 'Uber') if is_navigational_format?
    else
      session['devise.uber_data'] = request.env['omniauth.auth']
      redirect_to new_user_registration_url
    end
  end
end
