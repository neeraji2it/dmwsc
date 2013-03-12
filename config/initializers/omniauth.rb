# NJS - use trick here to use two different sets of keys
# http://stackoverflow.com/questions/4532721/facebook-development-in-localhost


if Rails.env == 'development' || Rails.env == 'test'
  # development for local host
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :facebook, '150429211787403', '46c56bf9ada50837f4c53c5432f04267'
  end
else
  Rails.application.config.middleware.use OmniAuth::Builder do
    # "production" for testing env (http://desolate-everglades-3115.herokuapp.com)
    provider :facebook, '226062270873991', '091b53e32234b2bd51d54c5f8b1a6344'
  end
end

OmniAuth.config.logger = Rails.logger
