{{ source "common.ikt" }}
echo # Set up infrakit.  This assumes Docker has been installed
{{ $infrakitHome := `/infrakit` }}
mkdir -p {{$infrakitHome}}/configs
mkdir -p {{$infrakitHome}}/logs
mkdir -p {{$infrakitHome}}/plugins

# dockerImage  {{ $dockerImage := var "/infrakit/docker/image" }}
# dockerMounts {{ $dockerMounts := `-v /var/run/docker.sock:/var/run/docker.sock -v /infrakit:/infrakit` }}
# dockerEnvs   {{ $dockerEnvs := `-e INFRAKIT_HOME=/infrakit -e INFRAKIT_PLUGINS_DIR=/infrakit/plugins`}}


echo "Cluster {{ var `/cluster/name` }} size is Manager: {{ var `/cluster/size/manager` }}, Worker: {{ var `/cluster/size/worker` }}"
echo "alias infrakit='docker run --rm {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} infrakit'" >> /root/.bashrc

alias infrakit='docker run --rm {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} infrakit'

echo "Starting up infrakit  ######################"
docker run -d --restart always --name infrakit -p 24864:24864 {{ $dockerMounts }} {{ $dockerEnvs }} \
       -v /var/log/:/var/log \
       -e INFRAKIT_AWS_STACKNAME={{ var `/cluster/name` }} \
       -e INFRAKIT_AWS_METADATA_POLL_INTERVAL=300s \
       -e INFRAKIT_AWS_METADATA_TEMPLATE_URL={{ var `/infrakit/metadata/configURL` }} \
       -e INFRAKIT_AWS_NAMESPACE_TAGS=infrakit.scope={{ var `/cluster/name` }} \
       -e INFRAKIT_GOOGLE_NAMESPACE_TAGS=infrakit.scope={{ var `/cluster/name` }} \
       -e INFRAKIT_MANAGER_BACKEND=swarm \
       -e INFRAKIT_ADVERTISE={{ var `/local/swarm/manager/logicalID` }}:24864 \
       -e INFRAKIT_CLIENT_TIMEOUT='60s' \
       -e INFRAKIT_TAILER_PATH=/var/log/cloud-init-output.log \
       {{$dockerImage}} \
       infrakit plugin start manager group vars combo swarm time tailer ingress kubernetes {{ var `/cluster/provider` }} \
       --log 5 --log-debug-V 900

# Need time for plugins (namely var) to load properly
sleep 10

# Need time for leadership to be determined.
sleep 30

echo "Update the vars in the metadata plugin -- we put this in the vars plugin for queries later."
docker run --rm {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} \
       infrakit vars change -c \
       cluster/provider={{ var `/cluster/provider` }} \
       cluster/name={{ var `/cluster/name` }} \
       infrakit/config/root={{ var `/infrakit/config/root` }} \
       infrakit/docker/image={{ var `/infrakit/docker/image` }} \
       infrakit/metadata/configURL={{ var `/infrakit/metadata/configURL` }} \
       provider/image/hasDocker={{ var `/provider/image/hasDocker` }} \
       cluster/swarm/manager/ips/0={{ var `/cluster/swarm/manager/ips/0` }} \
       cluster/swarm/manager/ips/1={{ var `/cluster/swarm/manager/ips/1` }} \
       cluster/swarm/manager/ips/2={{ var `/cluster/swarm/manager/ips/2` }} \
       cluster/swarm/manager/ips/3={{ var `/cluster/swarm/manager/ips/3` }} \
       cluster/swarm/manager/ips/4={{ var `/cluster/swarm/manager/ips/4` }} \
       cluster/size/manager={{ var `/cluster/size/manager` }} \
       cluster/size/worker={{ var `/cluster/size/worker` }} \
       cluster/instanceType/manager={{ var `/cluster/instanceType/manager` }} \
       cluster/instanceType/worker={{ var `/cluster/instanceType/worker` }} \
       cluster/tag/user={{ var `/cluster/tag/user` }} \
       cluster/tag/project={{ var `/cluster/tag/project` }} \


echo "Rendering a view of the config groups.json for debugging."
docker run --rm {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} infrakit template {{var `/infrakit/config/root`}}/groups.json

#Try to commit - this is idempotent but don't error out and stop the cloud init script!
echo "Commiting to infrakit $(docker run --rm {{$dockerMounts}} {{$dockerEnvs}} {{$dockerImage}} infrakit manager commit {{var `/infrakit/config/root`}}/groups.json)"
