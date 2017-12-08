{{ source "common.ikt" }}

apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
apt-get install -y jq

wget -qO- https://get.docker.com/ | sh

mkdir -p /etc/systemd/system/docker.service.d

echo '''
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
''' > /etc/systemd/system/docker.service.d/override.conf

sudo usermod -aG docker {{ var "/local/docker/user" }}

# will restart to pick up service changes in boot script
