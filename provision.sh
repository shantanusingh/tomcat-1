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

# ==================================================================

# Friendly Logo
logo()
{
	echo ""
	echo "  ______                           __     _____"
	echo " /_  __/___  ____ ___  _________ _/ /_   /__  /"
	echo "  / / / __ \/ __  __ \/ ___/ __  / __/     / / "
	echo " / / / /_/ / / / / / / /__/ /_/ / /_      / /  "
	echo "/_/  \____/_/ /_/ /_/\___/\__,_/\__/     /_/   "
	echo "                                               "
	echo "                                               "
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

IP="$( ifconfig eth0 | awk '/inet addr/ {split ($2,A,":"); print A[2]}' )"
HTTP_PORT=$2

# standard variables
SCRIPT=$(readlink -f $0)
DIRECTORY=`dirname $SCRIPT`

# ask for tomcat version
export CATALINA_BASE="$DIRECTORY/$HTTP_PORT"

case $1 in
	create)
		if [ -d "$CATALINA_BASE" ]; then
			echo "error: the defined port is already claimed"
			exit 1
		fi

		logo
		echo "[Step 1 of 2]: Creating new instance '$CATALINA_BASE'..."
		cp -R $DIRECTORY/shared/template $DIRECTORY/$HTTP_PORT
		sleep 2

		echo "[Step 2 of 2]: Starting tomcat instance '$CATALINA_BASE'..."
		$DIRECTORY/run.sh start $HTTP_PORT
		sleep 5

		# echo ""
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
