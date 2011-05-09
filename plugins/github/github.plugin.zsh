# hub alias from defunkt
# https://github.com/defunkt/hub
if [ "$commands[(I)hub]" ]; then
    # eval `hub alias -s zsh`
    function git(){hub "$@"}
fi

gh-has-update() {
    
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
                fi
            fi 
        fi
    done;
    echo "Was not able to find the requested remote repository..." >&2
    return 1
}
