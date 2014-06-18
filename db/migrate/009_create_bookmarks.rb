class CreateBookmarks < ActiveRecord::Migration
  def self.up
    create_table :bookmarks, :force => true do |t|
      t.column :name, :string
      t.column :url, :string
      t.column :user_id, :integer
      t.column :public, :boolean, :default => false
    end
    # execute "ALTER TABLE bookmarks ADD CONSTRAINT fk_bookmark_users FOREIGN KEY (user_id) REFERENCES users(id)"
    
    # Language for Bookmark plugins
    Language.create :name => "personal", :value => "personal", :language => "en"
    Language.create :name => "public", :value => "public", :language => "en"
    Language.create :name => "url", :value => "URL", :language => "en"
    Language.create :name => "url info", :value => "do not use http://", :language => "en"
    Language.create :name => "bookmark", :value => "bookmark", :language => "en"    
  end

  def self.down
    drop_table :bookmarks
  end

end