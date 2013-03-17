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
    provider :facebook, '547638578609734', '6e1d9d7592121d86a5b531c15130cf25'
  end
end

OmniAuth.config.logger = Rails.logger
