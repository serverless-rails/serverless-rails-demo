class CreatePublishWatches < ActiveRecord::Migration[6.1]
  def change
    create_table :publish_watches do |t|
      t.references :publisher, null: false
      t.references :watcher, null: false
      t.datetime :last_notified_at

      t.timestamps
    end

    add_foreign_key :publish_watches, :users, column: :publisher_id, primary_key: :id
    add_foreign_key :publish_watches, :users, column: :watcher_id, primary_key: :id
  end
end
