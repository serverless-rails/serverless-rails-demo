class User < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  devise :confirmable, :database_authenticatable, :timeoutable,
         :registerable, :recoverable, :validatable, :async

  has_one_attached :avatar
  has_many :documents

  has_many :watchers, class_name: "PublishWatch", foreign_key: "publisher_id"
  has_many :watching, class_name: "PublishWatch", foreign_key: "watcher_id"

  def online?
    last_online_at && last_online_at > 10.minutes.ago
  end

  def watching?(publisher)
    PublishWatch.find_by(
      publisher: publisher,
      watcher: self
    )
  end
end
