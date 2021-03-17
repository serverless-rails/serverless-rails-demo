class PublishWatchResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :last_notified_at
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :publisher
  attribute :watcher

  # Uncomment this to customize the display name of records in the admin area.
  def self.display_name(record)
    "#{record.publisher.name} watched by #{record.watcher.name}"
  end

  # Uncomment this to customize the default sort column and direction.
  # def self.default_sort_column
  #   "created_at"
  # end
  #
  # def self.default_sort_direction
  #   "desc"
  # end
end
