class PublishWatch < ApplicationRecord
  belongs_to :publisher, class_name: "User"
  belongs_to :watcher, class_name: "User"

  def cutoff
    last_notified_at || created_at
  end
end
