# This migration comes from islay_shop_engine (originally 20130327002435)
class CreateManufacturerAssets < ActiveRecord::Migration
  def change
    create_table :manufacturer_assets do |t|
      t.integer :manufacturer_id, :null => false, :on_delete => :cascade
      t.integer :asset_id,        :null => false, :on_delete => :cascade
      t.integer :position,        :null => false, :limit => 3, :default => 1

      t.timestamps
    end
  end
end
