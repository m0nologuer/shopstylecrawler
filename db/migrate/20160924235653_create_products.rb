class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.string :category
      t.string :unbranded_name
      t.string :retailer
      t.string :currency
      t.integer :price
      t.string :brand
      t.string :description
      t.string :img
      t.string :thumbnail
      t.string :raw_xml

      t.timestamps null: false
    end
  end
end
