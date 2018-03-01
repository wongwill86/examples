#!/bin/bash

set -o errexit
set -o nounset
set -o xtrace

{{ source "common.ikt" }}

##### Set up volumes #################################################################
# Only for managers
{{ if not (var "/local/infrakit/role/worker") }} {{ include "setup-volume.sh" }} {{ end }}

if [ -f "/etc/docker_init_done" ]; then
    echo "docker already setup"
else
    echo ##### Set up Docker #############################################################
    {{ if var "/local/install/docker" }} {{ include "install-docker.sh" }} {{ end }}

    echo #### Label the engine ###########################################################
    {{ $dockerLabels := var "/local/docker/engine/labels" }}
    mkdir -p /etc/docker
    cat << EOF > /etc/docker/daemon.json
{
  "labels": [
{{ if not (var `/local/infrakit/role/worker`) }}
	"infrakit-role=manager"
{{ else }}
	"infrakit-role=worker"
{{ end }}
{{ if not (eq 0 (len $dockerLabels)) }}
{{ range $index, $element := $dockerLabels }}
  , {{$element | jsonEncode}}
{{end}}
{{end}}
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "20"
  },
  "hosts": [ "fd://", "tcp://0.0.0.0:4243" ]
}
EOF

    # Try to find NVIDIA devices, this may override /etc/docker/daemon.json
    if lspci | grep NVIDIA; then
        echo "Found NVIDIA devices"
        {{ include "install-nvidia-docker.sh" }}
        # Move original daemon.json to a safe location to prepare for merge
        mv /etc/docker/daemon.json /etc/docker/daemon-original.json

        # Merge original daemon-original.json with new infrakit labels deamon-infrakit.json
        jq -s '.[0] * .[1]' /etc/docker/daemon-original.json /etc/docker/daemon.json.dpkg-dist > /etc/docker/daemon.json
    fi

    service docker restart

    touch /etc/docker_init_done

fi

echo "Wait for Docker to come up"
sleep 30

echo ##### Set up Docker Swarm Mode  ##################################################
{{ if not (var "/cluster/swarm/initialized") }}
echo ##### Initialize Swarm
echo "Init swarm: $(docker swarm init --advertise-addr {{ var "/cluster/swarm/join/ip" }})"  # starts :2377
{{ else }}
echo ##### Joining Swarm
# Wait for firewalls to be set up properly
while ! nc -z -w10 {{ var "/local/docker/swarm/join/addr" | replace ":" " " }}; do
    echo "Waiting for swarm join ip connectivity (check firewall)"
done

echo "Join Swarm: $(docker swarm join --token {{ var "/local/docker/swarm/join/token" }} {{ var "/local/docker/swarm/join/addr" }})"
{{ end }}

echo ##### Infrakit Services  #########################################################
{{ if not (var "/local/infrakit/role/worker") }}
{{ include "infrakit.sh" }}
{{ end }}{{/* if running infrakit */}}
