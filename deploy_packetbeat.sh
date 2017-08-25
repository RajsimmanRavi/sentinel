#!/bin/bash

# Check if arguments given
if [[ ! $# -eq 2 ]] ; then
    echo "Error: you need to provide the IP address of Kafka Broker and Elasticsearch"
    exit 1
fi

HOSTNAME=`hostname`
KAFKA_IP="$1"
ELASTIC_IP="$2"
PACKETBEAT_YML="/home/ubuntu/packetbeat.yml"

#remove the annoying 'sudo: unable to ...' warning 
sudo sed -i "s/127.0.0.1 .*/127.0.0.1 localhost $HOSTNAME/g" /etc/hosts

#check if packbetbeat docker container is running 
packetbeat_docker=`sudo docker ps | grep packetbeat`

#If the variable is empty, then docker container with 'packetbeat' string is not found. Hence, it is not installed.
#That's why I check if it's empty. 
if [ -z "$packetbeat_docker" ]
then 

    echo "
output.elasticsearch:
  hosts: ['$ELASTIC_IP:9200']

output.kafka:
  # initial brokers for reading cluster metadata
  hosts: ['$KAFKA_IP:9092']

  # message topic selection + partitioning
  topic: 'packetbeat'
  partition.round_robin:
  reachable_only: false

  required_acks: 1
  compression: gzip
  max_message_bytes: 1000000" >> $PACKETBEAT_YML
  
    echo "Packetbeat has been installed ad configured successfully!"

  #Command to run on each docker node after you scp the packetbeat.yml file
  #sudo docker run -d -v ~/packetbeat.yml:/usr/share/packetbeat/packetbeat.yml --restart always --cap-add=NET_ADMIN --net=host docker.elastic.co/beats/packetbeat:5.5.2
  
else 
    echo "Packetbeat has been installed and configured already!"
fi
