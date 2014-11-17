require 'dashing'
$username = 'username'
$password = 'password'

configure do
  set :auth_token, '1a2b3c4d5e'

  helpers do
    def protected!
     unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="RestrictedArea")
      throw(:halt, [401, "Not authorized\n"])
     end
    end

    def authorized?
     @auth ||= Rack::Auth::Basic::Request.new(request.env)
     @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [$username,$password]
    end
 end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application
