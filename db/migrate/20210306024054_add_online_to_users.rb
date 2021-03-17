class AddOnlineToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :last_online_at, :datetime
  end
end
