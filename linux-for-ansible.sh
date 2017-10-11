#!/usr/bin/env bash
set -e -x

#
# [ABOUT]
# - Install ansible & minimum python dependencies
#
# [ASSUMPTIONS]
# - That we only use Ubuntu :-/
#

dist=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`

if [ "$dist" == "Ubuntu" ]; then

  printf "Found: Ubuntu \n"

  sudo apt-get update
  sudo apt-get install -y --no-install-recommends apt-transport-https ca-certificates software-properties-common
  sudo apt-add-repository -y ppa:ansible/ansible
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends python=2.7* libpython2.7
  sudo apt-get install -y --no-install-recommends libpython-stdlib python-pkg-resources python-setuptools python-six \
                                                  python-httplib2 python-jinja2 python-markupsafe python-yaml \
                                                  python-crypto python-ecdsa python-paramiko
  sudo apt-get install -y --no-install-recommends ansible sshpass
  sudo apt-get install -y openssh-server

else

  printf "This is (Currently) only intended for Ubuntu \n"
  exit 1

fi
