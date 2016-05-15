#!/bin/bash
#   Script to configure a new component build job & UCD

# Input Parameters
# --g gold repository owner - The owner of gold master repository
# --P patternName			- Name of the gold master repository
# --t componentType			- Type of the component. Possible values [iib] [zos] [apic]
# --c componentName			- Name of the new component.This value will be used to create target cloned repository  
# --u clone username			- The user cloning from gold master repository
# --p clone password 			- The password of the user cloning from gold master repository
# --U gitHOST				- The git url e.g https://github.com

goldUser=
patternName=
componentType=
componentName=
cloneUser=
clonePassword=
scmtype=
gitHOST=
gitPort=
gitURLPattern=
gitURLComponent=
CIUser="aubuilddsa"
destFolder="tmp"
jenkinsHost=
jenkinsPort=
ucdUser=
ucdHost=
ucdPassword=
ucdPort=


# Do user input function

function usage() {
cat << EOF
usage: $0 options

OPTIONS:
	-g gold repository owner 	- The owner of gold master repository
	-P patternName			- Name of the gold master repository
	-t componentType		- Type of the component. Possible values [iib] [zconnect] [apic]
	-c componentName		- Name of the new component.This value will be used to create target cloned repository  
	-u clone username		- The user cloning from gold master repository
	-p clone password		- The password of the user cloning from gold master repository
	-U githost			- The git url e.g [github.com] [localhost]
	-O gitPort			- Git port
	-S scmtype			- scmtype type [gitblit] [stash]
	-UU ucdUser			- UCD User
	-UP ucdPassword			- UCD Password
	-UH ucdHost			- UCD Host         
	-UO ucdPort			- UCD Port
EOF
}


function configureUCD()
{
ucd_component_json="templates/createComponent.json"

perl -pi -e "s/##componentName##/${componentName}/g" ${ucd_component_json}

curl  -k -u ${ucdUser}:${ucdPassword} "https://${ucdHost}:${ucdPort}/cli/component/create" -X PUT -d @${ucd_component_json}

}

function parseParameters() {
	while getopts "g:P:t:c:u:p:U:O:S:J:k:UU:UP:UH:UO:" OPTION
	do
	     case $OPTION in
	        h)
	             usage
	             exit 1
	             ;;
        	g)
	            goldUser=$OPTARG
	             ;;
		P)
	            patternName=$OPTARG
	             ;;
	        t)
	            componentType=$OPTARG
	             ;;
	        c)
	            componentName=$OPTARG
	             ;;
	        u)
	            cloneUser=$OPTARG
	             ;;
	        p)
	            clonePassword=$OPTARG
	             ;;
		U)
	            gitHOST=$OPTARG
	             ;;
	        O)
	            gitPort=$OPTARG 
	             ;;    	   
	        S)
	            scmtype=$OPTARG
	             ;;
	        J)  
		    jenkinsHost=$OPTARG
		    ;;
               k)
		    jenkinsPort=$OPTARG
		    ;;	
		UU)
	            ucdUser=$OPTARG
	             ;;
		UP)
	            ucdPassword=$OPTARG
	             ;;	
		UH)
	            ucdHost=$OPTARG
	             ;;		
		UO)
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
	
	if [[ -z $goldUser ]] || [[ -z $patternName ]] || [[ -z $componentType ]] || [[ -z $componentName ]] || [[ -z $cloneUser ]] || [[ -z $clonePassword ]] || [[ -z $gitHOST ]] || [[ -z $scmtype ]]  || [[ -z $ucdUser ]] || [[ -z $ucdPassword ]] || [[ -z $ucdHost ]] || [[ -z $ucdPort ]]
	then
		usage
		exit 1
	fi
}

# start of main program

parseParameters $@

configureUCD


exit 0