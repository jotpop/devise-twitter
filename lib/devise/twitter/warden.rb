Warden::OAuth.access_token_user_finder(:twitter) do |access_token|
  twitter_handle = access_token.params[:screen_name]
  klass = @env['devise.mapping'].class_name.constantize

  already_existing_user = klass.find_by_twitter_handle(twitter_handle)
  previous_user = @env['warden'].user

  # If the user already exist, simply log him in
  if not already_existing_user.blank?
    session["warden.#{@scope}.twitter.connected_user.key"] = already_existing_user.id
    return already_existing_user
  end

  # If there is another user logged who has no twitter handle, merge the accounts 
  user = previous_user if previous_user.present? and previous_user.twitter_handle.nil?
  
  if user.nil?
      # Try to find user by token
      user = klass.find_by_twitter_oauth_token_and_twitter_oauth_secret(access_token.token, access_token.secret)

      # Create user if we don't know him yet
      user = klass.new unless user.present?

      # Since we are logging in a new user we want to make sure the before_logout hook is called
      @env['warden'].logout if previous_user.present?
  end

  user.twitter_handle = twitter_handle
  user.twitter_oauth_token = access_token.token
  user.twitter_oauth_secret = access_token.secret
  user.save
  
  session["warden.#{@scope}.twitter.connected_user.key"] = user.id
  return user
end

