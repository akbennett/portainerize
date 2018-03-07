#!/bin/bash

# get files that you need to push onto the device
repo=https://github.com/OpenSourceFoundries/gateway-ansible

usage="
$(basename "$0") [-g] [-r] -- script to seed and load portainer on target system

where:
    -h  show this help text
    -s  override seed repository IP
    -g  override target IP/hostname

"

if [[ $# -eq 0 ]] ; then
    echo "$usage"
    exit 0
fi

str="./"$(basename "$0")

#process command-line options / overrides
while getopts ":g:r:" option; do
  case $option in
    g ) GW=${OPTARG} ; str="$str -g $GW";;
    s ) repo=${OPTARG} ;;
    * ) echo "$usage" ;
        exit ;;
  esac
done
shift $((OPTIND -1))
str="$str -s $repo"
echo ""
echo "Running as: $str"

#init
  # remove local seedfile repo
rm -rf seedfiles

#copy ssh credentials and netrc file
ssh-copy-id osf@$GW
if [ -f ~/.netrc ]; then  scp ~/.netrc osf@$GW:/home/osf/.netrc; fi

#seed with files to support containers
git clone $repo seedfiles
scp seedfiles/* osf@$GW:/home/osf

#run the portainer container
ssh osf@$GW "docker rm -f -v portainer"
ssh osf@$GW "docker run -d -p 9000:9000 --restart always --name portainer  -v \$PWD/portainer-data:/data -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer --logo https://foundries.io/static/img/logo.png --templates https://raw.githubusercontent.com/akbennett/portainer-templates/master/templates.json "

echo "browse to http://$GW:9000/#/init/admin"
