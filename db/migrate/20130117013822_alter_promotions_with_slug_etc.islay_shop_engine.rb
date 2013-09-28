# This migration comes from islay_shop_engine (originally 20130117013342)
class AlterPromotionsWithSlugEtc < ActiveRecord::Migration
  def up
    add_column(:promotions, :application_limit, :integer, :null => true, :precision => 7,  :scale => 0)
    add_column(:promotions, :slug, :string, :null => true, :limit => 200, :unique => true)
  end

  def down
    remove_column(:promotions, :application_limit)
    remove_column(:promotions, :slug)
  end
end
