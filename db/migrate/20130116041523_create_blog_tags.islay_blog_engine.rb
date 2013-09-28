# This migration comes from islay_blog_engine (originally 20120811031725)
class CreateBlogTags < ActiveRecord::Migration
  def change
    create_table :blog_tags do |t|
      t.string :name, :null => false, :limit => 200
      t.string :slug, :null => false, :limit => 200, :unique => true
    end
  end
end
