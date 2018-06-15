#!/bin/bash

set -o errexit
set -o nounset
set -o xtrace

{{/* Before we call the common boot sequence, set a few variables */}}

{{ var "/cluster/swarm/initialized" SWARM_INITIALIZED }}

{{ var "/local/docker/engine/labels" INFRAKIT_LABELS }}
{{ var "/local/docker/swarm/join/addr" SWARM_MANAGER_ADDR }}
{{ var "/local/docker/swarm/join/token" SWARM_JOIN_TOKENS.Worker }}

{{ var "/local/infrakit/role/worker" true }}
{{ var "/local/infrakit/role/manager" false }}
{{ var "/local/infrakit/role/database" false }}

mount -t tmpfs tmpfs /tmp

{{ include "boot.sh" }}

# Append commands here to run other things that makes sense for workers
#docker pull ranlu/agglomeration:basil_10k
#docker pull ranlu/watershed:basil_10k
