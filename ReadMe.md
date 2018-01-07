### Coinpricegame.com

### Linux installation

adduser <USERNAME>
usermod -aG sudo <USERNAME>
su - <USERNAME>

sudo apt-get install clang libicu-dev
sudo apt-get install libpython2.7
sudo apt-get install libcurl4-openssl-de

sudo apt-get install postgresql postgresql-contrib

sudo -u postgres createuser --createdb $USER
sudo -u postgres createdb app
sudo -u postgres psql -d app -c "alter user "$USER" with password 'password';"

sudo apt-get install libssl-dev // Required by Cryptor
sudo apt-get install libpq-dev  // Required by SwiftKueryPostgreSQL

psql -d app -U <USERNAME> -W

swift build -Xcc -I/usr/include/postgresql
swift build -Xcc -I/usr/include/postgresql --product App -c release
