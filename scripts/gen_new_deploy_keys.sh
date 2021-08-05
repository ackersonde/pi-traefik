#!/bin/bash
WORKING_DIR=/home/ubuntu/my-ca
GITHUB_DEPLOY_KEY_FILE=~/.ssh/github_deploy_params
if [ -s "$GITHUB_DEPLOY_KEY_FILE" ]; then
    source $GITHUB_DEPLOY_KEY_FILE
else
    echo "$GITHUB_DEPLOY_KEY_FILE required. No params == no run."
    exit
fi

rm -f $WORKING_DIR/id_ed25519_github_deploy*

ssh-keygen -t ed25519 -a 100 -f $WORKING_DIR/id_ed25519_github_deploy -q -N ""
ssh-keygen -s $WORKING_DIR/ca_key -I github -n ubuntu,ackersond -P "$CACERT_KEY_PASS" -V +5w -z $(date +%s) $WORKING_DIR/id_ed25519_github_deploy
CERT_INFO=`ssh-keygen -L -f $WORKING_DIR/id_ed25519_github_deploy-cert.pub`

pip install -r $WORKING_DIR/requirements.txt

# heavy lifting which updates github secrets via API
if $WORKING_DIR/github_deploy_secrets.py ; then
    SLACK_URL=https://slack.com/api/chat.postMessage
    curl -s -d token=$SLACK_API_TOKEN -d channel=C092UE0H4 \
        -d text="$HOSTNAME just updated the SSH deploy key & cert in Org Secrets:" $SLACK_URL
    curl -s -d token=$SLACK_API_TOKEN -d channel=C092UE0H4 -d text="$CERT_INFO" $SLACK_URL
fi
