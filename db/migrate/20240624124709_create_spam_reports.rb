class CreateSpamReports < ActiveRecord::Migration[7.0]
  def change
    create_table :spam_reports do |t|
      t.references :forum_post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true # The user who reported the post
      t.integer :reason, null: false # Enum for reason
      t.text :details # optional column if the reason is 'other'

      t.timestamps
    end
  end
end
