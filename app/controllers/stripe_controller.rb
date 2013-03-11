class StripeController < ActionController::Base
  protect_from_forgery
  layout 'application'

  def index
    # intentionally blank
  end

  def create
    # set your secret key: remember to change this to your live secret key in production
    # see your keys here https://manage.stripe.com/account
    # NJS - will want to move this to a global somewhere that pulls values based on
    # test, development, or production environment
    Stripe.api_key = "sk_kGI38LpjtG08rZwNURQSbiniH0dAY"
    
    # get the credit card details submitted by the form
    token = params[:stripeToken]
    
    # create the charge on Stripe's servers - this will charge the user's card
    # NJS - move this to a background process
    @charge = Stripe::Charge.create(
                                  :amount => dollars_to_cents(params[:amount]),
                                  :currency => "usd",
                                  :card => token,
                                  :description => params[:description])
  end

end
