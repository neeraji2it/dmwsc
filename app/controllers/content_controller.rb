# NJS - figure out a better way to serve up static content
class ContentController < ApplicationController
  protect_from_forgery
  layout 'application'

  before_filter :login_required

  def index
    # intentionally blank
  end

end
