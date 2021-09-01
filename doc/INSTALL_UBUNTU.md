Installation manual

This manual refers to "Application", which can be substituted by any of the following: Easy Redmine, Easy Project, Redmine.

This file contains an instruction how to make "clear" new installation of EasyRedmine package on Debian server.

Glossary
========

Redmine installer - a ruby gem that is automizes installation procedure of Application

Prerequisites
=============
For both procedures, the following must be complied:
  > Server must have internet connection, at least during the installation (for installation of 3rd party dependencies)
  > At least 250 MB is available on the root disk
  > Web server must have full access to public, files, log, tmp folder
  > Make sure you are not using webrick as web server - it is not supported (we recommend unicorn)

First of all, what is inside the package you've downloaded. There is the ruby Application plus several scripts that allow you to install or upgrade quickly and easily.

Clean installation
==================

1. Update existing os packages and repositories.

sudo apt-get update
sudo apt-get upgrade

2. Install needed packages

sudo apt install gcc build-essential zlib1g zlib1g-dev zlibc ruby-zip libssl-dev libyaml-dev sudo libmagick++-dev libaio1

3. Install database

sudo apt-get install mysql-server default-libmysqlclient-dev

NB! After you've installed database check what version was installed. 

mysql --version

If the version is less then 10.2, then you should uninstall the packages and reinstall version 10.2 from special repository or deb-package. You may find instruction how to do it, for example, here:

https://www.howtoforge.com/community/threads/how-to-upgrade-to-mariadb-10-2-in-debian-9-perfect-setup.79068/

https://mariadb.com/kb/en/library/upgrading-from-mariadb-101-to-mariadb-102/

https://websiteforstudents.com/upgrading-mariadb-from-10-0-to-10-1-to-10-2-on-ubuntu-16-04-17-10/

4. add config to mysql

sudo vim /etc/mysql/conf.d/easy.cnf

Add to config

[mysqld]
bind-address                    = 127.0.0.1
binlog_format                   = row

log_warnings                    = 2
log-error                       = error.log

#slow_query_log_file            = slow_qeries.log
#long_query_time                = 5
min_examined_row_limit         = 100

# general_log_file               = all_guerry.log
# general_log                    = 0

character_set_server            = utf8mb4
collation_server                = utf8mb4_general_ci
query_cache_type                = 1
query_cache_size                = 60M
sort_buffer_size                = 5M
tmp_table_size                  = 60M
read_buffer_size                = 1M
join_buffer_size                = 1M

default_storage_engine          = InnoDB
innodb_autoinc_lock_mode        = 2
innodb_buffer_pool_size         = 60M
innodb_file_per_table           = 1
innodb_flush_log_at_trx_commit  = 2

innodb_file_format              = BARRACUDA
innodb_large_prefix             = 1
innodb_default_row_format       = dynamic

[mysqldump]
max_allowed_packet              = 200M
add_drop_table                  = True
# insert per line, great for diff, but slow
#extended_insert                 = False

5. start mysql service

sudo systemctl start mysql.service

6. install nginx

sudo apt-get install nginx

7. Set up root password to mysql

sudo mysql_secure_installation

Answer the questions installer will ask.

8. run mysql and create database

sudo su
mysql -u root -p

MariaDB [(none)]> create database easy char set utf8mb4;
MariaDB [(none)]> grant all on easy.* to easy@localhost identified by 'PASSWORD';
MariaDB [(none)]> flush privileges;
MariaDB [(none)]> exit

9. install special package that will allow use gpg keys

apt-get install dirmngr

10. add rvm gpg key

gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

11. install curl

apt-get install curl

12. install rvm, run it, add to autostart

curl -sSL https://get.rvm.io | sudo bash -s master
source /etc/profile.d/rvm.sh
echo '[[ -s "/etc/profile.d/rvm.sh" ]] && source "/etc/profile.d/rvm.sh"' >> ~/.bashrc

13. Create user "easy" (or you may name it as you wish, the point is, this user will work with your redmine application, not root user. It should be done for security reasons)

useradd -m -G rvm -s /bin/bash easy

Also you need to add user "easy" to sudoers group (we should allow to this user to run some commands from sudo)

usermod -a -G sudo easy

If you did this you may miss the next step, because after this command your user is in proper group already. Switch to this user

su - easy

14. add user to rvm group

usermod -a -G rvm easy

Also you need to add user "easy" to sudoers group (we should allow to this user to run some commands from sudo)

usermod -a -G sudo easy

Switch to user "easy"

su - easy

15. install ruby

rvm install 2.5.3 --patch railsexpress

16. install git

sudo apt-get install git

17. set ruby 2.5.3 as default

rvm use 2.5.3 --default

18. install gems bundler (specific version) and unicorn

gem install bundler --version 1.16

gem install unicorn

19. install gem redmine-installer

gem install redmine-installer

20. Download easyredmine package

