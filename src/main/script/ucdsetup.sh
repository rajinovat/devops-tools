#!/bin/bash
#   Script to configure a new component build job & UCD

# Input Parameters
# --P patternName			- Name of the gold master repository
# --c componentName			- Name of the new component.This value will be used to create target cloned repository  

patternName=
componentName=
ucdUser=
ucdHost=
ucdPassword=
ucdPort=
command=

# Do user input function

function usage() {
cat << EOF
usage: $0 options

OPTIONS:
	-p patternName			- Name of the gold master repository
	-c componentName		- Name of the new component.This value will be used to create target cloned repository  
	-u ucdUser			- UCD User
	-w ucdPassword			- UCD Password
	-h ucdHost			- UCD Host         
	-o ucdPort			- UCD Port
	
EOF
}

function checkIfObjectExists()
{

#Create UCD Component
httpcode=`curl -i -k  -u  ${ucdUser}:${ucdPassword} "https://${ucdHost}:${ucdPort}/cli/component/info?component=${componentName}" 2>/dev/null | head -n 1 | cut -d$' ' -f2`

if [ "$httpcode" -eq "200" ] ;
then
echo "$componentName Already Exists.."
exit 1;
fi

httpcode=`curl -i -k  -u  ${ucdUser}:${ucdPassword} "https://${ucdHost}:${ucdPort}/cli/application/info?application=${componentName}-App" 2>/dev/null | head -n 1 | cut -d$' ' -f2`

if [ "$httpcode" -eq "200" ] ;
then
echo "$componentName-App Already Exists.."
exit 1;
fi

}


function checkIfObjectDoesNotExists()
{

#Create UCD Component
httpcode=`curl -i -k  -u  ${ucdUser}:${ucdPassword} "https://${ucdHost}:${ucdPort}/cli/component/info?component=${componentName}" 2>/dev/null | head -n 1 | cut -d$' ' -f2`

if [ "$httpcode" -ne "200" ] ;
then
echo "$componentName Doesn't Exists.."
exit 1;
fi

httpcode=`curl -i -k  -u  ${ucdUser}:${ucdPassword} "https://${ucdHost}:${ucdPort}/cli/application/info?application=${componentName}-App" 2>/dev/null | head -n 1 | cut -d$' ' -f2`

if [ "$httpcode" -ne "200" ] ;
then
echo "$componentName-App Doesn't Exists.."
exit 1;
fi

}


function configureUCDObjects()
{

checkIfObjectExists

componentType=${patternName%/*}
#patternOnly=${patternName##*/}
templatesrc="../templates"

cp -rp ${templatesrc} /tmp
 
templatelocation="/tmp/templates"

ucd_component_json="${templatelocation}/createComponent.json"      #remove .. to reference template directory located at the root of the package 

ucd_application_json="${templatelocation}/createApplication.json"    #remove .. to reference template directory located at the root of the package

ucd_application_process_deploy_json="${templatelocation}/${componentType}_application_process_deploy.json"

ucd_application_process_undeploy_json="${templatelocation}/${componentType}_application_process_undeploy.json"


#Text replace componentName 

perl -pi -e "s/##componentName##/${componentName}/g" ${ucd_component_json}

perl -pi -e "s/##componentType##/${componentType}/g" ${ucd_component_json}

perl -pi -e "s/##componentName##/${componentName}/g" ${ucd_application_json}

perl -pi -e "s/##componentName##/${componentName}/g" ${ucd_application_process_deploy_json}

perl -pi -e "s/##componentName##/${componentName}/g" ${ucd_application_process_undeploy_json}

curl  -k -u ${ucdUser}:${ucdPassword} "https://${ucdHost}:${ucdPort}/cli/component/create" -X PUT -d @${ucd_component_json}

#Create UCD Application
curl  -k -u ${ucdUser}:${ucdPassword} "https://${ucdHost}:${ucdPort}/cli/application/create" -X PUT -d @${ucd_application_json}

#Import UCD Component Version

curl  -k  -u ${ucdUser}:${ucdPassword} "https://${ucdHost}:${ucdPort}/cli/component/integrate -X PUT -d {"component":"${componentName}"}"

#Add Component to Application

curl -k -u ${ucdUser}:${ucdPassword} "https://${ucdHost}:${ucdPort}/cli/application/addComponentToApp?component=${componentName}&application=${componentName}-App" -X PUT

#Add  Application Process Deploy

curl  -k -u ${ucdUser}:${ucdPassword} "https://${ucdHost}:${ucdPort}/cli/applicationProcess/create" -X PUT -d @${ucd_application_process_deploy_json}

#Add  Application Process Un-Deploy

curl  -k -u ${ucdUser}:${ucdPassword} "https://${ucdHost}:${ucdPort}/cli/applicationProcess/create" -X PUT -d @${ucd_application_process_undeploy_json}


#Create Environment in an Application

curl -k -u ${ucdUser}:${ucdPassword} "https://${ucdHost}:${ucdPort}/cli/environment/createEnvironment?application=${componentName}-App&name=Sandbox&color=pink" -X PUT

#Add resource to an environment

#curl -k -u ${ucdUser}:${ucdPassword} "https://${ucdHost}:${ucdPort}/cli/environment/addBaseResource?application=${componentName}-App&environment=Sandbox&resource=${componentType}-resource" -X PUT

rm -rf ${templatelocation}
}


function deleteUCDObjects(){
checkIfObjectDoesNotExists

###Delete commands yet to complete
}


function executeCommands(){
case $command in
   create)
   	configureUCDObjects
 	;;
   delete)
   	deleteUCDObjects
;;
   esac
}


function parseParameters() {

	while getopts "h:p:c:u:w:s:o:m:" OPTION
	do

	  case $OPTION in
	     h)
	             usage
	             exit 1
	             ;;
	     p)
	            patternName="$OPTARG"
	             ;;
	     c)
	            componentName=$OPTARG
	             ;;
	     u)
	            ucdUser=$OPTARG
	            ;;
	     w)
	            ucdPassword=$OPTARG
	             ;;
	    s)
	            ucdHost=$OPTARG
	             ;;		
	    o)
	            ucdPort=$OPTARG
	             ;;		
	    m)		command=$OPTARG
	    		;;            
	    ?)
	             usage
	             exit
	             ;;
	     esac
	done
	# ensure required params are not blank
	echo "PatternName=$patternName,ComponentName=$componentName,ucdUser=$ucdUser,ucdPassword=$ucdPassword,ucdHost=$ucdHost,ucdPort=$ucdPort,command=$command"
	
	if [[ -z $patternName ]] ||  [[ -z $componentName ]] || [[ -z $ucdUser ]] || [[ -z $ucdPassword ]] || [[ -z $ucdHost ]] || [[ -z $ucdPort ]] || [[ -z $command ]]
	then
		usage
		exit 1
	fi
}

# start of main program

parseParameters "$@"
executeCommands
exit 0
