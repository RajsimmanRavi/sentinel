FROM docker.elastic.co/beats/packetbeat:5.5.2
COPY packetbeat.yml /usr/share/packetbeat/packetbeat.yml
USER root
RUN chown packetbeat /usr/share/packetbeat/packetbeat.yml
USER packetbeat
