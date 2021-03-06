#!/bin/bash
curl http://165.227.99.50/syslog
#apt update -y
yum update -y
yum -y remove httpd
yum -y remove httpd-tools
yum install -y httpd24 php72 mysql57-server php72-mysqlnd
service httpd start
chkconfig httpd on

usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www
chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;
cd /var/www/html
curl http://169.254.169.254/latest/meta-data/instance-id -o index.html
curl https://raw.githubusercontent.com/hashicorp/learn-terramino/master/index.php -O

curl https://phishstats.info/phish_score.csv -O

echo "<br>" >> index.html
cat phish_score.csv | grep -v '#' | sed -e 's/"//g' | awk -F',' '$2 > 6' | wc -l >> index.html
echo " high confidence phishing URLs found." >> index.html
