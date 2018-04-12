#!/bin/bash
#
# Automate the chef node bootstrap process.

_BLUE="\e[34m"
_RED="\e[31m"
_WHITE="\e[0m"

PROJECT_KEY="/share/project_key"

function error_message() {
  # Echo an error message to the screen
  # Args:
  #   $1: String, The message to echo
  if [[ "${1}" == "" ]]; then
    echo "error_message requires one argument"
  else
    echo -e "${_RED}[ERROR]${_WHITE} ${1}"
  fi
  exit 1
}

function info_message() {
  # Echo an error message to the screen
  # Args:
  #   $1: String, The message to echo
  if [[ "${1}" == "" ]]; then
    error_message "info_message requires one argument"
  else
    echo -e "${_BLUE}[INFO]${_WHITE} ${1}"
  fi
}

function usage() {
  printf "USAGE: $(basename "${0}") [options]

  This script is used to manage chef nodes. Please provide one of the available flags to execute.

  Options:
  -b, --bootstrap    bootstrap the chef nodes
  -u, --update       update the chef nodes\n"
}

function validate_config() {
  # Ensure knife is installed
  info_message "Checking for knife..."
  if [[ $(knife --version) =~ 'Chef' ]]; then
    info_message "Checking for knife ssl..."
  else
    error_message "Knife is not properly installed, please check the chefdk installation"
  fi

  # Check the knife ssl configuration
  message=$(knife ssl check)
  if [[ $? -eq 0 ]]; then
    info_message "Checking for cookbooks..."
  else
    error_message "ssl configuration has an error: ${message}"
  fi

  # Check for a successful cookbook list
  if [[ $(knife cookbook list) =~ 'chef_apache2' ]]; then
    info_message "Checking for the private ssh key..."
  else
    error_message "Knife cannot find the cookbooks please ensure you have uploaded the 'chef_apache2' cookbook"
  fi

  # Check for the private key
  if [[ -f $PROJECT_KEY ]]; then
    info_message "All checks are complete."
  else
    error_message "The private key: ${PROJECT_KEY} does not exist"
  fi
}

function bootstrap() {
  validate_config
  info_message "Time to bootstrap!"
  for i in $(seq 1 5); do
    NODE_IP=$i
    (( NODE_IP += 1))
    info_message "Bootstrapping 10.0.0.${NODE_IP} as node-${i}"
    knife bootstrap 10.0.0.$NODE_IP --ssh-user $USER --sudo --identity-file $PROJECT_KEY --node-name node-$i --run
-list 'recipe[chef_apache2]'
  done
}
function update() {
  validate_config
  info_message "Time to update!"
  for i in $(seq 1 5); do
    info_message "Updating node-${i}"
    knife ssh name:node-$i sudo chef-client --ssh-user $USER --identity-file $PROJECT_KEY --attribute ipaddress
  done
}
if [[ $# -gt 0 ]]; then
  case $1 in
    -b|--bootstrap)
      bootstrap;
      exit 0
      ;;
    -u|--update)
      update;
      exit 0
      ;;
    *)
      usage;
      exit 1
      ;;
  esac
else
  usage
  exit 1
fi