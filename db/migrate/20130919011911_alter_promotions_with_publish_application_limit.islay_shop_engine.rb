# This migration comes from islay_shop_engine (originally 20130919011654)
class AlterPromotionsWithPublishApplicationLimit < ActiveRecord::Migration
  def up
    add_column(:promotions, :publish_application_limit, :boolean, :default => true)
  end

  def down
    remove_column(:promotions, :publish_application_limit)
  end
end
