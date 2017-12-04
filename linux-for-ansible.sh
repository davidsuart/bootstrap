#!/usr/bin/env bash
##
## SYNOPSIS
##   Install ansible & minimum python dependencies
## NOTES
##   Author: https://github.com/davidsuart
##   License: MIT License (See repository)
##   Requires:
##     - One of; Debian, Ubuntu, Mint
## LINK
##   Repository: https://github.com/davidsuart/bootstrap
##

# strict mode
set -o errexit -o nounset -o pipefail

# variables
distrib="unknown"

# functions
function identifyDistrib () {
  # This is unnecessarily harder than it should be -_-
  if [[ -f /etc/linuxmint/info ]]; then
    distrib="linuxmint"
  elif [[ -f /etc/lsb-release ]] && [[ "$(< /etc/lsb-release)" == *"DISTRIB_ID=LinuxMint"* ]]; then
    distrib="linuxmint"
  elif [[ -f /etc/lsb-release ]] && [[ "$(< /etc/lsb-release)" == *"DISTRIB_ID=Ubuntu"* ]]; then
    distrib="ubuntu"
  elif [[ -f /etc/os-release ]] && [[ "$(< /etc/os-release)" == *"ID=ubuntu"* ]]; then
    distrib="ubuntu"
  elif [[ -f /etc/os-release ]] && [[ "$(< /etc/os-release)" == *"ID=debian"* ]]; then
    distrib="debian"
  elif [[ -f /etc/debian_version ]]; then
    distrib="debian"
  else
    distrib="unknown"
  fi
  printf "Found distribution: [${distrib}] \n"
}

function installDebianPackages () {
  # python baseline packages
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends python=2.7* libpython2.7 libpython-stdlib \
                                                  python-pkg-resources python-setuptools python-six \
                                                  python-httplib2 python-jinja2 python-markupsafe python-yaml \
                                                  python-crypto python-cryptography python-ecdsa python-paramiko

  sudo apt-get install -y --no-install-recommends apt-transport-https ca-certificates software-properties-common
  sudo apt-add-repository -y ppa:ansible/ansible
  sudo apt-get update

  # Note: We put ansible *onto* the target to facilitate the 'ansible-pull' use case
  sudo apt-get install -y --no-install-recommends ansible sshpass openssh-server
}

# main
(
  set -e
  identifyDistrib
  if [[ "$distrib" == "ubuntu" || "$distrib" == "debian" || "$distrib" == "linuxmint" ]]; then
    installDebianPackages
  else
    printf "ERROR: This script currently supports only Debian/Ubuntu/Mint. \n"
    exit 1
  fi
)
# catch
exitCode=$?
if [ $exitCode -ne 0 ]; then
  printf "We encountered an error. \n"
  # Exit and pass on the error
  exit $exitCode
fi
