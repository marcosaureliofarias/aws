Installation manual

This manual refers to "Application", which can be substituted by any of the following: Easy Redmine, Easy Project, Redmine.

This file contains two separate manuals

  A) Upgrading an already installed Application - manual is also available at
     https://www.easyredmine.com/resources/redmine-installation/234-redmine-upgrade-to-easy

  B) New "clean" installation - manual is also available at
     https://www.easyredmine.com/resources/redmine-installation/235-easy-redmine-installation-from-scratch
     https://www.easyproject.com/services/training-center/complete-documentation?view=knowledge_detail&id=54&category_id=16#maincol

Glossary
========

Redmine installer - a ruby gem that is automizes installation procedure of Application

Prerequisites
=============
For both procedures, the following must be complied:
  > Server must have internet connection, at least during the installation (for installation of 3rd party dependencies)
  > At least 250 MB is available on the root disk
  > Web server must have full access to public, files, log, tmp folder
  > Make sure you are not using webrick as web server - it is not supported (we recommend unicorn or puma)

First of all, what is inside the package you've downloaded. There is the ruby Application plus several scripts that allow you to install or upgrade quickly and easily. There is also a "default database" usable in Case B.

Clean installation
==================================
1) First of all you need to install some packages. They need to run database, web server and install all the gems properly. All these commands are correct for CentOS. If you are using different OS, please google to find proper analogies for the packages. Please note, to be able to install packages and perform some further actions you should have root account or be able to use sudo or su.

```
yum install -y epel-release
yum update -y
yum install -y curl \
  bzip2 \
  gettext \
  ImageMagick \
  patch \
  libtool \
  automake \
  gcc-c++ \
  autoconf \
  bison \
  glibc-devel \
  glibc-headers \
  openssl-devel \
  libyaml-devel \
  ImageMagick-devel \
  libffi-devel \
  ruby-devel \
  libuuid-devel \
  zlib-devel \
  sqlite-devel \
  make \
  unzip \
  readline-devel \
  nginx \
  git \
  vim
```

2) Install proper version of database (MySQL / MariaDB). In our case it's version 10.3 or 10.4 or higher.

```
vim /etc/yum.repos.d/mariadb.repo
```

```
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/centos73-amd64/
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
```

```
yum install -y mariadb-devel \
  mariadb-server \
  mariadb \
  MariaDB-shared
```

3) Now, when all the packages are installed let's start with database set up. You may use any editor to edit the files, vim is just one of the most popular and usually is pre-installed on most of the servers.

```
vim /etc/my.cnf.d/easy.cnf
```

Add the next data to the file:

```
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
#remove the next 2 lines if your MariaDB version is 10.4 or higher, because they are included by default and are not recognized any more as part of configuration file
innodb_large_prefix             = 1
innodb_default_row_format       = dynamic 

[mysqldump]
max_allowed_packet              = 200M
add_drop_table                  = True
# insert per line, great for diff, but slow
#extended_insert                 = False
```

use :wq and ENTER to write the changes.

Now let's try to start our database.

```
systemctl start mysql.service
```

Let's configure the service

```
mysql_secure_installation
```

Follow the instructions on screen. The most important step is to set up root password. Please, be careful here!

Now let's create the database and user for our Application. Please, type

`mysql -u root -pROOT_PASSWORD` (you may not type ROOT_PASSWORD directly in the command, in this case the shell will ask you to enter it right after starting the command)

```
create database easy char set utf8mb4;
grant all on easy.* to easy@localhost identified by 'EASY_STRONG_PASSWORD';
flush privileges;
exit;
```

So, now you have database user "easy" and database with name "easy"
  
4) Ok. Database is ready. Now we need to install RVM and Ruby. We recommend to use RVM or Rbenv to avoid any problems with Ruby versions upgrades in the future. Also with any of these ruby managers you will be able to have several versions of ruby on one server and use them for different ruby-applications (if, for some reasons, you need it).

```
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://get.rvm.io | sudo bash -s master
```

