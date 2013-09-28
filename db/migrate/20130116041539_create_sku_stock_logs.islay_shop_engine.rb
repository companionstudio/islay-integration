# This migration comes from islay_shop_engine (originally 20120531093415)
class CreateSkuStockLogs < ActiveRecord::Migration
  def change
    create_table :sku_stock_logs do |t|
      t.integer :sku_id,  :null => false,   :on_delete => :cascade
      t.integer :before,  :null => false,   :limit => 5
      t.integer :after,   :null => false,   :limit => 5
      t.string  :action,  :null => false,   :limit => 25

      t.user_tracking(true)
      t.timestamps
    end
  end
end
