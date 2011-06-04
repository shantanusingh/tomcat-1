#!/bin/bash
# ==================================================================
#  ______                           __     _____
# /_  __/___  ____ ___  _________ _/ /_   /__  /
#  / / / __ \/ __ `__ \/ ___/ __ `/ __/     / /
# / / / /_/ / / / / / / /__/ /_/ / /_      / /
#/_/  \____/_/ /_/ /_/\___/\__,_/\__/     /_/

# Multi-instance Apache Tomcat installation with a focus
# on best-practices as defined by Apache, SpringSource, and MuleSoft
# and enterprise use with large-scale deployments.

# Credits:
#       Google -> Couldn't survive without it
#       Stackoverflow.com -> Community support
#       SpringSource -> Specifically best-practices and seminars (Expert Series)

# Based On:
#       http://www.springsource.com/files/uploads/tomcat/tomcatx-performance-tuning.pdf
#       http://www.springsource.com/files/u1/PerformanceTuningApacheTomcat-Part2.pdf
#       http://www.springsource.com/files/uploads/tomcat/tomcatx-large-scale-deployments.pdf

# Created By: Terrance A. Snyder
# URL: http://www.terranceasnyder.com, http://shutupandcode.net

# Best Practice Documentation:
# http://terranceasnyder.com/2011/05/tomcat-best-practices/

# Looking for the latest version?
# github @ https://github.com/terrancesnyder

# ==================================================================

# default tomcat version
TOMCAT_VERSION="apache-tomcat-7.0.14"

# ensure we always grab the current shell scripts
source ~/.bashrc

# user arguments
HTTP_PORT="$1"
ACTION="$2"
IP="$( ifconfig eth0 | awk '/inet addr/ {split ($2,A,":"); print A[2]}' )"

# directory
SCRIPT=$(readlink -f $0)
DIRECTORY=`dirname $SCRIPT`

if [ -z  "$1" -o -z "$2" ]; then
  echo "usage: run.sh <configuration> [start|stop]"
  exit -1
fi

if [ `whoami` != "tomcat" ]; then
  echo "error: you are not running under the tomcat user"
  exit -1
fi

SHUTDOWN_PORT=$(($HTTP_PORT+1))
JMX_PORT=$(($HTTP_PORT+2))
JPDA_PORT=$(($HTTP_PORT+3))

export JRE_HOME="/opt/dev/java"
export JAVA_HOME="/opt/dev/java"
export JPDA_ADDRESS="$JPDA_PORT"

export JPDA_TRANSPORT="dt_socket"
export CATALINA_BASE="$DIRECTORY/$HTTP_PORT"
export CATALINA_HOME="$DIRECTORY/$TOMCAT_VERSION"
export CATALINA_CONF="$DIRECTORY/shared/server.xml"
export CATALINA_PID="$CATALINA_BASE/logs/catalina.pid"

export LOGGING_CONFIG="-Djava.util.logging.config.file=$DIRECTORY/shared/logging.properties"

# check if tomcat installed if not download it
if [ ! -d "$DIRECTORY/$TOMCAT_VERSION" ]; then
	echo "Downloading Apache Tomcat 7.0.14 from Apache..."
	wget http://www.carfab.com/apachesoftware/tomcat/tomcat-7/v7.0.14/bin/apache-tomcat-7.0.14.zip > /dev/null
	echo "Extracting Tomcat..."
	unzip apache-tomcat-7.0.14.zip
	echo "Removing downloaded zip..."
	rm -rf apache-tomcat-7.0.14.zip
	echo "Changing scripts to executable..."
	chmod +x ./apache-tomcat-7.0.14/bin/*.sh
fi

if [ ! -d "$CATALINA_BASE" ]; then
  echo "error: the configured folder does not exist '$CATALINA_BASE'"
  exit -1
fi

# default jmx options - secured by default
export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote"
export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.port=$JMX_PORT"
export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.ssl=false"
export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.authenticate=false"
export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.access.file=$DIRECTORY/shared/jmxremote.access"
export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.password.file=$DIRECTORY/shared/jmxremote.password"
export CATALINA_OPTS="$CATALINA_OPTS -Djava.rmi.server.hostname=$IP"

# java opts are primary and we need these to define the http ports
export JAVA_OPTS="$JAVA_OPTS -Dhttp.port=$HTTP_PORT"
export JAVA_OPTS="$JAVA_OPTS -Dshutdown.port=$SHUTDOWN_PORT"

echo ""
echo "  ______                           __     _____"
echo " /_  __/___  ____ ___  _________ _/ /_   /__  /"
echo "  / / / __ \/ __  __ \/ ___/ __  / __/     / / "
echo " / / / /_/ / / / / / / /__/ /_/ / /_      / /  "
echo "/_/  \____/_/ /_/ /_/\___/\__,_/\__/     /_/   "
echo "                                               "
echo "                                               "

echo "IP: $IP | HTTP: $HTTP_PORT | JPDA Port: $JPDA_PORT | JMX Port: $JMX_PORT"
echo "_______________________________________________"
echo ""

exec "$CATALINA_HOME/bin/catalina.sh" jpda "$ACTION" -config $CATALINA_CONF

Tomcat

/S