wget https://es.easyproject.com/path_to_file (link from your client's zone)

21. create current directory and switch to it

mkdir current
cd current/

22. run redmine install command

redmine install archive_name.zip /path to current folder/current/

Answer the questions it will ask

Creating database configuration
What database do you want use? MySQL
Database: easy
Host: localhost
Username: easy
Password: password for user easy here
Encoding: utf8mb4
Port: 3306

Creating email configuration
Which service to use for email sending? Choose the option you would like to use and the installer will help you to configure mail sending settings.

23. go to one level higher and create unicorn.rb file

cd ../
vim unicorn.rb

app_home="/home/easy"

worker_processes 4
timeout 3600
preload_app true

listen "#{app_home}/application.sock", :backlog => 64
pid "#{app_home}/application.pid"

stdout_path "#{app_home}/current/log/unicorn.log"
stderr_path "#{app_home}/current/log/unicorn.err"

before_fork do |server, worker|
  # Close all open connections
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end

  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end

end

after_fork do |server, worker|
  # Reopen all connections
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.establish_connection
  end
end

24. create easy.service file

sudo su
vim /etc/systemd/system/easy.service

[Unit]
Description=Easy server system service

[Service]
Restart=on-failure
Type=simple
User=easy
WorkingDirectory=/home/easy/current
Environment=RAILS_ENV=production
PIDFile=/home/easy/application.pid
ExecStart=/bin/bash -lc 'rvm default do unicorn -D -c /home/easy/unicorn.rb -E production'

[Install]
WantedBy=multi-user.target

25. activate system file and start service

systemctl daemon-reload
systemctl start easy.service
systemctl enable easy.service

26. create nginx config. Please, note that with these setting ssl certificates MUST BE added/created. 

vim /etc/nginx/conf.d/easy.conf

# Definition of upstream socket
#
# documentation http://nginx.org/en/docs/http/ngx_http_upstream_module.html
#
upstream rails {
  server                        unix:///home/easy/application.sock;
}

# uncomment if need permanent redirect from http to https
#server {
#  listen                        80;
#  listen                        [::]:80;
#  server_name                   _;
#  location / {
#    rewrite                     ^(.*) https://$http_host$1 permanent;
#  }
#}

server {
  listen                        443 default ssl http2;
  listen                        [::]:443 ssl http2;
# listen                        80;
# listen                        [::]:80;

  client_max_body_size          100M;

# the aplication will listen on all server names
  server_name                   _;

# In this case the root of our application is /home/easy/current
  root                          /home/easy/current/public;

  try_files                     $uri @app;
  error_page                    500 502 503 504 /500.html;

# Uncoment if you would like to compress defined types in gzip_types option
#  gzip                          on;
#  gzip_http_version             1.0;
#  gzip_disable                  "MSIE [1-6]\.(?!.*SV1)";
#  gzip_buffers                  4 16k;
#  gzip_comp_level               4;
#  gzip_min_length               0;
#  gzip_types                    text/plain
#                                text/css
#                                application/x-javascript
#                                text/xml
#                                application/xml
#                                application/xml+rss
#                                text/javascript
#                                application/json;

# Uncoment in case you want to cache static content
#  location ~ ^/(images|system|assets)/ {
#    gzip_static                 on;
#    expires                     1y;
#    add_header                  Cache-Control public;
#    add_header                  ETag '';
#    break;
#  }

  location @app {
    proxy_pass                  http://rails;
    proxy_set_header            Host $http_host;
    proxy_set_header            X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header            X-Forwarded-Proto $scheme;
    proxy_set_header            X-Forwarded-Ssl on;
    proxy_connect_timeout       600;
    proxy_send_timeout          600;
    proxy_read_timeout          600;
    send_timeout                600;
  }

# Uncoment only if use redirect from http to https
#  ssl                          on;

  ssl_certificate              /etc/nginx/self_signed.crt;
  ssl_certificate_key          /etc/nginx/self_signed.key;
  ssl_session_cache            shared:SSL:10m;
  ssl_session_timeout 5m;
  ssl_protocols                TLSv1.2;
  ssl_ciphers                  'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256';
  ssl_prefer_server_ciphers    on;
}

26. create self-signed certificate. If you already have certificates, you may miss this step, just change the path in config file above to the path to certificates.

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/self_signed.key -out /etc/nginx/self_signed.crt

Answer the questions

Country Name (2 letter code) [AU]:cz
State or Province Name (full name) [Some-State]:
Locality Name (eg, city) []:
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Colsys
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:176.222.227.123
Email Address []:

27. start nginx service

systemctl restart nginx
systemctl enable nginx

exit

28. set up scheduler

cd /home/user_directory/
mkdir scripts
cd scripts/
vim easy_scheduler.sh

