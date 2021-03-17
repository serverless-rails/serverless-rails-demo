class Document < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged

  belongs_to :user
  has_rich_text :body

  default_scope -> { order('updated_at desc') }
end
