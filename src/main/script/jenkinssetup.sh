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


# Do user input function

function usage() {
cat << EOF
usage: $0 options

OPTIONS:

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
	-JU JenkinsUser			- Jenkins User
	-JP JenkinsPassword		- JenkinsPassword
    	-JH jenkinsHost			- Jinkins Hostname
	-JP jenkinsPort			- Jenkins Port
EOF
}




function createJenkinsJob()
{

if [ "${scmtype}"	==	"gitblit"	]; then	

	gitURLComponent="https://${cloneUser}@${gitHOST}:${gitPort}/r/${cloneUser}/${componentName}.git"
fi

jenkins_template="../templates/${componentType}_jenkins_template.xml"

replace_quote=$(printf '%s' "$gitURLComponent" | sed 's/[#\]/\\\-/g')

perl -pi -e "s#SCMURL#${replace_quote}#g" ${jenkins_template}


curl --user $jenkinsUser:$jenkinsPassword -X POST -H "Content-Type:application/xml" -d @${jenkins_template} "http://${jenkinsHost}:${jenkinsPort}/createItem?name=${componentName}" 

}


function parseParameters() {
	while getopts "g:P:t:c:u:p:U:O:S:JU:JP:JH:JO:" OPTION
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
	        JU)  
		    jenkinsUser=$OPTARG
		    ;;
	        JP)  
		    jenkinsPassword=$OPTARG
		    ;;
	        JH)  
		    jenkinsHost=$OPTARG
		    ;;
                JO)
		    jenkinsPort=$OPTARG
		    ;;		   	 
	        ?)
	             usage
	             exit
	             ;;
	     esac
	done
	
	# ensure required params are not blank
	echo "componentName=$componentName,componentType=$componentType,cloneUser=$cloneUser,gitHOST=${gitHOST},gitPort=${gitPort},scmtype=${scmtype},jenkinsHost=${jenkinsHost},jenkinsPort=${jenkinsPort}"
	
	if [[ -z $goldUser ]] || [[ -z $patternName ]] || [[ -z $componentType ]] || [[ -z $componentName ]] || [[ -z $cloneUser ]] || [[ -z $clonePassword ]] || [[ -z $gitHOST ]] || [[ -z $scmtype ]] || [[ -z $jenkinsUser ]] || [[ -z $jenkinsPassword ]] || [[ -z $jenkinsHost ]] || [[ -z $jenkinsPort ]] 
	then
		usage
		exit 1
	fi
}

# start of main program

parseParameters $@

createJenkinsJob

exit 0
