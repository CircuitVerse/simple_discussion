class AddSearchableColumnToForumThreads < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    if ActiveRecord::Base.connection.adapter_name.downcase.start_with?('postgresql')
      add_column :forum_threads, :searchable_data, :tsvector

      # Initialize the tsvector column
      ForumThread.find_each do |thread|
        thread.update_searchable
      end

      # index concurrently
      add_index :forum_threads, :searchable_data, using: :gin, algorithm: :concurrently
    end
  end

  def down
    if ActiveRecord::Base.connection.adapter_name.downcase.start_with?('postgresql')
      remove_index :forum_threads, :searchable_data
      remove_column :forum_threads, :searchable_data
    end
  end
end
