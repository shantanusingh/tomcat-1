#! /bin/sh
# Licensed to the Apache Software Foundation (ASF).

# handles the automatic startup/shutdown
# of any tomcat instance within the tomcat
# folder. an instance is based on convention
# that a folder that hosts the specified instance
# is named the same as the port number wanted.

# For example: ./8080; ./8181; ./8282

# Will trigger the following commands to be run:
# ./run.sh 8080 start
# ./run.sh 8181 start
# ./run.sh 8282 start

ACTION="$1"

if [ -z  "$1" ]; then
  echo "usage: server.sh [start|stop]"
  exit 0
fi

# directory
SCRIPT=$(readlink -f $0)
DIRECTORY=`dirname $SCRIPT`

# grab all directories that look like port numbers
ports=$(ls -p $DIRECTORY | awk -F'[_/]' '/^[0-9]/ {print $1}')

# issue action against those ports
for port in $ports
do
	$DIRECTORY/run.sh $port "$ACTION" > /dev/null 2>&1
done

