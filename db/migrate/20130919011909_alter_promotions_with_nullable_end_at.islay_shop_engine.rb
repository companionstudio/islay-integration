# This migration comes from islay_shop_engine (originally 20130910054748)
class AlterPromotionsWithNullableEndAt < ActiveRecord::Migration
  def up
    change_column_null(:promotions, :end_at, true)
  end

  def down
    change_column_null(:promotions, :end_at, false)
  end
end
