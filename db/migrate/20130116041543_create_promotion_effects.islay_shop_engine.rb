# This migration comes from islay_shop_engine (originally 20120531103047)
class CreatePromotionEffects < ActiveRecord::Migration
  def change
    create_table :promotion_effects do |t|
      t.integer :promotion_id,  :null => false, :on_delete => :cascade
      t.string  :type,          :null => false, :limit => 50
      t.hstore  :config,        :null => false

      t.timestamps
    end
  end
end
