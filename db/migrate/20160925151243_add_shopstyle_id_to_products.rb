class AddShopstyleIdToProducts < ActiveRecord::Migration
  def change
    add_column :products, :shopstyle_id, :integer
  end
end
