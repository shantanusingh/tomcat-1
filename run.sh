#!/bin/bash
# ==================================================================
#   ______                           __
#  /_  __/___  ____ ___  _________ _/ /_
#   / / / __ \/ __ `__ \/ ___/ __ `/ __/
#  / / / /_/ / / / / / / /__/ /_/ / /_
# /_/  \____/_/ /_/ /_/\___/\__,_/\__/

# Multi-instance Apache Tomcat installation with a focus
# on best-practices as defined by Apache, SpringSource, and MuleSoft
# and enterprise use with large-scale deployments.

# ==================================================================

# directory
SCRIPT=`perl -e 'use Cwd "abs_path";print abs_path(shift)' $0`
DIRECTORY=`dirname $SCRIPT`

# user arguments
ACTION="$1"
HTTP_PORT="$2"

# IP ADDRESS OF CURRENT MACHINE
if hash ip 2>&-
then
	IP=`ip addr show | grep 'global eth[0-9]' | grep -o 'inet [0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+' | grep -o '[0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+'`
else
	IP=`ifconfig | grep 'inet [0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+.*broadcast' | grep -o 'inet [0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+' | grep -o '[0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+'`
fi


# Friendly Logo
logo()
{
	echo ""
	echo "  ______                           __    "
	echo " /_  __/___  ____ ___  _________ _/ /_   "
	echo "  / / / __ \/ __  __ \/ ___/ __  / __/   "
	echo " / / / /_/ / / / / / / /__/ /_/ / /_     "
	echo "/_/  \____/_/ /_/ /_/\___/\__,_/\__/     "
	echo "                                         "
	echo "                                         "
}

# Help
usage()
{
	logo
	echo "Script starts and stops a Tomcat web instance by "
	echo "invoking the standard $CATALINA_HOME/bin/catalina.sh file."
	echo ""
	echo "usage:"
	echo "   $0 [stop|start] <port>"
	echo ""
	echo "examples:"
	echo "   $0 start 8080 -> Starts the tomcat instance configured for port 8080"
	echo "   $0 stop 8080  -> Stops the tomcat instance configured for port 8080"
	echo ""
	exit 1
}

if [ -z  "$1" -o -z "$2" ]; then
  usage
  exit 0
fi

#if [ `whoami` != "tomcat" ]; then
#  echo "error: you are not running under the tomcat user"
#  exit 1
#fi

if [ -z "$JAVA_HOME" ]; then
   echo "error: JAVA_HOME is not set"
   exit 1
fi

#if [ -z "$JRE_HOME" ]; then
#   echo "error: JRE_HOME is not set"
#   exit 1
#fi

SHUTDOWN_PORT=$(($HTTP_PORT+1))
JMX_PORT=$(($HTTP_PORT+2))
JPDA_PORT=$(($HTTP_PORT+3))

# grab tomcat version from provisioned directory
TOMCAT_VERSION=`cat $DIRECTORY/$HTTP_PORT/VERSION | sed -n '1p'`
# get tomcat major version number
TOMCAT_MAJOR_VERSION=`cat $DIRECTORY/$HTTP_PORT/VERSION | sed -n '1p' | grep -oE apache\-tomcat\-[0-9] | grep -oE [0-9]`

export JPDA_ADDRESS="$JPDA_PORT"
export JPDA_TRANSPORT="dt_socket"
export CATALINA_BASE="$DIRECTORY/$HTTP_PORT"
export CATALINA_HOME="$DIRECTORY/$TOMCAT_VERSION"
export CATALINA_CONF="$DIRECTORY/shared/tc$TOMCAT_MAJOR_VERSION/server.xml"
export CATALINA_PID="$CATALINA_BASE/logs/catalina.pid"

export LOGGING_CONFIG="-Djava.util.logging.config.file=$DIRECTORY/shared/tc$TOMCAT_MAJOR_VERSION/logging.properties"

if [ ! -d "$CATALINA_BASE" ]; then
  echo "error: the configured folder does not exist '$CATALINA_BASE'"
  exit -1
fi

# check for additional options supplied (just like tomcat)
# for server level configuration options applied to all
# containers
if [ -r "$DIRECTORY/setenv.sh" ]; then
  . "$DIRECTORY/setenv.sh"
fi


# default jmx options - secured by default
export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote"
export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.port=$JMX_PORT"
export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.ssl=false"
export CATALINA_OPTS="$CATALINA_OPTS -Djava.rmi.server.hostname=$IP"
export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.authenticate=false"

# uncomment the below in production to protect access to JMX
# export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.access.file=$DIRECTORY/shared/jmxremote.access"
# export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.password.file=$DIRECTORY/shared/jmxremote.password"

# java opts are primary and we need these to define the http ports
export JAVA_OPTS="$JAVA_OPTS -Dhttp.port=$HTTP_PORT"
export JAVA_OPTS="$JAVA_OPTS -Dshutdown.port=$SHUTDOWN_PORT"

# avoid problem we secure ID generation taking a long time
export JAVA_OPTS="$JAVA_OPTS -Djava.security.egd=file:/dev/./urandom"

# endorsed folder
export JAVA_ENDORSED_DIRS="$DIRECTORY/shared/endorsed"

# print friendly logo and information useful for debugging
logo

echo "IP: $IP | HTTP: $HTTP_PORT | JPDA Port: $JPDA_PORT | JMX Port: $JMX_PORT"
echo "_______________________________________________"
echo ""

# start/stop commands directed to the standard catalina out folder
exec "$CATALINA_HOME/bin/catalina.sh" "$ACTION" -config $CATALINA_CONF

Tomcat

/S

