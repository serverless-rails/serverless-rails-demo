class PresenceChannel < ApplicationCable::Channel
  def subscribed
    stream_from "presence:users"
  end

  def unsubscribed
    if current_user
      current_user.update(last_online_at: nil)
      broadcast_to "users", { id: current_user.id, status: "offline" }
    end
  end

  def heartbeat
    if current_user
      was_online = current_user.online?
      Rails.logger.info "IDENTIFIED AS #{current_user.email} (online already? #{was_online})"
      current_user.update(last_online_at: Time.now)
      if !was_online
        broadcast_to "users", { id: current_user.id, status: "online" }
      end
    else
      Rails.logger.error "Unauthenticated user trying to heartbeat..."
    end
  end
end
