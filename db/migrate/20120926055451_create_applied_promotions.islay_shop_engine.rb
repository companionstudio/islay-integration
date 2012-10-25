# This migration comes from islay_shop_engine (originally 20120618045608)
class CreateAppliedPromotions < ActiveRecord::Migration
  def change
    create_table :applied_promotions do |t|
      t.integer :promotion_id,              :null => false
      t.integer :promotion_effect_id,       :null => false
      t.integer :order_id,                  :null => false, :on_delete => :cascade
      t.integer :qualifying_order_item_id,  :null => true,  :references => :order_items
      t.integer :bonus_order_item_id,       :null => true,  :references => :order_items

      t.timestamp :created_at
    end
  end
end
