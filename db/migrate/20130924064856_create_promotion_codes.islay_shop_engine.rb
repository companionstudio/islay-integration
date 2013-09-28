# This migration comes from islay_shop_engine (originally 20130924064801)
class CreatePromotionCodes < ActiveRecord::Migration
  def change
    create_table :promotion_codes do |t|
      t.integer   :promotion_condition_id,  :null => false
      t.string    :code,                    :null => false, :limit => 200, :unique => true
      t.timestamp :redeemed_at,             :null => true
      t.integer   :order_id,                :null => true
      t.timestamps
    end
  end
end

