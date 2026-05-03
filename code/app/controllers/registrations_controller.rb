class RegistrationsController < ApplicationController
  def new
    @member = Member.new
  end

  def create
    @member = Member.new(member_params)
    if @member.save
      session[:member_id] = @member.id
      redirect_to root_path, notice: "Welcome, #{@member.display_name}!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def member_params
    params.require(:member).permit(:display_name, :email, :password)
  end
end
