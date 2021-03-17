class DocumentChannel < ApplicationCable::Channel
  def subscribed
    stream_from "document:updates"
  end
end
