#!/bin/bash

set -o errexit
set -o nounset
set -o xtrace

{{ source "common.ikt" }}

##### Set up volumes #################################################################
# Only for managers
{{ if and (not (var "/local/infrakit/role/worker")) (eq (var "/cluster/provider") "aws") }} {{ include "setup-volume.sh" }} {{ end }}

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
]
}
EOF
kill -s HUP $(cat /var/run/docker.pid)  {{/* Reload the engine labels */}}
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
