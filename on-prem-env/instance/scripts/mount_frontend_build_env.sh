echo ":::::::: installing Node"
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
apt install nodejs -y
node --version

echo ":::::::: installing yarn"
sudo npm install --global yarn

echo ":::::::: installing angular"
sudo npm install -g @angular/cli

echo ":::::::: finished"

