#!/bin/bash
# ==================================================================
#  ______                           __
# /_  __/___  ____ ___  _________ _/ /_
#  / / / __ \/ __ `__ \/ ___/ __ `/ __/
# / / / /_/ / / / / / / /__/ /_/ / /_
#/_/  \____/_/ /_/ /_/\___/\__,_/\__/

# Multi-instance Apache Tomcat installation with a focus
# on best-practices as defined by Apache, SpringSource, and MuleSoft
# and enterprise use with large-scale deployments.

# ==================================================================
# standard variables
SCRIPT=$(readlink -f $0)
DIRECTORY=`dirname $SCRIPT`

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
	echo "Script creates or deletes a Tomcat 7 web instance by"
	echo "provisioning them from the shared/template folder."
	echo ""
	echo "usage:"
	echo "   $0 [create|delete] <port>"
	echo ""
	echo "examples:"
	echo "   $0 create 8080 -> Creates a new tomcat instance on port 8080"
	echo "   $0 delete 8080 -> Deletes the tomcat instance on port 8080"
	echo ""
	exit 1
}

# Download and install Tomcat
choose_tomcat_version() 
{
	echo ""
	echo "What version of tomcat would you like to provision:"
	cat VERSION | awk 'NR % 1 == 0' | awk '{ print "Enter [" $1 "] for " $2 }'
	echo -n "Enter your choice: "
	read -e CHOICE
	TOMCAT_VERSION=`cat $DIRECTORY/VERSION | grep ^$CHOICE | grep -oE apache.+`

	if [ -z $TOMCAT_VERSION ]; then
		echo "ERROR: Unable to identify the tomcat version you have selected, '$CHOICE' is not an option to choose from."
		exit 0
	fi

	echo "using '$TOMCAT_VERSION'..."

	export TOMCAT_VERSION="$TOMCAT_VERSION"
	if [ ! -d "$DIR/$TOMCAT_VERSION" ]; then
		wget https://github.com/downloads/terrancesnyder/tomcat/$TOMCAT_VERSION.zip --no-check-certificate --connect-timeout=10 --dns-timeout=5 -O $DIRECTORY/$TOMCAT_VERSION.zip
		RESULT=$?
		if [ ! $RESULT -eq 0 ]; then
			echo "Failed to download tomcat at https://github.com/downloads/terrancesnyder/tomcat/$TOMCAT_VERSION.zip"
			exit 0
		fi

		echo "Extracting Tomcat..."
		unzip $DIRECTORY/$TOMCAT_VERSION.zip
		echo "Removing downloaded zip..."
		rm -rf $DIRECTORY/$TOMCAT_VERSION.zip
		echo "Changing scripts to executable..."
		chmod +x $DIRECTORY/$TOMCAT_VERSION/bin/*.sh
	fi
}

# Ensure running as tomcat
if [ `whoami` != "tomcat" ]; then
	echo "error: you must be running as tomcat user"
	exit 0
fi

# Main
# if no arguments passed in
if [ $# -lt 1 ]; then
	usage
fi

if [ -z  "$1" -o -z "$2" ]; then
	usage
	exit 1
fi

IP=`ip addr show | grep 'global eth[0-9]' | grep -o 'inet [0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+' | grep -o '[0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+'`
HTTP_PORT=$2

# ask for tomcat version
export CATALINA_BASE="$DIRECTORY/$HTTP_PORT"

case $1 in
	create)
		if [ -d "$CATALINA_BASE" ]; then
			echo "error: the defined port is already claimed"
			exit 1
		fi

		logo

		choose_tomcat_version

		echo "[Step 1 of 2]: Creating new instance '$CATALINA_BASE'..."
		cp -R $DIRECTORY/shared/template $DIRECTORY/$HTTP_PORT
		sleep 2

		echo "[Step 2 of 3]: Setting Tomcat version to $TOMCAT_VERSION..."
		echo "$TOMCAT_VERSION" > $DIRECTORY/$HTTP_PORT/VERSION

		echo "[Step 3 of 3]: Starting tomcat instance '$CATALINA_BASE'..."
		$DIRECTORY/run.sh start $HTTP_PORT
		sleep 5

		echo "[Done]: Your tomcat instance is available via http://$IP:$HTTP_PORT/..."

		exit 0
	;;
	delete)
		if [ ! -d "$CATALINA_BASE" ]; then
			echo "error: that port does not exist to delete"
			exit 1
		fi

		logo
		echo "Removing tomcat instance '$CATALINA_BASE'"
		echo -n "Are you sure? [y/N]: "
		read -e CONFIRM

		case $CONFIRM in
			[yY]*)
				echo "Step [1 of 3]: Ensuring instance $HTTP_PORT is shutdown..."
				$DIRECTORY/run.sh stop $HTTP_PORT > /dev/null 2>&1
				sleep 1
				echo "Step [2 of 3]: Ensuring no orphaned tomcat instances are running..."
				ps aux | grep $DIRECTORY/$HTTP_PORT | grep -v grep | awk '{print $2}' | xargs kill -9 > /dev/null 2>&1
				sleep 1
				echo "Step [3 of 3]: Removing instance from file system..."
				rm -rf $CATALINA_BASE
				echo "(done)"
				exit 0
				;;
			[nN]*)
				exit "(aborted)"
				;;
			*)
				echo "(aborted)"
				;;
		esac
	;;
esac
exit 0
