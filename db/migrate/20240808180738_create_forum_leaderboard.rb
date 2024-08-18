class CreateForumLeaderboard < ActiveRecord::Migration[7.0]
  def change
    create_table :forum_leaderboards do |t|
      t.references :user, null: false, foreign_key: true, index: {unique: true}
      t.integer :points, null: false, default: 0

      t.timestamps
    end

    add_index :forum_leaderboards, :points
  end
end
