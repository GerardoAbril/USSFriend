sudo apt-get install default-jdk
sudo apt-get install perl
sudo apt-get install cpanminus
sudo apt-get install mysql
sudo apt-get install libmysqlclient-dev libmysqld-dev
sudo apt-get install apache
sudo apt-get install apache2 php7.0 libapache2-mod-php7.0
sudo apt-get install php7.0-mysql
sudo cpanm AppConfig
sudo cpanm Carp
sudo cpanm DBD
sudo cpanm DBI
sudo cpanm Net::Pcap
sudo cpanm NetPacket::Ethernet
sudo cpanm NetPacket::IP qw/ :protos /
sudo cpanm NetPacket::TCP
sudo cpanm NetPacket::UDP
a2query -m php7.0
sudo a2enmod php7.0
sudo service apache2 restart
use LWP::Online