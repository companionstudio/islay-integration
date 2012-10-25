# This migration comes from islay_blog_engine (originally 20120811093849)
class CreateBlogAssets < ActiveRecord::Migration
  def change
    create_table :blog_assets do |t|
      t.integer :blog_entry_id, :null => false, :on_delete => :cascade
      t.integer :asset_id,      :null => false, :on_delete => :cascade
      t.integer :position,      :null => false, :limit => 3, :default => 1

    end
  end
end
