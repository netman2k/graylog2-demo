#!/bin/bash
HOST_IP=$(ip addr show $(/sbin/ip route | awk '/default/ { print $5 }') | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
docker-compose up -d
