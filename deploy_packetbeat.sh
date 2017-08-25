#!/bin/bash

# Check if arguments given
if [[ ! $# -eq 2 ]] ; then
    echo "Error: you need to provide the IP address of Kafka Broker and Elasticsearch"
    exit 1
fi

KAFKA_IP="$1"
ELASTIC_IP="$2"
PACKETBEAT_YML="/home/ubuntu/packetbeat.yml"
DOCKER_CMD="sudo docker run -d -v ~/packetbeat.yml:/usr/share/packetbeat/packetbeat.yml --restart always --cap-add=NET_ADMIN --net=host --name packetbeat docker.elastic.co/beats/packetbeat:5.5.2"

# First, insert ELASTIC_IP
sed -i "s/hosts: \[\".*:9200\"\]/hosts: \[\"$ELASTIC_IP:9200\"\]/g" $PACKETBEAT_YML

# Second, insert KAFKA_IP  
sed -i "s/hosts: \[\".*:9092\"\]/hosts: \[\"$KAFKA_IP:9092\"\]/g" $PACKETBEAT_YML


# Ok, the command is huge. Let me break it down.
# "docker node ls" gives us the nodes and it's hostnames.
# awk {print $2" "$3} gives us only the hostnames.
# sed 's/*//g' removes the asterisk
# sed 's/Ready//g' removes the string "Ready" because we had that when we printed $3
# sed 's/HOSTNAME//g' removes the string "HOSTNAME" from the title of the output
# sed 's/STATUS//g' removes the string "STATUS" from the title of the output
# sed '/^$/d'` removes empty lines from the output

# Hence this provides only the hostnames of the nodes we want to deploy dockbeat and metricbeat.
# Store this in an array
NODES=( $(sudo docker node ls | awk '{print $2}' | sed 's/*//g' | sed 's/Ready//g' |sed 's/HOSTNAME//g' | sed 's/STATUS//g'| sed '/^$/d') )

for hostname in "${NODES[@]}"
do
    # send the packetbeat.yml file to the node
    sudo docker-machine scp $PACKETBEAT_YML $hostname:~

    # start the packetbeat docker container 
    sudo docker-machine ssh $hostname $DOCKER_CMD 
    
    echo "Started Packetbeat container for node: $hostname"
done

#We still need to start the packetbeat container for this node itself
$DOCKER_CMD

echo "Successfully deployed Packetbeat on all the containers"
