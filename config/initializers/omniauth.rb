# NJS - use trick here to use two different sets of keys
# http://stackoverflow.com/questions/4532721/facebook-development-in-localhost


if Rails.env == 'development' || Rails.env == 'test'
  # development for local host
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :facebook, '151278968367725', '20f2283e41f3cf106a803232ba8c58f8'
  end
else
  Rails.application.config.middleware.use OmniAuth::Builder do
    # "production" for testing env (http://desolate-everglades-3115.herokuapp.com)
    provider :facebook, '427462840668798', '179811dcfa381b590feffbb59eb260cc'
  end
end

OmniAuth.config.logger = Rails.logger
