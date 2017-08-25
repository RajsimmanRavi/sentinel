#!/bin/bash

# Check if arguments given
if [[ $# -eq 0 ]] ; then
    echo "Error: you need to provide the IP address of Elasticsearch's Host"
    exit 1
fi

SCRIPTS_DIR="/home/ubuntu"
COMPOSE_DIR="$SCRIPTS_DIR/docker_compose"

ELASTIC_IP="$1"

#Now, replace the url in ek-compose.yml to the ELASTIC_IP
sed -i "s/ELASTICSEARCH_URL=.*/ELASTICSEARCH_URL=http:\/\/$ELASTIC_IP:9200/g" $COMPOSE_DIR/ek_compose.yml
        
echo "Deploying EK services"

sudo docker stack deploy -c $COMPOSE_DIR/ek_compose.yml EK_monitor

echo "Waiting for Elasticsearch to be up and running"

$SCRIPTS_DIR/sleep_bar.sh 60

#check if succeeded or failed. If it failed to import, re-deploy EK again
port_open=`nc -w 5 $ELASTIC_IP 9200 </dev/null; echo $?`    

if [[ $port_open == "1" ]]
then
    echo "Failed to deploy Elasticsearch and Kibana because Elasticsearch port (9200) not open"
    echo "Hence, re-deploying EK"
    sudo docker stack rm EK_monitor

    $SCRIPTS_DIR/sleep_bar.sh 10

    sudo docker stack deploy -c $COMPOSE_DIR/ek_compose.yml EK_monitor
fi

echo "Completed ELK deployment"
