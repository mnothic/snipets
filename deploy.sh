#!/usr/bin/env zsh
# author: Jorge A. Medina
# coment: deploy passnfly 
base_path=$(dirname $0)
if [[ ! -d "$base_path/nshell" ]]; then
    git clone https://github.com/mnothic/nshell.git
fi
. $base_path/nshell/nshell.sh
check_for_cli_args 1 $(color_string red "<release_version>") $@
color_string green "$(timestamp) Deploy start"
export BRANCH=$1
export APP=SAST-dispatcher
export APP_HOME=/home/sast/$APP
cd $APP_HOME
OLD_BRANCH=$(git describe --tags)
git fetch
git tag | grep "^$BRANCH$" > /dev/null
if [[ $? -ne 0 ]]; then
    color_string red "$(timestamp) ERROR: The tag \"$BRANCH\" don't exist"
    usage "deploy.sh <existant_release_version>"
fi
color_string green "The differences between version $OLD_BRANCH and $BRANCH are:"
color_string red "$(git diff --name-status $OLD_BRANCH..$BRANCH)"
continue_question
if [[ $? -ne 0 ]]; then
    exit_message $(color_string red "$(timestamp) The deploy it's aborted")
fi
git fetch
git checkout .
git checkout -b $BRANCH origin/$BRANCH
git checkout $BRANCH
git merge origin/$BRANCH
color_string green "now you could compile translations"
continue_question
if [[ $? -eq 0 ]]; then
    color_string green "compiling email translations..."
    . $APP_HOME/.ENV/bin/activate
    cd $APP_HOME/sast_dispatcher/apps/email
    color_string green "compiling web translations..."
    pybabel compile -d translations
    cd $APP_HOME/sast_dispatcher/apps/web
    pybabel compile -d translations
fi
color_string green "Now you could restart gunicorns"
continue_question
if [[ $? -eq 0 ]]; then
    color_string green "$(timestamp) stopping gunicorns"
    while [[ $(running gunicorn) == "YES" ]]
    do
        sudo supervisorctl stop all
        sleep 5
    done
    color_string green "You want flush redis cache?"
    continue_question
    if [[ $? -eq 0 ]]; then
        echo "flushdb" | redis-cli -h rabbitmq
    fi 
    color_string green "You want exit without start application"
    continue_question
    if [[ $? -eq 0 ]]; then
       color_string red "$(timestamp) Exit with application stopped!!!!!WARNING"
    else
        color_string green "$(timestamp) starting gunicorns"
        sudo supervisorctl start all
        color_string green "now you could flush nginx"
        continue_question
        if [[ $? -eq 0 ]]; then
            color_string green "$(timestamp) restarting nginx"
            sudo service nginx stop
            sudo rm -rf /tmp/nginx/*
            sudo service nginx start
        fi
    fi
else
    color_string red "$(timestamp) Exit without restart, you need restart services by your own hand later"
fi
color_string green "$(timestamp) Deploy finish"
