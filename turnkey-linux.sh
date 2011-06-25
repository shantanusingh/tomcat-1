#!/bin/bash

logo() {
	echo "  ______                 __                 __    _                 "
	echo " /_  __/_  ___________  / /_____  __  __   / /   (_)___  __  ___  __"
	echo "  / / / / / / ___/ __ \/ //_/ _ \/ / / /  / /   / / __ \/ / / / |/_/"
	echo " / / / /_/ / /  / / / / ,< /  __/ /_/ /  / /___/ / / / / /_/ />  <  "
	echo "/_/  \__,_/_/  /_/ /_/_/|_|\___/\__, /  /_____/_/_/ /_/\__,_/_/|_|  "
	echo "                               /____/                               "
	echo ""

	# ensure java on path
	source /etc/profile
}

usage() {
	logo
	echo "Script creates the default appliance based version of a Java Application"
	echo "server for minimal footprint installations. This is usueful for cloud based"
	echo "or 'just-enough' operating systems."
	echo ""
	echo "usage:"
	echo "   $0 [install|configure|remove]"
	echo ""
	echo "examples:"
	echo "   $0 install   -> installs the required software for running this appliance"
	echo "   $0 configure -> configures this installation"
	echo "   $0 remove    -> removes all configuration for this installation"
	exit 0
}

# check args passed, if NULL then display usage
if [ $# -lt 1 ]; then
	usage
fi

# get current directory
SCRIPT=$(readlink -f $0)
DIR=`dirname $SCRIPT`

case $1 in
	install)
		logo

		# ensure minimal software packages
		sudo apt-get install htop nano haproxy unrar rar unzip zip curl

		if [ ! -f "$DIR/jdk-6u26-linux-x64.bin" ]; then
			echo "Downloading java x64..."
			wget http://download.oracle.com/otn-pub/java/jdk/6u26-b03/jdk-6u26-linux-x64.bin
		fi

		if [ ! -d "$DIR/jdk1.6.0_26" ]; then
			echo "Extracting java..."
			chmod +x jdk-6u26-linux-x64.bin
			echo 'y' > java-license-agreement.txt
			./jdk-6u26-linux-x64.bin < java-license-agreement.txt &> /dev/null
			rm java-license-agreement.txt
		fi

		if [ ! -f "$DIR/tomcat.zip" ]; then
			echo "Getting latest Apache Tomcat..."
			wget https://github.com/downloads/terrancesnyder/tomcat/tomcat.zip -O tomcat.zip
		fi

		if [ ! -d "$DIR/tomcat" ]; then
			echo "Extracting Apache Tomcat..."
			unzip tomcat.zip -d ./
		fi

		exit 0
	;;
	configure)
		logo

		# ensure install was completed
		if [ ! -d "$DIR/tomcat" ]; then
			echo "You must run './$0 install' first..."
			exit 0
		fi
		if [ ! -d "$DIR/jdk1.6.0_26" ]; then
			echo "You must run './$0 install' first..."
			exit 0
		fi

		if [ ! -d "/opt/dev" ]; then
			echo "Creating /opt/dev/ folder..."
			sudo mkdir /opt/dev
			sudo chmod 777 /opt/dev
		fi

		if [ ! -d "/opt/dev/java" ]; then
			echo "Configuring java..."
			sudo cp -R $DIR/jdk1.6.0_26 /opt/dev/java
		fi

		if [ ! -d "/opt/dev/tomcat" ]; then
			echo "Configuring tomcat..."
			sudo cp -R $DIR/tomcat /opt/dev/tomcat
		fi

		TOMCAT_GROUP=`grep "^tomcat" /etc/group`
		if [ -z "$TOMCAT_GROUP" ]; then
			echo "Creating tomcat group..."
			sudo groupadd tomcat
		fi

		TOMCAT_USER=`grep "^tomcat:" /etc/passwd`
		if [ -z "$TOMCAT_USER" ]; then
			echo "Creating tomcat user..."
			sudo useradd -g tomcat -c "Apache Tomcat Application" -s /bin/bash tomcat
			echo "Password for tomcat user?"
			sudo passwd tomcat
		fi

		sudo chown -R tomcat:users /opt/dev
		sudo chmod +x /opt/dev/tomcat/*.sh
		sudo chmod +x /opt/dev/tomcat/shared/template/bin/*.sh

		if [ ! -f "/etc/profile.d/turnkey-linux.sh" ]; then
			sudo touch /etc/profile.d/turnkey-linux.sh
			sudo chmod 777 /etc/profile.d/turnkey-linux.sh
			sudo chown tomcat:users /etc/profile.d/turnkey-linux.sh
			sudo echo "export JAVA_HOME=\"/opt/dev/java\"" >> /etc/profile.d/turnkey-linux.sh
			sudo echo "export JRE_HOME=\"/opt/dev/java\"" >> /etc/profile.d/turnkey-linux.sh
			sudo echo "export PATH=\"\$JAVA_HOME/bin:\$PATH\"" >> /etc/profile.d/turnkey-linux.sh
		fi

		exit 0
	;;
	remove)
		logo

		echo "Removing turnkey-linux will result in:"
		echo ""
		echo "  -> All tomcat instances will STOP and then be DELETED in /opt/dev/tomcat"
		echo "  -> /opt/dev/java will be DELETED"
		echo "  -> /etc/profile.d/turnkey-linux.sh will be DELETED"
		echo "  -> 'tomcat' user being removed from the system"
		echo "  -> 'tomcat' group being removed from the system"
		echo ""
		echo "Are you sure? [y/N]:"
		read -e CONFIRMATION

		case $CONFIRMATION in
			[yY]*)
				if [ -f "/etc/profile.d/turnkey-linux.sh" ]; then
					sudo rm /etc/profile.d/turnkey-linux.sh
				fi
				if [ -d "/opt/dev/tomcat" ]; then
					echo "Ensuring tomcat is shutdown..."
					sudo /opt/dev/tomcat/server.sh stop
					echo "Removing /opt/dev/tomcat..."
					sudo rm -rf /opt/dev/tomcat
				fi
				if [ -d "/opt/dev/java" ]; then
					echo "Removing /opt/dev/java..."
					sudo rm -rf /opt/dev/java
				fi

				TOMCAT_USER=`grep "^tomcat:" /etc/passwd`
				TOMCAT_GROUP=`grep "^tomcat" /etc/group`

                                if [ ! -z "$TOMCAT_USER" ]; then
                                        echo "Removing tomcat user..."
                                        sudo userdel tomcat > /dev/null 2>&1
                                fi

				if [ ! -z "$TOMCAT_GROUP" ]; then
					echo "Removing tomcat group..."
					sudo groupdel tomcat > /dev/null 2>&1
				fi
				exit 0
			;;
			*)
				echo "(aborted)"
				exit 0
				;;
		esac
	;;
esac
exit 0
