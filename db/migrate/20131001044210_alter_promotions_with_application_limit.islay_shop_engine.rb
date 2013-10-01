# This migration comes from islay_shop_engine (originally 20131001020107)
class AlterPromotionsWithApplicationLimit < ActiveRecord::Migration
  def up
    add_column(:promotions, :application_limit, :integer, :null => true, :precision => 7,  :scale => 0)
  end

  def down
    remove_column(:promotions, :application_limit)
  end
end
