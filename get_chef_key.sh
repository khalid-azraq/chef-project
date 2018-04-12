#!/bin/bash
#
# This script copies over the chefadmin.pem file to the localhost.
set -e
function metadata_value() {
  curl --retry 5 -sfH "Metadata-Flavor: Google" \
    "http://metadata.google.internal/computeMetadata/v1/$1"
}
function server_name() {
  metadata_value "instance/attributes/server-name"
}
function project_name() {
  metadata_value "project/project-id"
}
function copy_chef_key() {
  scp -o StrictHostKeyChecking=no -i /share/project_key "$(server_name).c.$(project_name).internal:/share/chefadmin
.pem" /share/.chef/chefadmin.pem
}
copy_chef_key || exit $?