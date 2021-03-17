class PublishWatchesController < ApplicationController
  before_action :set_user
  before_action :get_current_publish_watch

  def subscribe
    if @pw
      redirect_to profile_path(@user), alert: "You are already subscribed."
    else
      @pw = PublishWatch.create(
        publisher: @user,
        watcher: current_user
      )
      redirect_to profile_path(@user), notice: "Subscribed to new and updated documents from #{@user.name}."
    end
  end

  def unsubscribe
    if !@pw
      redirect_to profile_path(@user), alert: "You weren't subscribed."
    else
      @pw.destroy
      redirect_to profile_path(@user), notice: "Unsubscribed from #{@user.name}'s updates."
    end
  end

  private
    def set_user
      @user = User.friendly.find(params[:profile_id])
    end

    def get_current_publish_watch
      @pw = PublishWatch.find_by(
        publisher: @user,
        watcher: current_user
      )
    end
end
