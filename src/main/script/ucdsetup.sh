#!/bin/bash
#   Script to configure a new component build job & UCD

# Input Parameters
#	-c componentName		- Name of the new component.This value will be used to create target cloned repository  
#	-t componentType		- Type of the component. Possible values [iib] [zconnect] [apic]
#	-u ucdUser			- UCD User
#	-p ucdPassword			- UCD Password
#	-O ucdPort			- UCD Port
#	-H ucdHost			- UCD Host  

componentName=
componentType=
ucdUser=
ucdHost=
ucdPassword=
ucdPort=


# Do user input function

function usage() {
cat << EOF
usage: $0 options

OPTIONS:
	-c componentName		- Name of the new component.This value will be used to create target cloned repository  
	-t componentType		- Type of the component. Possible values [iib] [zconnect] [apic]
	-u ucdUser			- UCD User
	-p ucdPassword			- UCD Password
	-H ucdHost			- UCD Host         
	-O ucdPort			- UCD Port
EOF
}


function configureUCD()
{
ucd_component_json="templates/createComponent.json"

perl -pi -e "s/##componentName##/${componentName}/g" ${ucd_component_json}

curl  -k -u ${ucdUser}:${ucdPassword} "https://${ucdHost}:${ucdPort}/cli/component/create" -X PUT -d @${ucd_component_json}

}

function parseParameters() {
	while getopts "c:t:u:p:H:O" OPTION
	do
	     case $OPTION in
	        h)
	             usage
	             exit 1
	             ;;
	        c)
	            componentName=$OPTARG
	             ;;
		t)
	            componentType=$OPTARG
	             ;;
		u)
	            ucdUser=$OPTARG
	             ;;
		p)
	            ucdPassword=$OPTARG
	             ;;	
		H)
	            ucdHost=$OPTARG
	             ;;		
		O)
	            ucdPort=$OPTARG
	             ;;		
	        ?)
	             usage
	             exit
	             ;;
	     esac
	done
	
	# ensure required params are not blank
	echo "componentName=$componentName,componentType=$componentType,ucdUser=$ucdUser,ucdPassword=$ucdPassword,ucdHost=$ucdHost,ucdPort=$ucdPort"
	
	if [[ -z $componentName ]] || [[ -z $componentType ]] || [[ -z $ucdUser ]] || [[ -z $ucdPassword ]] || [[ -z $ucdHost ]] || [[ -z $ucdPort ]]
	then
		usage
		exit 1
	fi
}

# start of main program

parseParameters $@

configureUCD


exit 0
