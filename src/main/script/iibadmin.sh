# This script provides utility functions to manage IBM Interation Server
# Input Parameters
# --e Integration Server Name - The name of the Integration Server
# --k Application Name - Integration Application Name
# --b BrokerName - The Name of the Integration Broker
# --c command - [deploy][undeploy][stop][start][create][delete] functions for apps,broker,server
# --v version - Bar File version 
# Deploy bar in order as per bom.csv file
iib_server=""
iib_app=""
iib_broker=""
command=""
bar_version=""
#iib_home="/app/iib/iib-10.0.0.4"
iib_home="/root/IIB/iib-10.0.0.4/"
status="success"
# Do user input function

function deployApp() {
#Deploys a bar file  
$iib_home/server/bin/mqsideploy -e "$iib_server" "$iib_broker" -a "$iib_app-$bar_version.bar"
# Integration App deployment status
result="$?"
 if [[ $result -ne 0 ]]
  then
   status="failed"
  fi
echo "Integration App ${iib_app} deploy $status on ${iib_server}."
}

function stopApp() {
 #Stop Integration App
${iib_home}/server/bin/mqsistopmsgflow -e "${iib_server}" ${iib_broker} -k "${iib_app}"
# api deployment status
result=$?
 if [[ $result -ne 0 ]]
  then
   status="failed"
  fi
	echo "Integration App ${iib_app} stop $status on ${iib_server}."
   
  }

function startApp() {
  #Start  Integration App
 ${iib_home}/server/bin/mqsistartmsgflow -e "${iib_server}" ${iib_broker} -k "${iib_app}"
 # api deployment status
 result="$?"
 if [[ $result -ne 0 ]]
  then
   status="failed"
  fi
echo "Integration App ${iib_app} start $status on ${iib_server}."
}

function createBroker(){
 #Create new Broker Node 
. ${iib_home}/server/bin/mqsiprofile
${iib_home}/server/bin/mqsicreatebroker ${iib_broker} -i wbrkuid -a wbrkpw
result="$?"
 if [[ $result -ne 0 ]]
  then
   status="failed"
  fi
echo "Broker Node ${iib_broker} create $status ..."
}

function startBroker(){
 #Start Broker Instance
. ${iib_home}/server/bin/mqsiprofile
${iib_home}/server/bin/mqsistart ${iib_broker}
result="$?"
 if [[ $result -ne 0 ]]
  then
   status="failed"
  fi
echo "Broker Node ${iib_broker} start $status ..."
}

function stopBroker(){
 #Stop Broker Instance
. ${iib_home}/server/bin/mqsiprofile
${iib_home}/server/bin/mqsistop ${iib_broker}
result="$?"
 if [[ $result -ne 0 ]]
  then
   status="failed"
  fi
echo "Broker Node ${iib_broker} stop $status ..."
}


function deleteBroker(){
 #Stop Broker Instance
. ${iib_home}/server/bin/mqsiprofile
${iib_home}/server/bin/mqsideletebroker ${iib_broker}
result="$?"
 if [[ $result -ne 0 ]]
  then
   status="failed" 
  fi
echo "Broker Node ${iib_broker} delete $status ..."
}


function createIntegrationServer(){
 #Create IntegrationServer instance
. ${iib_home}/server/bin/mqsiprofile
${iib_home}/server/bin/mqsicreateexecutiongroup  ${iib_broker} -e ${iib_server}
result="$?"
 if [[ $result -ne 0 ]]
  then
   status="failed"
  fi
echo "Integration Server ${iib_server} create $status ..."
}


function startIntegrationServer(){
 #Start IntegrationServer instance
. ${iib_home}/server/bin/mqsiprofile
${iib_home}/server/bin/mqsistartmsgflow  ${iib_broker} -e ${iib_server}
result="$?"
 if [[ $result -ne 0 ]]
  then
   status="failed"
  fi
echo "Integration Server ${iib_server} start $status ..."
}

function stopIntegrationServer(){
 #Stop IntegrationServer instance
. ${iib_home}/server/bin/mqsiprofile
${iib_home}/server/bin/mqsistopmsgflow ${iib_broker} -e ${iib_server}
result="$?"
 if [[ $result -ne 0 ]]
  then
   status="failed"
  fi
echo "Integration Server ${iib_server} stop $status ..."
}

function deleteIntegrationServer(){
 #Remove IntegrationServer instance
. ${iib_home}/server/bin/mqsiprofile
${iib_home}/server/bin/mqsideleteexecutiongroup ${iib_broker} -e ${iib_server}
result="$?"
 if [[ $result -ne 0 ]]
  then
   status="failed"
  fi
echo "Integration Server ${iib_server} remove $status ..."
}


function executemqsiCommands(){
 case $command in
   deploy)
   	deployApp
;;
   stop)
   	stopApp
;;
   start)
   	startApp
;;
  createnode)
   	createBroker
;;
  stopnode)
         stopBroker
;;
  startnode)
   	startBroker
;;
  deletenode)
	deleteBroker
;;	
  createserver)
  	createIntegrationServer
;;
  stopserver)
	stopIntegrationServer
;;
  startserver)
	startIntegrationServer
;;
  deleteserver)
	deleteIntegrationServer
;;	   		
 esac
}


function parseParameters() {
while getopts "e:k:b:c:v:CN:SN:TN:DN:CS:SS:TS:DS:" OPTION
do
case $OPTION in
 e)
 iib_server=$OPTARG
 ;;
 k)
 iib_app=$OPTARG
 ;;
 b)
 iib_broker=$OPTARG
 ;;
 c)
 command=$OPTARG
 ;;
 v)
bar_version=$OPTARG
 ;; 
 CN)
 command=$OPTARG
 ;;
 SN)
 command=$OPTARG
 ;;
 TN)
 command=$OPTARG
;;
 DN)
 command=$OPTARG
;;
 CS)
 command=$OPTARG
 ;;
SS)
 command=$OPTARG
;;
TS)
 command=$OPTARG
;;
 DS)
 command=$OPTARG
;;
esac
done

# ensure required params are not blank
echo "iib_server=$iib_server,iib_app=$iib_app,iib_broker=$iib_broker,command=$command,bar_version=$bar_version"

if [[ -z $iib_server ]] || [[ -z $iib_app ]] || [[ -z $iib_broker ]] || [[ -z $command ]]
then
 exit 1
 fi
}

 # start of main pogram
parseParameters "$@"
executemqsiCommands 
# Deployment complete
exit 0
