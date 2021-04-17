# Overview

Examples for interacting with a Slack workspace through the REST API.
## Prerequsiites

1. Go to https://api.slack.com/apps and create an application. Under ***OAuth and Permissions > Scopes > Bot Token Scopes*** add the following permissions: 

    - chat:write.public
    - channels:join
    - chat:write
    - chat:write.customize

2. Copy the *Bot User OAuth Token* that starts with ***xoxb-*** and store it somewhere secure. This will be used to authenticate to to the Slack REST API.

3. Install the application to the workspace.

## Examples

### Export all channels in a Slack Workspace
#### API Reference: https://api.slack.com/methods/conversations.list
                
    TOKEN='xoxb-XXXXXXXXXXXXX-XXXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXX';
    URL='https://slack.com/api/conversations.list';

    curl -X GET -H "Authorization: Bearer $BOT_TOKEN" \
    -H 'Content-type: application/x-www-form-urlencoded' \
    $URL > channels.list.json

### Add an application to all public channels
#### API Reference: https://api.slack.com/methods/conversations.join

    CHANNEL_IDS=$(cat ./channels.list.json | jq '.channels[] | select(.name) | .id' | sed -e 's/"//g')
    TOKEN='xoxb-XXXXXXXXXXXXX-XXXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXX'

    for ID in $CHANNEL_IDS; do
        URL="https://slack.com/api/conversations.join?channel=$ID&pretty=1"
        echo $URL
        curl -X POST -H "Authorization: Bearer $BOT_TOKEN" -H "application/x-www-form-urlencoded" "$URL"
    done

### Export all users in Slack Workspace
#### API Reference: https://api.slack.com/methods/users.list

    TOKEN='xoxb-XXXXXXXXXXXXX-XXXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXX'
    URL='https://slack.com/api/users.list'

    curl -X GET -H "Authorization: Bearer $BOT_TOKEN" \
    -H 'Content-type: application/x-www-form-urlencoded' \
    $URL > users.list.json






