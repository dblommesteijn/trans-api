echo "======================================================="
echo " Updating Apt... "
echo "======================================================="
sudo DEBIAN_FRONTEND=noninteractive apt-get -q -y -o Dpkg::Options::="--force-confdef" update

echo "======================================================="
echo " Installing Dependencies... "
echo "======================================================="
sudo DEBIAN_FRONTEND=noninteractive apt-get -q -y -o Dpkg::Options::="--force-confdef" install transmission-cli transmission-common transmission-daemon

echo "======================================================="
echo " Configuring... "
echo "======================================================="
# ruby /vagrant/.vagrant/bootstrap/testing.rb

# prepare paths
sudo mkdir -p /home/vagrant/downloads/
sudo chmod -R 777 /home/vagrant/downloads/
# register daemon
sudo update-rc.d transmission-daemon defaults
# push config
sudo service transmission-daemon stop
sudo cp /vagrant/.vagrant/bootstrap/settings.json /var/lib/transmission-daemon/info/settings.json
sudo chown debian-transmission /var/lib/transmission-daemon/info/settings.json
sudo service transmission-daemon start

echo "======================================================="
echo " VM is up and running!"
echo " ---------------------"
echo " Running service at: http://localhost:19091 (tunneled)"
echo " - You can now start testing!"
echo " $ CONFIG=\"{\\\"host\\\":\\\"localhost\\\",\\\"port\\\":\\\"19091\\\",\\\"user\\\":\\\"admin\\\",\\\"pass\\\":\\\"adm1n\\\",\\\"path\\\":\\\"/transmission/rpc\\\"}\""
echo " $ ruby -I test test/unit/trans_connect.rb"
echo "======================================================="

