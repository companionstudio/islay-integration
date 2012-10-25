# This migration comes from islay_blog_engine (originally 20120811031729)
class CreateBlogTaggings < ActiveRecord::Migration
  def change
    create_table :blog_taggings do |t|
      t.integer :blog_entry_id, :null => false, :on_delete => :cascade
      t.integer :blog_tag_id,   :null => false, :on_delete => :cascade
    end
  end
end