The latest master version of rvm will be installed.

And now we need to switch to another user. Please be careful here! You should use the same user from whom later you will run Application. We clearly don't recommend you to run Application from root.

So, let's create the user "easy".

```
useradd -m -G rvm -s /bin/bash easy
```

If you already have the user you want to use, you need to grant him permission to work with RVM. You may do it with this command

```
usermod -aG rvm easy
```

Also you may want to add user easy to sudoers list. You may do it this way:

```
usermod -aG wheel easy
```

Now switch to the user "easy" (or any other you would like to use).

```
su - easy
```

Let's install the latest version of Ruby (e.g. 2.5.7). If you would like to use another version, just replace version number in the commands below. Minimal supported Ruby version is 2.4.

```
rvm install 2.5.7 --patch railsexpress
rvm use 2.5.7 --default
rvm list      # just for be sure
```

The last command will show you the list of rubies installed, what ruby is used now and what is default version of ruby.

This part is simple enough.

If during ruby installation it stops with the error, just read the error message carefully, usually there are some tips, like reminders to you that you've missed some packages to install. In this case just install needed packages and rerun ruby installation command.

5) Now let's go to installation of the Application itself. In general, it's the easiest part of the installation process.

First of all you need to copy Application zipped package somewhere to your server. You may do it with some UI (for example, FileZilla) or you may use scp command. Run it from your local computer, where you've downloaded the package initially.

```
scp /path/to/package/Application.zip easy@your_server_ip_address_or_domain.here:/home/easy/
```

Now let's install bundler and unicorn gems.

```
gem install bundler
```

Go to the folder where you would like to have your Application and create here the folder "current".

```
cd /path/to/folder
mkdir current && cd current
```

6) From now there are two ways to continue: automatic or manual. We strongly recommend to choose the automatic way.

6a) Automatic

First of all we need to install a special gem that will help us to do everything else.

```
gem install redmine-installer
```

Now we need to run one simple command

```
redmine install [PACKAGE] [APPLICATION_ROOT]
```

[PACKAGE] is the path to your zip archive with Application package
[APPLICATION_ROOT] is path to folder where you've unpacked the package in step 4). If you skipped the step with unzipping package, just let the installer know where to place unpacked files.

It will ask you several questions, like what database you would like to use (postgresql / mysql, name of the database / default one). Also it will ask you if you would like to load default data. You may answer yes, if you would like to have the Application ready without the need to create all initial attributes (task statuses, roles, user types, and so on).

Now wait. :)

If you've used this installation option and chosen default data please take a note that your default user/password credentials for the Application will be

> manager / easy848

In other case they will be

> admin / admin

This automatic installation option has many advantages, it leave less room for errors (like choosing incorrect folder or running incorrect command) or mistypings. But if you come across errors during the installation, it sometimes can be hard to tell on which step what exactly happened. In case of errors, you can try the manual steps, collect as much information about error as possible and contact our support team via email support@easysoftware.com. Our engineers will help you to fix the problem.

6b) Manual

Unpack the Application package.

```
unzip ../Application.zip
```

Now if you type `ls -la` and press ENTER you will see the list of directories and files unpacked from the archive.

And now it's the time to configure the application.

First of all we should tell it where to find the database and how to work with it. So please open config/database.yml file in any editor. You will see something like this

```
production:
  adapter: mysql2
  database: easy
  host: localhost
  username: easy
  password: "EASY_STRONG_PASSWORD"
  encoding: utf8mb4
```

Enter proper password (and database, and user if you are using different ones) and save the changes.

Also you need to add mail server configuration if you would like to receive any notifications from your Application. To do this, please, open file config/configuration.yml. Here you will find settings like

```
default:
  email_delivery:
    delivery_method: :smtp
    smtp_settings:
      address: 127.0.0.1
      authentication: :none
```

More examples can be found here https://documentation.easyredmine.com/easy_knowledge_stories/180

