class Admin::HailsController < ApplicationController
  protect_from_forgery
  layout 'admin'

  # NJS - make sure user is logged in as an internal_user

  def index
    # intentionally blank
  end

  # staff can only mark them as done
  def update
    h = Hail.find(params[:id])
    # NJS - make sure sr isn't already closed

    h.mark_done!(InternalUser.find(1))

    # NJS - what to return back? just a success msg?
    respond_to do |format|
      format.html { 
        flash[:notice] = "hail marked as done"
        redirect_to :action => :index
      }
    end
  end

end
