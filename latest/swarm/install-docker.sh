{{ source "common.ikt" }}

apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
apt-get install -y jq

wget -qO- https://get.docker.com/ | sh

sudo usermod -aG docker {{ var "/local/docker/user" }}
