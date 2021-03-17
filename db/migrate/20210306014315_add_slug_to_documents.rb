class AddSlugToDocuments < ActiveRecord::Migration[6.1]
  def change
    add_column :documents, :slug, :string
    add_index :documents, :slug, unique: true
  end
end
