namespace :uberspace do
  # invoked in capistrano_hooks.rake before :check and :starting
  task :defaults do
    on roles(:web) do |host|
      set :home, "/home/#{host.user}"
      # Set a random, ephemeral port, and hope it's free.
      # Could be refactored to actually check whether it is.

      set :port, -> { rand(61000-32768+1)+32768 }
    end
  end

  desc "Setup a Uberspace account for serving Rails"
  task setup: [:setup_supervisord, :setup_reverse_proxy, :setup_database_and_config]

  desc "Start the Rails Server"
  task :start do
    on roles(:web) do
      execute "supervisorctl start #{fetch :application}"
    end
  end

  desc "Stop the Rails Server"
  task :stop do
    on roles(:web) do
      execute "supervisorctl stop #{fetch :application}"
    end
  end

  desc "Restart the Rails server"
  task :restart do
    on roles(:web) do
      execute "supervisorctl restart #{fetch :application}"
    end
  end

  desc "Setup uberspace's MySQL server"
  task setup_database_and_config: :defaults do
    on roles(:web) do |host|
      database_name = "#{host.user}_#{fetch(:application).gsub(/\W/, '_')}_#{fetch :stage}"
      my_cnf = capture('cat ~/.my.cnf')
      config = {}
      env = (fetch :stage).to_s

      config[env] = {
        'adapter' => 'mysql2',
        'encoding' => 'utf8',
        'database' => database_name,
        'host' => 'localhost'
      }

      config[env]['username'] = my_cnf.scan(/^user=(.*)$/)[0][0]

      config[env]['password'] = my_cnf.scan(/^password=(.*)$/)[0][0]

      config[env]['port'] = 3306

      execute "mysql -e 'CREATE DATABASE IF NOT EXISTS #{database_name} CHARACTER SET utf8 COLLATE utf8_general_ci;'"

      execute "mkdir -p #{fetch :deploy_to}/shared/config"
      database_yml = StringIO.new(config.to_yaml)
      upload! database_yml, "#{fetch :deploy_to}/shared/config/database.yml"
      upload! 'config/master.key', "#{fetch :deploy_to}/shared/config/master.key"
    end
  end

  desc "Setup supervisord"
  task setup_supervisord: :defaults do
    app_config = <<-EOF
[program:#{fetch :application}]
command=bundle exec rails s -p #{fetch :port} -e #{fetch :stage}
directory=#{fetch :deploy_to}/current
autostart=yes
autorestart=yes
    EOF

    app_config_stream = StringIO.new(app_config)
    on roles(:web) do
      upload! app_config_stream, "#{fetch :home}/etc/services.d/#{fetch :application}.ini"
    end
  end

  task setup_reverse_proxy: :defaults do
      htaccess = <<-EOF
DirectoryIndex disabled
RewriteEngine On
RewriteCond %{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f
RewriteRule ^(.*)$ http://#{host.user}.local.uberspace.de:#{fetch :port}/$1 [P]
      EOF
      htaccess_stream = StringIO.new(htaccess)
      on roles(:web) do |host|
        path = "/var/www/virtual/#{host.user}/html"
        execute "mkdir -p #{path}"
        upload! htaccess_stream, "#{path}/.htaccess"
        execute "chmod +r #{path}/.htaccess"
    end
  end
end
