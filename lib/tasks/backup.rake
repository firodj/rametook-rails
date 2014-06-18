desc "Backup Toombila Project"
task :backup => [ "backup:db",  "backup:app"]
# http://snippets.dzone.com/posts/show/4777

namespace :backup do

  desc "Dump Current Environment Db to file"  
  task :db => [:environment] do			
    baktime = Time.now.strftime("%Y%m%d.%a.%H%M%S.%Z")
    dbconfig = ActiveRecord::Base.establish_connection.config
	  
    backupdir = File::join(RAILS_ROOT,'db','backups')
    backupname = "#{dbconfig[:database]}[#{RAILS_ENV}-#{baktime}].sql"
    defaultname = "#{dbconfig[:database]}.sql"
    
    FileUtils.mkdir_p(backupdir)
    
    puts "Dumping... to #{backupname}\n\n"
    cmd = ["mysqldump", "-u #{dbconfig[:username]}", "-h #{dbconfig[:host]}"]
    cmd << "--password=#{dbconfig[:password]}" unless dbconfig[:password].nil?
    cmd << dbconfig[:database]
    cmd << "> #{File.join(backupdir,backupname)}"
    `#{cmd.join(' ')}`
    puts "Copying... to #{defaultname}\n\n"
    `cp #{File.join(backupdir,backupname)} #{File.join(backupdir,defaultname)}`
  end
  
  desc "Dump Current Application to file"    
  task :app => [:environment] do
    pathname = Pathname.new(RAILS_ROOT).realpath
    baktime = Time.now.strftime("%Y%m%d.%a.%H%M%S.%Z")
    
    backupdir = File::join(RAILS_ROOT,'..')
    backupname = "#{pathname.basename}[#{baktime}].tgz"
    
    FileUtils.chdir(backupdir)    
    puts "Archiving... #{pathname.basename} application to #{backupname}\n\n"
  	cmd = ["tar -zcvf", backupname, "#{pathname.basename}"]
    # + ["-X", File.join(pathname.basename, 'lib','tasks','backup.no_svn')]
		`#{cmd.join(' ')}`
  end
end
