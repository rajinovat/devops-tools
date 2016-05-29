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
scmtype="gitblit"
gitHOST=
gitPort=
gitURLPattern=
gitURLComponent=
CIUser="aubuilddsa"
destFolder="tmp"
command=

# Do user input function

function usage() {
cat << EOF
usage: $0 options

OPTIONS:
    -h Help
	-g gold repository owner 	- The owner of gold master repository
	-p patternName				- Name of the gold master repository
	-c componentName			- Name of the new component.This value will be used to create target cloned repository  
	-u clone username			- The user cloning from gold master repository
	-w clone password			- The password of the user cloning from gold master repository
	-j githost					- The git url e.g [github.com] [localhost]
	-k gitPort					- Git port
	-l scmtype					- scmtype type [gitblit] [stash]
	-m command					- [create] [delete]
EOF
}

function createRepo()
{
componentType=${patternName%/*}
patternOnly=${patternName##*/}

jsonPost="\"name\": \"${componentType}/${componentName}.git\",\"description\": \"${componentName}\",\"owners\": [\"${CIUser}\",\"${cloneUser}\",\"master\"],\"accessRestriction\": PUSH"

if [ "${scmtype}"	==	"gitblit"	]; then		
	 curl --insecure --user ${cloneUser}:${clonePassword} -X POST -H 'content-type: application/json;' --data "{${jsonPost}}"  "https://${gitHOST}:${gitPort}/rpc/?req=CREATE_REPOSITORY"
fi

}

function deleteRepo()
{

componentType=${patternName%/*}

jsonPost="\"name\": \"${componentType}/${componentName}.git\""

if [ "${scmtype}"	==	"gitblit"	]; then		
	 curl --insecure --user ${cloneUser}:${clonePassword} -X POST -H 'content-type: application/json;' --data "{${jsonPost}}" "https://${gitHOST}:${gitPort}/rpc/?req=DELETE_REPOSITORY"
fi

}


function forkRepo()
{
#Fork a git repo

componentType=${patternName%/*}
patternOnly=${patternName##*/}

if [ "${componentType}"	 ==  "iib"	]; then	

	patternOnly="${patternOnly}-parent"
	componentName="${componentName}-parent"
fi

git config --global http.sslVerify false

gitURLPattern="https://${goldUser}@${gitHOST}:${gitPort}/r/${componentType}/${patternOnly}.git"

gitURLComponent="https://${cloneUser}@${gitHOST}:${gitPort}/r/${componentType}/${componentName}.git"

patternCloneDir="/${destFolder}/${patternOnly}"
componentCloneDir="/${destFolder}/${componentName}"


if [ -d "$patternCloneDir" ]; then
 rm -rf ${patternCloneDir}
fi 

if [ -d "$componentCloneDir" ]; then
 rm -rf ${componentCloneDir}
fi 

mkdir -p ${patternCloneDir}
mkdir -p ${componentCloneDir}

git clone "${gitURLPattern}" ${patternCloneDir}

git clone "${gitURLComponent}" ${componentCloneDir}

if [ -d "$patternCloneDir" ]; then
	 cd "${patternCloneDir}"
	 rm -rf ".git"
	 cp -rp * ${componentCloneDir}
	 cd ${componentCloneDir}
	 git add *
	 git commit -m "Initial Commit"
	 git config --global push.default simple
	 git push --set-upstream "https://${cloneUser}:${clonePassword}@${gitHOST}:${gitPort}/r/${componentType}/${componentName}.git" master
	 echo "Git fork from ${patternName} repository success!!"
	 rm -rf ${patternCloneDir}
	 rm -rf ${componentCloneDir}
else
  	echo "Git fork from ${patternName} repository failed!!"
fi 



}

function executeCommands(){
case $command in
   create)
   	createRepo
   	forkRepo
;;
   delete)
   	deleteRepo
;;
   esac
}

function parseParameters() {
	while getopts "h:g:p:c:u:w:j:k:l:m:" OPTION
	do
	     case $OPTION in
	        h)
	             usage
	             exit 1
	             ;;
	        g)
	            goldUser=$OPTARG
	             ;;
			p)
	            patternName=$OPTARG
	             ;;
	        c)
	            componentName=$OPTARG
	             ;;
	        u)
	            cloneUser=$OPTARG
	             ;;
	        w)
	            clonePassword=$OPTARG
	             ;;
			j)
	            gitHOST=$OPTARG
	             ;;
	        k)
	            gitPort=$OPTARG 
	             ;;    	   
	        l)
	            scmtype=$OPTARG
	             ;;
	        m)  command=$OPTARG
	        	;;     
	        ?)
	             usage
	             exit
	             ;;
	     esac
	done
	
	# ensure required params are not blank
	echo "goldUser=$goldUser,patternName=$patternName,componentName=$componentName,cloneUser=$cloneUser,clonePassword=$clonePassword,gitHOST=${gitHOST},gitPort=${gitPort},scmtype=${scmtype},command=${command}"
	
	if [[ -z $goldUser ]] || [[ -z $patternName ]] ||  [[ -z $componentName ]] || [[ -z $cloneUser ]] || [[ -z $clonePassword ]] || [[ -z $gitHOST ]] || [[ -z $scmtype ]] || [[ -z $command ]]
	then
		usage
		exit 1
	fi
}

# start of main program

parseParameters "$@"

executeCommands

exit 0
