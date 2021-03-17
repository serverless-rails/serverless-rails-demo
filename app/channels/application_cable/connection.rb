module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = env['warden'].user(:user)
      Rails.logger.info "Cable authentication: #{self.current_user ? self.current_user.email : "ANONYMOUS"}"
    end
  end
end
