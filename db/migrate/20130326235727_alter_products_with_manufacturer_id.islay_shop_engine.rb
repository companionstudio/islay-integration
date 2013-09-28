# This migration comes from islay_shop_engine (originally 20130326234451)
class AlterProductsWithManufacturerId < ActiveRecord::Migration
  def up
    add_column(:products, :manufacturer_id, :integer, :null => true)
  end

  def down
    remove_column(:products, :manufacturer_id)
  end
end

