# NJS - use trick here to use two different sets of keys
# http://stackoverflow.com/questions/4532721/facebook-development-in-localhost


if Rails.env == 'development' || Rails.env == 'test'
  # development for local host
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :facebook, '482351791819327', '95b272b1a22849438af4f8fdfacade44'
  end
else
  Rails.application.config.middleware.use OmniAuth::Builder do
    # "production" for testing env (http://desolate-everglades-3115.herokuapp.com)
    provider :facebook, '226062270873991', '091b53e32234b2bd51d54c5f8b1a6344'
  end
end

OmniAuth.config.logger = Rails.logger
