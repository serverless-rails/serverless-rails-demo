class UserResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :email
  attribute :name
  attribute :admin
  attribute :created_at, form: false
  attribute :last_online_at

  # Associations
  attribute :documents
  attribute :watchers
  attribute :watching

  # Uncomment this to customize the display name of records in the admin area.
  def self.display_name(record)
    record.name
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