#!/bin/bash -l
LOG_FILE="/home/easy/current/log/easy_scheduler_rake.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') start rake" >> ${LOG_FILE}
cd /home/easy/current && bundle exec rake easyproject:scheduler:run_tasks RAILS_ENV=production >> ${LOG_FILE}
echo "$(date '+%Y-%m-%d %H:%M:%S') end rake" >> ${LOG_FILE}

chmod +x easy_scheduler.sh 

crontab -e

*/5 * * * *             /home/easy/scripts/easy_scheduler.sh &> /dev/null

sudo service cron reload

29. Open your browser and type

https://ip_address_of_your_server_or_domain_name.here

Application admin's user/password if default data is loaded

> manager / easy848

if default data is not loaded

If in any step you receive an error, first of all, read the error message.

  1) sometimes, the answer how to fix it is already inside the message;

  2) or at least you may try to copy the error and google it. There is a great chance it's known problem and there is already very good recommendation how to fix it quickly;

  3) if you tried everything and nothing works, please, don't panic! Write to our support team to address support@easysoftware.com. Attach the screenshot of the error message or it's text and describe very carefully step by step what did you do before receiving the error. Even small detail may help our support team to answer you quickly and properly.


Troubleshooting
===============

Usually both installation and upgrade go properly if you do everything step by step. But sometimes errors happen. What errors can you meet and how to solve them. If you meet some error, first of all look at it.

All the problems can be splited into 2 categories:

- during installation / upgrade
- after installation / upgrade

During installation / upgrade
=============================

1) If you meet error like 

[!] There was an error parsing `Gemfile`: 
[!] There was an error parsing `Gemfile`: Event 'rys-gemfile' not defined in Bundler::Plugin::Events. Bundler cannot continue.

Try to do the next:

- check that you have the latest available client package (if not, you may download it from your client zone)
- go to your application folder and run

   gem uninstall -a bundler
   gem install bundler -v 1.16.6
   rm -rf .bundle

- rerun the package installation

3) If during package update or running bundle exec command you see error like

Can't connect to MYSQL through socket XXXX

Do the next:

- first of all, check that your database server is running. If you are using local database, try to check that it is shown in process list

ps -aux | grep mysql

If you are using remote database, check that you can't connect to remote server via telnet

telnet domain_or_ip_here

Check that port is open with the same telnet command

telnet domain_or_ip_here port_number_here

Check that database service is running on remote server

4) You restored your dump from somewhere and now are running package update or bundle exec command and you see error like

"table already exists"

In this case you may

- drop table in database, if you are sure there are no significant data in the table (not the best way)
- rename table in database and then, after migration is done, rename it back (better, but still not the best way, because table structure may be different in different versions of redmine)
- mark migration as done (the best way). To mark migration done do the next

-- look trough error message and find number of migration which caused the error. It may look like 20100705164950. 
-- mysql -u USERNAME -p -D DATABASE_NAME

-- UPDATE schema_migrations set VERSION = "MIGRATION NUMBER HERE"

-- rerun bundle exec rake command or installation of the package

5) If during upgrade or installation you've met error like "Index column size too large", it means you need to set correct row format. Usually this problem can be seen only in MariaDB.

- The very important part! Check version of your database

    mysql --version

  If it is 10.0.x you should upgrade your database first.

  If it is 10.2 or higher, you may continue.

- From root user or using sudo open file /etc/mysql/my.cnf in any editor, for example, nano

    sudo nano /etc/mysql/my.cnf

  And add in [mysqld] area the next line

    innodb_default_row_format       = dynamic

  Save the changes and restart mysql service.

  Please note, this setting will work only with MariaDB 10.1.3 or higher. Eariler versions will not recognize this setting.


After installation / upgrade
============================

1) If it looks like white page with some text about error 403 or 404 or 502, then it means that something wrong with your web-server (unicorn) or proxy server (nginx). And you need to check their logs first. 

If in logs you see something about permissions, please try to do the next:

- log in to your server and go to your application folder
- run commands

sudo chmod -R 755 files/ public/ log/ tmp/ config.ru

sudo chown -R easy:easy files/ public/ log/ tmp/ config.ru

systemctl restart easy.service

2) If unicorn server was not started via service you may try to run it manually. Just go to your application folder (it's important!), switch to user easy (user from what you've installed package) and run the next command

rvm default do unicorn -D -c /home/easy/unicorn.rb -E production

It will either run unicorn process or show you proper error message.

If you see something like "file config.ru can't be found", check you are trying to run command from application folder, not from somewhere else.

3) You reload the page and see Error 500 message. In this case first of all check production.log file. Usually it's application message. If it's empty or if there is no error, then check unicorn and nginx logs. If there is nothing about permissions or missed files in the logs, better connect to our support team and don't forget to attach the log or at least found error message.

4) If your application mostly works via https, but some of the pages switch to http, add the next line to /etc/nginx/conf/easy.conf 

proxy_set_header X-Forwarded-Proto https

and restart nginx.

> admin / admin

