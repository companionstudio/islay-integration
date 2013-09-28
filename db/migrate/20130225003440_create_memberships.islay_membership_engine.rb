# This migration comes from islay_membership_engine (originally 20130224235427)
class CreateMemberships < ActiveRecord::Migration
  def change
    create_table :memberships do |t|
      t.integer :person_id, :null => false
      t.integer :group_id,  :null => false
      t.hstore  :config,    :null => true

      t.user_tracking
      t.timestamps
    end
  end
end
