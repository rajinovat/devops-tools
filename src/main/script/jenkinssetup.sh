#!/bin/bash
#   Script to configure a new component build job & UCD

# Input Parameters
# --g gold repository owner - The owner of gold master repository
# --P patternName			- Name of the gold master repository
# --c componentName			- Name of the new component.This value will be used to create target cloned repository  
# --u clone username			- The user cloning from gold master repository
# --p clone password 			- The password of the user cloning from gold master repository
# --U gitHOST				- The git url e.g https://github.com
# --command					[create] [delete]

 
patternName=
componentName=
scmtype="gitblit"
gitHOST=
gitPort=
CIUser="aubuilddsa"
jenkinsHost=
jenkinsPort=
command=

# Do user input function

function usage() {
cat << EOF
usage: $0 options

OPTIONS:

OPTIONS:
	-h Help	
	-p patternName				- Name of the gold master repository
	-c componentName			- Name of the new component.This value will be used to create target cloned repository  
	-g githost					- The git url e.g [github.com] [localhost]
	-o gitPort					- Git port
	-j JenkinsUser				- Jenkins User
	-k JenkinsPassword			- JenkinsPassword
   	-l jenkinsHost				- Jinkins Hostname
	-m jenkinsPort				- Jenkins Port
	-n command					- [create] [delete]
EOF
}


function createJob()
{
componentType=${patternName%/*}

if [ "${scmtype}"	==	"gitblit"	]; then	
   
	gitURLComponent="ssh://${CIUser}@${gitHOST}:${gitPort}/${componentType}/${componentName}.git" 
fi
templatesrc="../templates"

cp -rp ${templatesrc} /tmp
 
templatelocation="/tmp/templates"

jenkins_template="${templatelocation}/jenkinsjobconfig.xml"

perl -pi -e "s#SCMURL#ssh://${CIUser}\@${gitHOST}:${gitPort}/${componentType}/${componentName}.git#g" ${jenkins_template}

curl --user "$jenkinsUser:$jenkinsPassword" -X POST -H "Content-Type:application/xml" -d "@${jenkins_template}" "http://${jenkinsHost}:${jenkinsPort}/createItem?name=${componentName}" 

}

function deleteJob()
{
componentType=${patternName%/*}

curl --user "$jenkinsUser:$jenkinsPassword" -X POST "http://${jenkinsHost}:${jenkinsPort}/job/${componentName}/doDelete"
}

function executeCommands(){
case $command in
   create)
   	createJob
;;
   delete)
   	deleteJob
;;
   esac
}


function parseParameters() {
	while getopts "h:p:c:g:o:j:k:l:m:n:" OPTION
	do
	     case $OPTION in
	        h)
	         usage
	             exit 1
	             ;;
			p)
	            patternName=$OPTARG
	             ;;
	        c)
	            componentName=$OPTARG
	             ;;
			g)
	            gitHOST=$OPTARG
	             ;;
	        o)
	            gitPort=$OPTARG 
	             ;;    	   
	        j)  
		    	jenkinsUser=$OPTARG
		  	 	;;
	        k)  
		  		jenkinsPassword=$OPTARG
		   		;;
	        l)  
		    	jenkinsHost=$OPTARG
		    	;;
            m)
		   		jenkinsPort=$OPTARG
		    	;;		   	 
            n)
		    	command=$OPTARG
		    	;;		   	 
		
	        ?)
	             usage
	             exit
	             ;;
	     esac
	done
	
	# ensure required params are not blank
        echo "componentName=${componentName},gitHOST=${gitHOST},gitPort=${gitPort},jenkinsHost=${jenkinsHost},jenkinsPort=${jenkinsPort};command=${command}"	
	
	if [[ -z $patternName ]] || [[ -z $componentName ]] ||  [[ -z $gitHOST ]] || [[ -z $jenkinsUser ]] || [[ -z $jenkinsPassword ]] || [[ -z $jenkinsHost ]] || [[ -z $jenkinsPort ]] || [[ -z $command ]];
	then
		usage
		exit 1
	fi
}

# start of main program

parseParameters "$@"

executeCommands

exit 0