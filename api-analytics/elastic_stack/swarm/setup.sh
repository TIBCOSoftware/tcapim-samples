#!/bin/bash
#
# Copyright © 2021. TIBCO Software Inc.
# This file is subject to the license terms contained
# in the license file that is distributed with this file.
#
docker stack deploy -c docker-compose.yaml elk
# Check kibana container
while [ : ]
do
    status=$(docker service ls| grep "kibana")
    if [ $? -ne 0 ]; then
        break
    fi
    echo
    echo "Waiting for Kibana to start..."
    count=$(echo "$status" | grep "1/1" | wc -l)
    if [ $? -eq 0 ] && [ $count -eq 1 ]; then
        break
    fi
    sleep 10
done
kibana_container=$(docker ps | grep -i "kibana" | awk '{print $1}')
echo "Copying saved objects to Kibana"
docker cp ../configs/kibana/saved_objects/ $kibana_container:/tmp/
echo "Updating saved objects"
docker exec $kibana_container curl -s -o /dev/null --show-error -X POST 'http://localhost:5601/api/saved_objects/_import?overwrite=true' -H 'kbn-xsrf: true' --form file=@/tmp/saved_objects/kibana_dashboards_7.12.0.ndjson
echo "----- Kibana Dashboard URL -----"
echo "http://<hostname/LB>:5601/app/dashboards"