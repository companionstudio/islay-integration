# This migration comes from islay_blog_engine (originally 20120810110956)
class CreateBlogEntries < ActiveRecord::Migration
  def change
    create_table :blog_entries do |t|
      t.integer :author_id,   :null => false, :references => :users, :on_delete => :cascade
      t.string  :title,       :null => false, :limit => 200
      t.string  :slug,        :null => false, :limit => 200, :unique => true
      t.string  :body,        :null => false, :limit => 8000
      t.hstore  :metadata,    :null => true

      t.publishing
      t.user_tracking
      t.timestamps
    end

    add_column(:blog_entries, :terms, :tsvector)
  end
end
