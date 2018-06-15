#!/bin/bash

set -o errexit
set -o nounset
set -o xtrace

{{/* Before we call the common boot sequence, set a few variables */}}

{{/* var "/cluster/swarm/initialized" SWARM_INITIALIZED */}}

{{ var "/local/docker/engine/labels" INFRAKIT_LABELS }}
{{ var "/local/docker/swarm/join/addr" SWARM_MANAGER_ADDR }}
{{ var "/local/docker/swarm/join/token" SWARM_JOIN_TOKENS.Manager }}

{{ var "/local/infrakit/role/manager" false }}
{{ var "/local/infrakit/role/database" true }}
{{ var "/local/infrakit/role/worker" false }}

mkdir -p /var/lib/mysql
#mount -t tmpfs tmpfs /var/lib/mysql

{{ include "boot.sh" }}

# Append commands here to run other things that makes sense for managers
