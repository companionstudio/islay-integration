# This migration comes from islay_shop_engine (originally 20130703031124)
class CreateServices < ActiveRecord::Migration
  def up
    create_table :services do |t|
      t.string  :name,        :null => false, :limit => 200
      t.string  :key,         :null => true,  :limit => 20
      t.boolean :deletable,   :null => false, :default => true

      t.user_tracking
      t.timestamps
    end

    execute(%{
      INSERT INTO services (name, key, deletable, created_at, updated_at, creator_id, updater_id)
      VALUES (
        'Shipping',
        'shipping',
        false,
        COALESCE((SELECT created_at FROM orders ORDER BY created_at ASC LIMIT 1), NOW()),
        NOW(),
        (SELECT id FROM users WHERE email = 'system@spookandpuff.com'),
        (SELECT id FROM users WHERE email = 'system@spookandpuff.com')
      )
    })
  end

  def down
    drop_table(:services)
  end
end
