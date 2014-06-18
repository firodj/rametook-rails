class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table "users", :force => true do |t|
      # Basic
      t.column :login,              :string
      t.column :email,              :string
      t.column :crypted_password,   :string, :limit => 40
      t.column :salt,               :string, :limit => 40
      t.column :created_at,         :datetime
      t.column :updated_at,         :datetime
      # Login Information
      t.column :last_login_at,      :datetime
      t.column :last_ip,            :string
      # Sign Up Activation
      t.column :activation_code,    :string, :limit => 40
      t.column :activated_at,       :datetime
      # Token for Remember Me
      t.column :remember_token,     :string
      t.column :remember_token_expires_at, :datetime
      # Department
      t.column :department_id,      :integer
      # Informational
      t.column :first_name,   :string, :limit => 100
      t.column :last_name,    :string, :limit => 100
      t.column :birthday,     :datetime
      t.column :bio,          :string
      t.column :website,      :string
      t.column :address,      :string
      t.column :city,         :string
      t.column :country,      :string
      t.column :userimage,    :string, :default => 'admin.gif'
    end

    # Add default user account
    say_with_time "Creating superadmin account..." do
      admin = User.new :email => 'admin@local.host', :first_name => 'Administrator', :last_name => 'Super',
        :login => 'admin', :password => 'admin123', :password_confirmation => 'admin123', :userimage => 'admin.gif',
        :activated_at => Time.now
      admin.department = Department.find(:first, :conditions => {:name => 'Uncategorized'})
      admin.roles << Role.find(:first, :conditions => {:title => 'superadmin'})
      admin.save
    end
  end

  def self.down
    drop_table "users"
  end
end
