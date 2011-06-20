#    _____ ____  __    ____
#   / ___// __ \/ /   / __ \
#   \__ \/ / / / /   / /_/ /
#  ___/ / /_/ / /___/ _, _/
# /____/\____/_____/_/ |_|
#

# directory
SCRIPT=$(readlink -f $0)
DIRECTORY=`dirname $SCRIPT`

# Friendly Logo
logo()
{
	echo "    _____ ____  __    ____                     "
	echo "   / ___// __ \/ /   / __ \                    "
	echo "   \__ \/ / / / /   / /_/ /                    "
	echo "  ___/ / /_/ / /___/ _, _/                     "
	echo " /____/\____/_____/_/ |_|                      "
        echo "                                               "
}

# Help
usage()
{
        logo
        echo "Script creates a new instance of solr. "
        echo ""
        echo "usage:"
        echo "   $0 <port>"
        echo ""
        echo "examples:"
        echo "   $0 8080 -> Provisions a new solr instance on port 8080"
        echo ""
        exit 1
}

if [ -z  "$1" ]; then
  usage
  exit 0
fi

logo

# provision it
echo "provisioning new solr on port $1..."
$DIRECTORY/../provision.sh create $1 > /dev/null 2>&1
if [ ! $? == 0 ]; then
 echo "failed to provision a new intance!"
 exit -1
fi
sleep 1

# stop it because it auto starts
echo "ensuring $1 is stopped before installing solr..."
$DIRECTORY/../run.sh stop $1 > /dev/null 2>&1

if [ ! $? == 0 ]; then
 echo "failed to run the new instance!"
 exit -1
fi

# provision solr to a new instance
if [ ! -f $DIRECTORY/apache-solr-3.2.0.war ]; then
	echo "downloading solr..."
	wget https://github.com/downloads/terrancesnyder/tomcat/apache-solr-3.2.0.war > /dev/null 2>&1
	if [ ! $? == 0 ]; then
 		echo "failed to download solr.war"
		exit -1
	fi
fi

# setup tomcat instance for /opt/dev/
touch $DIRECTORY/../$1/bin/app.sh
chmod +x $DIRECTORY/../$1/bin/app.sh
echo export JAVA_OPTS=\"\$JAVA_OPTS -Dsolr.solr.home=/opt/dev/solr-index\" > $DIRECTORY/../$1/bin/app.sh
cp apache-solr-3.2.0.war $DIRECTORY/../$1/webapps

$DIRECTORY/../run.sh start 7051
