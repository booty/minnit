class SessionsController < ApplicationController
  def new
  end

  def create
    member = Member.active.find_by("LOWER(email) = LOWER(?)", params[:email])
    if member&.authenticate(params[:password])
      session[:member_id] = member.id
      redirect_to root_path, notice: "Welcome back, #{member.display_name}!"
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:member_id)
    redirect_to root_path, notice: "Logged out."
  end
end
