# This migration comes from islay_shop_engine (originally 20120522005035)
class CreateProductVariantAssets < ActiveRecord::Migration
  def change
    create_table :product_variant_assets do |t|
      t.integer :product_variant_id,  :null => false, :on_delete => :cascade
      t.integer :asset_id,            :null => false, :on_delete => :cascade
      t.integer :position,            :null => false, :limit => 3, :default => 1

      t.timestamps
    end
  end
end
