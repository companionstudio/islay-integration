# This migration comes from islay_shop_engine (originally 20121030234226)
class AlterOrdersAddTrackingReference < ActiveRecord::Migration
  def up
    add_column(:orders, :tracking_reference, :string, :limit => 30, :null => true)
  end

  def down
    remove_column(:orders, :tracking_reference)
  end
end
