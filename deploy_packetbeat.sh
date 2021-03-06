#!/bin/bash

# Check if arguments given
if [[ ! $# -eq 2 ]] ; then
    echo "Error: you need to provide the IP address of Kafka Broker and Elasticsearch"
    exit 1
fi

KAFKA_IP="$1"
ELASTIC_IP="$2"

# make sure, the packetbeat.yml file has the following permissions: -rwx--x--x 
# if not, do this: sudo chmod 711 packetbeat.yml

PACKETBEAT_YML="/home/ubuntu/packetbeat.yml"
PACKETBEAT_DIR="/etc/packetbeat/"
# check if this directtory exists. If it does, then it must have been installed before
CHECK_CMD="[ -d '/etc/packetbeat' ] && echo 'Yes'"

INSTALL_PACKETBEAT="sudo apt-get install libpcap0.8 && curl -L -O https://artifacts.elastic.co/downloads/beats/packetbeat/packetbeat-5.5.2-amd64.deb && sudo dpkg -i packetbeat-5.5.2-amd64.deb"

CP_CMD="sudo cp /home/ubuntu/packetbeat.yml /etc/packetbeat/packetbeat.yml"
START_PACKETBEAT_CMD="sudo /etc/init.d/packetbeat start"

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

    # check if packetbeat is installed
    check_exists=`sudo docker-machine ssh $hostname $CHECK_CMD`
    if [ "$check_exists" != "Yes" ]
    then     
        # install packetbeat service on the node
        sudo docker-machine ssh $hostname $INSTALL_PACKETBEAT 
    fi

    # copy it to the appropriate /etc/packetbeat/ dir
    sudo docker-machine ssh $hostname $CP_CMD

    # start the packetbeat service 
    sudo docker-machine ssh $hostname $START_PACKETBEAT_CMD
    
    echo "Started Packetbeat service for node: $hostname"
done

#We still need to start the packetbeat container for this node itself
if [ ! -d "$PACKETBEAT_DIR" ];then    
    #install packetbeat service on the node
    sudo apt-get install libpcap0.8 && curl -L -O https://artifacts.elastic.co/downloads/beats/packetbeat/packetbeat-5.5.2-amd64.deb && sudo dpkg -i packetbeat-5.5.2-amd64.deb
fi

$CP_CMD
$START_PACKETBEAT_CMD

echo "Successfully deployed Packetbeat on all the nodes"
