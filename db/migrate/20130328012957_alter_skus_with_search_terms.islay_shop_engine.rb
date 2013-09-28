# This migration comes from islay_shop_engine (originally 20130328012713)
class AlterSkusWithSearchTerms < ActiveRecord::Migration
  def up
    add_column(:skus, :terms, :tsvector)
  end

  def down
    remove_column(:skus, :terms)
  end
end
