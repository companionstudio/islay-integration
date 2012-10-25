# This migration comes from islay_shop_engine (originally 20120522004456)
class CreateProductRanges < ActiveRecord::Migration
  def change
    create_table :product_ranges do |t|
      t.integer :asset_id,      :null => true
      t.string  :name,          :null => false, :limit => 255, :index => :unique
      t.string  :slug,          :null => false, :limit => 255, :index => :unique
      t.string  :description,   :null => false, :limit => 4000

      t.publishing
      t.user_tracking
      t.timestamps
    end

    add_column(:product_ranges, :terms, :tsvector)
  end
end
