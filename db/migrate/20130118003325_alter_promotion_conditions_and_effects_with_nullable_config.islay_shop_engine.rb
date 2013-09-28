# This migration comes from islay_shop_engine (originally 20130117234405)
class AlterPromotionConditionsAndEffectsWithNullableConfig < ActiveRecord::Migration
  def up
    change_column_null(:promotion_conditions, :config, true)
    change_column_null(:promotion_effects, :config, true)
  end

  def down
    change_column_null(:promotion_conditions, :config, false)
    change_column_null(:promotion_effects, :config, false)
  end
end
