# Installation of NVIDIA Docker https://github.com/NVIDIA/nvidia-docker
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | \
  apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/ubuntu16.04/amd64/nvidia-docker.list | \
  tee /etc/apt/sources.list.d/nvidia-docker.list

sudo add-apt-repository ppa:graphics-drivers/ppa -y

# Add the package repositories
apt-get update

if ! nvidia-smi; then
  apt install nvidia-387
else
  echo 'nvidia-smi already installed, not installing drivers'
fi

# Install nvidia-docker2 
sudo apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install nvidia-387 nvidia-docker2
