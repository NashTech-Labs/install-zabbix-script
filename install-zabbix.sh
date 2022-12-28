#!/bin/sh

set -o errexit
# set -o xtrace  # used for debugging

declare mysql_password=""
declare mysql_password_zabbix=""
declare public_ip=""

# Start of the script
echo "Install Zabbix"
echo "--------------"

echo "Downloading zabbix package"
wget https://repo.zabbix.com/zabbix/6.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.2-4%2Bubuntu22.04_all.deb

echo "install the zabbix package"
sudo dpkg -i zabbix-release_6.2-4+ubuntu22.04_all.deb

echo "Updating apt"
sudo apt update

echo "Installing MySQL Server"
sudo apt install mysql-server

# Installing zabbix server, frontend, agent on the same instance to monitor using zabbix, sql scripts for initial database setup
echo "Install zabbix server, frontend, agent on the same instance to monitor using zabbix, sql scripts for initial database setup"
sudo apt install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

echo "Enter MySQL Password: "
read mysql_password
echo "Enter MySQL Password for Zabbix user: "
read mysql_password_zabbix
echo "Create initial database"
# mysql -uroot -p$mysql_password

sudo mysql --password=$mysql_password --user=root --execute="create database zabbix character set utf8mb4 collate utf8mb4_bin;"
sudo mysql --password=$mysql_password --user=root --execute="create user zabbix@localhost identified by "\'$mysql_password_zabbix\'""
sudo mysql --password=$mysql_password --user=root --execute="grant all privileges on zabbix.* to zabbix@localhost"
sudo mysql --password=$mysql_password --user=root --execute="set global log_bin_trust_function_creators = 1"
echo "Exited MySQL"

zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p$mysql_password zabbix

sudo mysql --password=$mysql_password --user=root --execute="set global log_bin_trust_function_creators = 0"

echo "Configure the database for Zabbix server"
echo "DBPassword=${mysql_password}" | sudo tee -a /etc/zabbix/zabbix_server.conf

echo "Start Zabbix server and agent processes"
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2
echo "Successfully started zabbix server and agent processes"

echo "installation successful of zabbix server, frontend, creating initial database and zabbix agent"

public_ip=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
echo "Configure the zabbix server on the web page on http://$public_ip/zabbix"
