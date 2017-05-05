apt-get -y install curl

# Chef installation (specific version)
echo "Installing chef version $CHEF_VERSION"

curl -o /tmp/chef-install.sh -L https://www.chef.io/chef/install.sh
bash /tmp/chef-install.sh -v $CHEF_VERSION
rm -f /tmp/chef-install.sh

exit
