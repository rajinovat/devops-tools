#!/bin/bash
#   Script to configure a new component build job

# Input Parameters
# --g gold repository owner - The owner of gold master repository
# --P patternName			- Name of the gold master repository
# --t componentType			- Type of the component. Possible values [iib] [zos] [apic]
# --c componentName			- Name of the new component.This value will be used to create target cloned repository  
# --u clone username			- The user cloning from gold master repository
# --p clone password 			- The password of the user cloning from gold master repository
# --U gitUrl				- The git url e.g https://github.com

goldUser=${goldUser}
patternName=${patternName}
componentType=${componentType}
componentName=${componentName}
cloneUser=${cloneUser}
clonePassword=${clonePassword}
scm=${scm}
gitURL=${gitURL}
gitPort=${gitPort}
ciUser="aubuilddsa"
destFolder="tmp"
# Do user input function

function usage() {
cat << EOF
usage: $0 options

OPTIONS:
	-g gold repository owner 	- The owner of gold master repository
	-P patternName			- Name of the gold master repository
	-t componentType		- Type of the component. Possible values [iib] [zos] [apic]
	-c componentName		- Name of the new component.This value will be used to create target cloned repository  
	-u clone username		- The user cloning from gold master repository
	-p clone password		- The password of the user cloning from gold master repository
	-U githost			- The git url e.g github.com
	-O gitPort			- Git port
	-S scm				- SCM type [gitblit] [stash]
EOF
}

function createEmptyRepo()
{
jsonPost="\"name\": \"${cloneUser}/${componentName}.git\",\"description\": \"${componentName}\",\"owners\": [\"${ciUser}\",\"${cloneUser}\"],\"accessRestriction\": PUSH"

if [ "${scm}"	==	"gitblit"	]; then		
	 curl --insecure --user ${cloneUser}:${clonePassword} -X POST -H 'content-type: application/json;' --data "{${jsonPost}}"  https://${gitURL}:${gitPort}/rpc/?req=CREATE_REPOSITORY
fi

}

function forkGitRepo()
{
#Fork a git repo

git config --global http.sslVerify false

echo "git clone "https://${goldUser}@${gitURL}:${gitPort}/r/${componentType}/${patternName}.git""
echo "git clone "https://${goldUser}@${gitURL}:${gitPort}/r/${componentType}/${patternName}.git" /${destFolder}/${patternName}"

rm -rf /${destFolder}/${patternName} /${destFolder}/${componentName}

git clone "https://${goldUser}@${gitURL}:${gitPort}/r/${componentType}/${patternName}.git" /${destFolder}/${patternName}

git clone "https://${cloneUser}@${gitURL}:${gitPort}/r/${cloneUser}/${componentName}.git" /${destFolder}/${componentName}

cd "/${destFolder}/${patternName}";rm -rf ".git";

cp -rp * /${destFolder}/${componentName};cd /${destFolder}/${componentName}

git add *;git commit -m "Initial Clone";git config --global push.default simple

git push --set-upstream "https://${cloneUser}:${clonePassword}@${gitURL}:${gitPort}/r/${cloneUser}/${componentName}.git" master

}

function parseParameters() {
	while getopts "g:P:t:c:u:p:U:O:S:" OPTION
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
	            gitURL=$OPTARG
	             ;;
	        O)
	        	gitPort=$OPTARG 
	        	;;    	   
	        S)
	            scm=$OPTARG
	             ;;
	                       
	        ?)
	             usage
	             exit
	             ;;
	     esac
	done
	
	# ensure required params are not blank
	echo "goldUser=$goldUser,patternName=$patternName,componentType=$componentType,componentName=$componentName,cloneUser=$cloneUser,clonePassword=$clonePassword,gitURL=${gitURL},gitPort=${gitPort},scm=${scm}"
	
	if [[ -z $goldUser ]] || [[ -z $patternName ]] || [[ -z $componentType ]] || [[ -z $componentName ]] || [[ -z $cloneUser ]] || [[ -z $clonePassword ]] || [[ -z $gitURL ]]
	then
		usage
		exit 1
	fi
}

# start of main program

parseParameters $@
createEmptyRepo
forkGitRepo


exit 0
