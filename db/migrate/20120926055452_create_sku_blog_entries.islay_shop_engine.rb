# This migration comes from islay_shop_engine (originally 20120826232814)
# @todo: This migration should actually be added via a generator.
class CreateSkuBlogEntries < ActiveRecord::Migration
  def change
    create_table :sku_blog_entries do |t|
      t.integer :sku_id,        :null => false, :on_delete => :cascade
      t.integer :blog_entry_id, :null => false, :on_delete => :cascade
    end
  end
end
