#TODO: Fix the arguments and shit

# hub alias from defunkt
# https://github.com/defunkt/hub
if [ "$commands[(I)hub]" ]; then
    # eval `hub alias -s zsh`
    function git(){hub "$@"}
fi

gh-get-user-from-remote() {

    if [ -z $1 ]; then
        targetRemote=origin
    else
        targetRemote=$1
    fi

    if [ -z $2 ]; then
        theirBranch=master
    else
        theirBranch=$2
    fi
 
    if [ -z $3 ]; then
        repoName=${${(%):-%1d}#.}
    else
        repoName=$3
    fi
  
    oldIFS=$IFS
    
    IFS=$'\n'
    
    set -A remotes $(git remote -v)
    
    
    IFS=oldIFS
    
    frontSub="$targetRemote*github.com/"
    backSub="$repoName.git*\(fetch\)"
    backSub="/$backSub"
    
    for i in $remotes; do;
        name=${i#${~frontSub}}
        if [ "$i" != "$name" ]; then
            stepOne=$name
            name=${name/${~backSub}} 
            if [ "$stepOne" != "$name" ]; then
                echo $name                
                return 0
            fi
        fi
    done
}

gh-fork-has-update() {
    
    if [ -z $4 ]; then
        myUsername=$(git config --get "github.user")
    else
        myUsername=$4
    fi

    if [ -z $3 ]; then
        myBranch=$(current_branch)
    else
        myBranch=$3
    fi
    
    if [ -z $1 ]; then
        targetRemote=origin
    else
        targetRemote=$1
    fi
    
    if [ -z $2 ]; then
        theirBranch=master
    else
        theirBranch=$2
    fi
    
    repoName=${${(%):-%1d}#.}

    name=$(gh-get-user-from-remote $targetRemote $theirBranch)
    if [ $? -eq 0 ]; then 
        getURL="https://github.com/$myUsername/$repoName/compare/$myBranch...$name:$theirBranch"
        netReq=$(wget --no-check-certificate --quiet $getURL -O -)
        netS=$?
        if [ $netS -eq 0 ]; then
            echo $netReq | grep "is up to date" -q
            if [ $? -eq 0 ]; then
                return 1
            else
                return 0
            fi
        else
            echo "Bad URL: $getURL" >&2
            echo "Was not able to find the requested remote repository..." >&2
            return 1
        fi
    else
            echo "Was not able to find the user from requested remote and branch" >&2
            return 1
    fi

}

gh-get-head-sha1() {
    tarBranch=master
    tarRepo=${${(%):-%1d}#.}
    doUser=origin
    unset tarUser
    
    while getopts :r:l:b:R: o; do
        case $o in
        r)  
            unset tarUser 
            doUser=$OPTARG;;
        l)
            tarUser=$OPTARG;;
        b)
            tarBranch=$OPTARG;;
        R)
            tarRepo=$OPTARG;;
        :)
            case $OPTARG in
            r)
                unset tarUser
                doUser=origin;;
            l)
                tarUser=$(git config --get "github.user");;
            b)
                tarBranch=$(current_branch);;
            esac;;
        [?])
            echo "Usage: ~~~" >&2
            return 1
        esac
    done
    
    if [ -z $tarUser ]; then
        tarUser=$(gh-get-user-from-remote $doUser $tarBranch $tarRepo)
    fi
    
    getURL="https://github.com/$tarUser/$tarRepo/commits/$tarBranch"
    
    netData=$(wget --no-check-certificate -q $getURL -O -)
    if [ $? -eq 0 ]; then
        grepData=$(echo $netData | grep "commitSHA" -m 1)
        if [ $? -eq 0 ]; then
            echo $(echo $grepData | sed -rn 's/^[ \t]*//; s/.*= "([a-f,0-9]*)".*/\1/p')
            return 0
        else
            echo "SHA1 hash not found..." >&2
            return 1
        fi
    else
        echo "Connection to $getURL was unsuccessful..." >&2
        return 1
   fi

}
