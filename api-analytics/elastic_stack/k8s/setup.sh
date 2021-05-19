#!/bin/bash
#
# Copyright © 2021. TIBCO Software Inc.
# This file is subject to the license terms contained
# in the license file that is distributed with this file.
#
kubectl create cm logstash-pipeline --from-file ../configs/logstash/logstash.conf
kubectl create cm es-idx-template --from-file ../configs/logstash/index_template.json
kubectl apply -f elastic/
kibana_container=$(kubectl get po -o jsonpath={'.items[?(@.metadata.labels.k8s-app=="kibana")].metadata.name'} )
echo "Kibana running in pod $kibana_container"
until [ `kubectl get po $kibana_container -o jsonpath={'.status.containerStatuses[?(@.name=="kibana")].ready'}` = "true" ]; do
    echo "Waiting for Kibana to start..."
    sleep 10;
done;
echo "Copying saved objects to Kibana"
kubectl cp ../configs/kibana/saved_objects/ $kibana_container:/tmp/
echo "Updating saved objects"
kubectl exec $kibana_container -- curl  --show-error -s -o /dev/null -X POST 'http://localhost:5601/api/saved_objects/_import?overwrite=true' -H 'kbn-xsrf: true' --form file=@/tmp/saved_objects/kibana_dashboards_7.12.0.ndjson
echo "----- Kibana Dashboard URL -----"
echo "http://<hostname/LB>:5601/app/dashboards"