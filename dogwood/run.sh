# Create LXC VM for 12.04.5
# sudo lxc-create -download -n myNode #dist: ubuntu , release: precise , arch: amd64
sudo bash install-openedx.sh "named-release/dogwood.rc" | tee /tmp/openedx-install.log

