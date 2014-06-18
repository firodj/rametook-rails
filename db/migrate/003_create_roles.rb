class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :roles, :force => true do |t|
       t.column :title,       :string
       t.column :description, :string
    end
    
    say_with_time "Creating superadmin role..." do
      Role.create :title => 'superadmin', :description => "It's administrator.. and super!"
      # Role.create :title => "user", :description => "Common user"
      # Role.create :title => "userfrozen", :description => "Unlucky user, deleted or banned."
    end
  end

  def self.down
    drop_table :roles
  end
end
