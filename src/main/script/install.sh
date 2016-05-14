#!/bin/bash
#   Script to configure a new component build job

# Input Parameters
# --g gold repository owner - The owner of gold master repository
# --P patternName			- Name of the gold master repository
# --t componentType			- Type of the component. Possible values [iib] [zos] [apic]
# --c componentName			- Name of the new component.This value will be used to create target cloned repository  
# --u clone username			- The user cloning from gold master repository
# --p clone password 			- The password of the user cloning from gold master repository
# --U gitHOST				- The git url e.g https://github.com

goldUser=${goldUser}
patternName=${patternName}
componentType=${componentType}
componentName=${componentName}
cloneUser=${cloneUser}
clonePassword=${clonePassword}
scm=${scm}

gitHOST=${gitHOST}
gitPort=${gitPort}
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
	-g gold repository owner 	- The owner of gold master repository
	-P patternName			- Name of the gold master repository
	-t componentType		- Type of the component. Possible values [iib] [zconnect] [apic]
	-c componentName		- Name of the new component.This value will be used to create target cloned repository  
	-u clone username		- The user cloning from gold master repository
	-p clone password		- The password of the user cloning from gold master repository
	-U githost			- The git url e.g [github.com] [localhost]
	-O gitPort			- Git port
	-S scm				- SCM type [gitblit] [stash]
        -J jenkinsHost			- Jinkins Hostname
	-k jenkinsPort			- Jenkins Port
EOF
}

function createEmptyRepo()
{
jsonPost="\"name\": \"${cloneUser}/${componentName}.git\",\"description\": \"${componentName}\",\"owners\": [\"${CIUser}\",\"${cloneUser}\"],\"accessRestriction\": PUSH"

if [ "${scm}"	==	"gitblit"	]; then		
	 curl --insecure --user ${cloneUser}:${clonePassword} -X POST -H 'content-type: application/json;' --data "{${jsonPost}}"  https://${gitHOST}:${gitPort}/rpc/?req=CREATE_REPOSITORY
fi

}

function forkGitRepo()
{
#Fork a git repo

git config --global http.sslVerify false

gitURLPattern="https://${goldUser}@${gitHOST}:${gitPort}/r/${componentType}/${patternName}.git"

gitURLComponent="https://${cloneUser}@${gitHOST}:${gitPort}/r/${cloneUser}/${componentName}.git"


rm -rf /${destFolder}/${patternName} /${destFolder}/${componentName}

git clone "${gitURLPattern}" /${destFolder}/${patternName}

git clone "${gitURLComponent}" /${destFolder}/${componentName}

cd "/${destFolder}/${patternName}";rm -rf ".git";

cp -rp * /${destFolder}/${componentName};cd /${destFolder}/${componentName}

git add *;git commit -m "Initial Clone";git config --global push.default simple

git push --set-upstream "https://${cloneUser}:${clonePassword}@${gitHOST}:${gitPort}/r/${cloneUser}/${componentName}.git" master

}


function createJenkinsJob()
{

jenkins_template="${componentType}_jenkins_template.xml"

perl -pi -e "s/SCMURL/${gitURLComponent}/g" ${jenkins_template}

curl -X POST -H "Content-Type:application/xml" -d @${jenkins_template} "http://${jenkinsHost}:${jenkinsPort}/createItem?name=${componentName}"

}


function parseParameters() {
	while getopts "g:P:t:c:u:p:U:O:S:J:k" OPTION
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
	            scm=$OPTARG
	             ;;

	        J)  
		    jenkinsHost=$OPTARG
		    ;;

                k)
		    jenkinsPort=$OPTARG
		   ;;		   	 

	        ?)
	             usage
	             exit
	             ;;
	     esac
	done
	
	# ensure required params are not blank
	echo "goldUser=$goldUser,patternName=$patternName,componentType=$componentType,componentName=$componentName,cloneUser=$cloneUser,clonePassword=$clonePassword,gitHOST=${gitHOST},gitPort=${gitPort},scm=${scm},jenkinsHost=${jenkinsHost},jenkinsPort=${jenkinsPort}"
	
	if [[ -z $goldUser ]] || [[ -z $patternName ]] || [[ -z $componentType ]] || [[ -z $componentName ]] || [[ -z $cloneUser ]] || [[ -z $clonePassword ]] || [[ -z $gitHOST ]] || [[ -z $scm ]] || [[ -z $jenkinsHost ]] || [[ -z $jenkinsPort ]] 
	then
		usage
		exit 1
	fi
}

# start of main program

parseParameters $@
createEmptyRepo
forkGitRepo

createJenkinsJob


exit 0
