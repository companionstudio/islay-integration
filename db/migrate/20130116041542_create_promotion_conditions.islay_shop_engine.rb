# This migration comes from islay_shop_engine (originally 20120531103046)
class CreatePromotionConditions < ActiveRecord::Migration
  def change
    create_table :promotion_conditions do |t|
      t.integer :promotion_id,  :null => false, :on_delete => :cascade
      t.string  :type,          :null => false, :limit => 50
      t.hstore  :config,        :null => false

      t.timestamps
    end
  end
end
