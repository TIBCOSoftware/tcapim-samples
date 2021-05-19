#!/bin/bash
#
# Copyright © 2021. TIBCO Software Inc.
# This file is subject to the license terms contained
# in the license file that is distributed with this file.
#
kubectl delete cm logstash-pipeline es-idx-template
kubectl delete statefulset elasticsearch  
kubectl delete deploy logstash kibana
kubectl delete svc elasticsearch kibana logstash

