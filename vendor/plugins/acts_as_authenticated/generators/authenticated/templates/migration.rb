class <%= migration_name %> < ActiveRecord::Migration
  def self.up
    create_table "<%= table_name %>", :force => true do |t|
      t.column :login,                     :string
      t.column :email,                     :string
      t.column :crypted_password,          :string, :limit => 40
      t.column :salt,                      :string, :limit => 40
      t.column :created_at,                :datetime
      t.column :updated_at,                :datetime
      t.column :remember_token,            :string
      t.column :remember_token_expires_at, :datetime
      
      t.column :display_name, :string, :limit => 100
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :last_login_at, :datetime
      t.column :last_ip, :string
      t.column :userimage, :string
      t.column :department_id, :integer
      t.column :bio, :string
      t.column :website, :string
      t.column :address, :string
      t.column :city, :string
      t.column :country, :string
      t.column :birthday, :datetime
      t.column :admin, :integer, :default => 0
      t.column :activated, :boolean, :default => false
    end
  end

  def self.down
    drop_table "<%= table_name %>"
  end
end
