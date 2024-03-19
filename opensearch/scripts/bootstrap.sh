#!/bin/bash
#
# Copyright © 2024. TIBCO Software Inc.
# This file is subject to the license terms contained
# in the license file that is distributed with this file.
#
source ../application_conf/input.properties
source ../application_conf/stack.properties

base_url() {
  echo "${3}://${1}:${2}"
}

acquire_cookies() {
  curl -k \
    -X POST "$1/${auth_endpoint}" \
    -H "Content-Type: application/json" \
    -H "osd-xsrf: true" \
    -d "{\"username\": \"${dashboard_username}\", \"password\": \"${dashboard_password}\"}" \
    -c auth.txt
    }


process_type() {
  local file

  for file in ${1}; do
    if [ -f "${file}" ]; then
      echo "----------------------------------------------"
      echo "Processing ${file##*/} of type ${1}"
      process_file "${file}" "${2}" "$(get_url "${file}" "${2}" "${3}")" "${4}"
      echo "Processed ${file##*/}"
      echo "----------------------------------------------"
    fi
  done
}

process_file() {
  echo "Processing file: ${1##*/} with {method: ${2}, endpoint: ${3}}"

  if [[ ${4} == "true" ]]; then
    curl -s -k \
      -X "${2}" "${3}" \
      -H "osd-xsrf:true" \
      -X "${2}" "${3}" \
      -b auth.txt \
      -u "${dashboard_username}":"${dashboard_password}" \
      --form file=@"${1}"
    echo ""
  else
    content=$(replace_variables "$(cat ${1})")
    request "${2}" "${3}" "${content}" "${opensearch_username}" "${opensearch_password}"
  fi
}

request() {
  http_response=$(curl -s -k -i \
    -H "osd-xsrf:true" \
    -X "${1}" "${2}" \
    -u "${4}":"${5}"  \
    -H "Content-Type: application/json" \
    -d "${3}")

  echo "Response: ${http_response}"
  echo ""
}

get_url(){
  if [[ ${2} == "PUT" ]]; then
    echo "${3}/${1##*/}"
  else
    echo "${3}"
  fi
}

process_object() {
  http_method=$(object_http_method "${1}")
  object_endpoint=$(object_endpoint "${1}")
  object_directory="${opensearch_config_directory}/${1}/*"

  process_type "${object_directory}" "${http_method}" "$2/${object_endpoint}" ${3}
}

main() {
  local opensearch_endpoint
  local dashboard_endpoint
  local object

  opensearch_endpoint=$(base_url "${opensearch_host}" "${opensearch_port}" "${opensearch_protocol}")
  dashboard_endpoint=$(base_url "${dashboard_host}" "${dashboard_port}" "${dashboard_protocol}")

  echo "Opensearch endpoint: ${opensearch_endpoint}"
  echo "Dashboard endpoint: ${dashboard_endpoint}"

  echo "Processing opensearch and dashboard objects..."

  for object in ${opensearch_objects//,/ }; do
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "Processing ${object}"
    is_dir "${opensearch_config_directory}"/"${object}"
    process_object "${object}" "${opensearch_endpoint}" "false"
    echo "Processed ${object} successfully"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  done

  if [[ ${#dashboard_objects} -gt 0 ]] ; then
    echo "Saved objects are enabled.. Acquiring cookies"
    acquire_cookies "${dashboard_endpoint}"
    echo "cookies acquired"

    for object in ${dashboard_objects//,/ }; do
      echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      echo "Processing ${object}"
      is_dir "${opensearch_config_directory}"/"${object}"
      process_object "${object}" "${dashboard_endpoint}" "true"
      echo "Processed ${object} successfully"
      echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    done
  fi

}

replace_variables() {
  local content=${1}
  local matches

  matches=$(get_matches "${content}")

  while read -r match; do
    placeholder="<%=${match}%>"
    if [ -n "${match}" ] && [ "${match}" != " " ]; then
      content=${content//${placeholder}/${!match}}
    fi
   done <<< "${matches}"

   echo "${content}"
}

get_matches() {
  local content=${1}

  echo "${1}" \
  | grep -o '<%=[^%]*%>' \
  | awk -F '<%=' '{print $2}' \
  | awk -F '%>' '{print $1}'
}

object_endpoint() {
  local object_url=${1}"_endpoint"
  echo "${!object_url}"
}

object_http_method() {
  local http_method=${1}"_http_method"
  echo "${!http_method}"
}

is_dir() {
  local dir=${1}

  [[ -d ${dir} ]]
}

main "$@"