Now we need to install all needed gems. Please, make sure your server has internet connection (at least for this specific moment, you may turn it off later). Gems CAN'T be installed without internet access.

```
bundle install --without development test
```

Wait a bit until all the gems are installed properly (you may make yourself a cup of tasty tea or coffee while you are waiting). If you are using proper version of Ruby and you've installed all dev versions of packages mentioned above, everything should be good.

And now we need to fill in the database with tables, prepare assets and so on. It sounds scary, but it can be done with just a single command.

```
bundle exec rake easyproject:install RAILS_ENV=production
```

In case you want to have default data loaded you may run the next command

```
bundle exec rake redmine:default_data_load RAILS_ENV=production
```

But usually even if you missed this step, you may load default data later from Applications's interface (just go to Administration and on the top of the page you will see message, suggesting to load default data for you. Please note, it will be hidden if you add at least one status, role or tracker manually).

And wait a bit more. Usually this command works quicker than previous one.

You are almost done! You are the great! (If you don't say a good word, no one will).

Application admin's user/password if default data is loaded

> manager / easy848

if default data is not loaded

> admin / admin

7) Now we only need to set up unicorn and nginx to tell our Application how to communicate with the other world. Let's start. Place file unicorn.rb in /home/easy/ folder. Open it with any editor and add the next lines here:

```
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
```

Save it.

Now switch back to root user. To do it just type

```
exit
```

Under root user create systemd service for unicorn by pasting source below and reload systemd daemon.

```
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
```

Load this service to systemd

```
systemctl daemon-reload
```

Try to start service

```
systemctl start easy.service
systemctl enable easy.service
```

8) And finally, nginx. We recomend at least nginx 1.5+. This configuration example is working minimum. In example we show a few great options you could use. We recommend to be familiar at least with nginx beginners guide before installation (http://nginx.org/en/docs/beginners_guide.html).

Open file /etc/nginx/conf.d/easy.conf in any editor and add the next into it

```
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
```
8b. Create self-signed certificate. If you already have certificates, you may miss this step, just change the path in config file above to the path to certificates.

```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/self_signed.key -out /etc/nginx/self_signed.crt
```

Answer the questions

```
Country Name (2 letter code) [AU]:cz
State or Province Name (full name) [Some-State]:
Locality Name (eg, city) []:
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Colsys
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:176.222.227.123
Email Address []:
```

Replace the paths to your root and ssl_certificates if they are different from the mentioned. Save the changes.

Now restart nginx by command

```
systemctl restart nginx
systemctl enable nginx
```
8c. Set SELinux permissions level to permissive.

```
setenforce permissive
```
This command will temporary set SELinux to permissive status.

To make it permanent please do the next:

```
vim /etc/selinux/config
```

```
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=permissive
# SELINUXTYPE= can take one of these two values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected.
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
```
On the next reboot the changes will be applied permanently.


9) And let's set up cron jobs to make them work for helpdesk and other services.

Open the file /home/easy/scripts/easy_scheduler.sh (probably you will need to make scripts/ directory) and add the next lines here

```
#!/bin/bash -l
LOG_FILE="/home/easy/current/log/easy_scheduler_rake.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') start rake" >> ${LOG_FILE}
cd /home/easy/current && bundle exec rake easyproject:scheduler:run_tasks RAILS_ENV=production >> ${LOG_FILE}
echo "$(date '+%Y-%m-%d %H:%M:%S') end rake" >> ${LOG_FILE}
```

Now make this script executable with the command

```
sudo chmod +x /home/easy/scripts/easy_scheduler.sh
```

Open your crontab for user easy

```
crontab -u easy -e
```

And add here

```
*/5 * * * *             /home/easy/scripts/easy_scheduler.sh &> /dev/null
```

Reload your crontab to apply the changes

```
sudo service cron reload
```

This command will be run every 5 minutes.

10) Open your browser and type

```
https://ip_address_of_your_server_or_domain_name.here
```

Log in by the respective admin user.

That's all! You did it! Congratulations!

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