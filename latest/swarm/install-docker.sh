{{ source "common.ikt" }}

# add docker ce repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
apt-get install -y jq

# nvidia-docker only supports stable docker releases, can't use script
wget -qO- https://get.docker.com/ | sh

#apt install docker-ce -y

sudo usermod -aG docker {{ var "/local/docker/user" }}

# For Upstart ONLY (pre- Ubuntu 15.04)
if [ -d "/var/log/upstart" ]; then
    # Upstart
    echo DOCKER_OPTS=\"-H tcp://0.0.0.0:4243 -H unix:///var/run/docker.sock\" >> /etc/default/docker
else
    # Systemd
    mkdir -p /etc/systemd/system/docker.service.d

    echo '''
    [Service]
    ExecStart=
    ExecStart=/usr/bin/dockerd
    ''' > /etc/systemd/system/docker.service.d/override.conf

	systemctl daemon-reload
fi

# will restart to pick up service changes in boot.sh script
