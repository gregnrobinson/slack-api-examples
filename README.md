# Overview

This repository shares examples for interacting with a Slack workspace through the Slack REST API. Using simple for loops and jq we can get any json dataset using the slack api and run queries against the data we want using [jq complex assignments](https://stedolan.github.io/jq/manual/#Assignment). This can prove to be a powerful solution at scale for automating the management of a Slack workspace of a large company.

Suppose we have the following JSON file named ***channels.list.json*** that contains the public slack channels for a company retrieved using a GET Request with the Slack API.
```
{
  "ok": true,
  "channels": [
    {
      "id": "C01EWFV0DV9",
      "name": "general",
      "is_channel": true,
      "is_group": false,
      "is_im": false,
      "created": 1605774649,
      "is_archived": false,
      "is_general": false,
      "unlinked": 0,
      "name_normalized": "billing",
      "is_shared": false,
      "parent_conversation": null,
      "creator": "U01F2TQEX42",
      "is_ext_shared": false,
      "is_org_shared": false,
      "shared_team_ids": ["T01EZGRJHC5"],
      "pending_shared": [],
      "pending_connected_team_ids": [],
      "is_pending_ext_shared": false,
      "is_member": true,
      "is_private": false,
      "is_mpim": false,
      "topic": {
        "value": "All Square orders and Google Cloud budget notifications are posted here automatically.",
        "creator": "U01F2TQEX42",
        "last_set": 1605820091
      },
      "purpose": {
        "value": "All Square billing related information",
        "creator": "U01F2TQEX42",
        "last_set": 1605801520
      },
      "previous_names": [],
      "num_members": 6
    },
    {
      "id": "C01F9XLF1SE",
      "name": "greg-useless-channel",
      "is_channel": true,
      "is_group": false,
      "is_im": false,
      "created": 1605775906,
      "is_archived": false,
      "is_general": false,
      "unlinked": 0,
      "name_normalized": "marketing",
      "is_shared": false,
      "parent_conversation": null,
      "creator": "U01F2TQEX42",
      "is_ext_shared": false,
      "is_org_shared": false,
      "shared_team_ids": ["T01EZGRJHC5"],
      "pending_shared": [],
      "pending_connected_team_ids": [],
      "is_pending_ext_shared": false,
      "is_member": true,
      "is_private": false,
      "is_mpim": false,
      "topic": {
        "value": "New subscribers to to the mailing list will be sent here automatically.",
        "creator": "U01F2TQEX42",
        "last_set": 1605820144
      },
      "purpose": {
        "value": "Show mailchimp notifications",
        "creator": "U01F2TQEX42",
        "last_set": 1605775906
      },
      "previous_names": [],
      "num_members": 1
    }
  ],
  "response_metadata": { "next_cursor": "" }
}
```

If I wanted to query, filter and then store only channel IDs that contain 1 member we would start by piping the ***channels.list.json*** file into jq.
```
cat ./channels.list.json | jq
```

Then we need to tell jq we want to process the channels array.
```
cat ./channels.list.json | jq '.channels[]'
```

Then we need to query against the `num_members` attribute of the json objects and use `== 1` to return only the channels where `"num_members": 1`.
```
cat ./channels.list.json | jq '.channels[] | select(.num_members == 1)'
```

Then we can add an additional filter to return only the ID of the json object where `"num_members": 1`. This can be done by matching the JSON path for the ID starting from the root of JSON file. The full JSON path to return the ID of a channel is `.channels[].id`.
```
cat ./channels.list.json | jq '.channels[] | select(.num_members == 1) | .id'
```
 
The output at his point is `"C01F9XLF1SE"`. To remove the quotes we can use some sed magic.
```
cat ./channels.list.json | jq '.channels[] | select(.num_members == 1) | .id' | sed -e 's/"//g'
```

We are left with a variable that equals `C01F9XLF1SE`. This ID can now be passed into a for loop that executes slack API requests. The variable only contains a single ID but if jq returned multiple IDs they would appear in the variable as `C01F9XLF1SE C01EWFV0DV9`. This logic is the basis for all the examples that are shown below and these snippets can be executed at any scale. Imagine a company that has 400+ channels and they want a quick way to find channels that have only a single member. I use this as an example because I have seen channels where only 1 user is a member because either people leave or it was used as a test for a Slack integration and it never gets used afterwards.

## Prerequsiites

1. Go to https://api.slack.com/apps and create an application. Under ***OAuth and Permissions > Scopes > Bot Token Scopes*** add the following permissions: 

    - channels:manage
    - channels:join
    - channels:read
    - channels:history
    - users:read

2. Copy the *Bot User OAuth Token* that starts with `xoxb-` and store it somewhere secure. This will be used to authenticate to to the Slack REST API.

3. Install the application to the workspace.

## Examples

### Export all public channels in a Slack Workspace
#### API Reference: https://api.slack.com/methods/conversations.list
                
    TOKEN='xoxb-1509569629413-1996816964960-yoyQoN7WrNcyy6vILVCViEur'
    URL='https://slack.com/api/conversations.list'

    curl -X GET -H "Authorization: Bearer $TOKEN" \
    -H 'Content-type: application/x-www-form-urlencoded' \
    $URL > channels.list.json

### Add a Bot to all public channels
#### API Reference: https://api.slack.com/methods/conversations.join
*Note: You must export all the public channels to a file named channels.list.json before executing*

    CHANNEL_IDS=$(cat ./channels.list.json | jq '.channels[] | select(.name) | .id' | sed -e 's/"//g')
    TOKEN='xoxb-XXXXXXXXXXXXX-XXXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXX'

    for ID in $CHANNEL_IDS; do
        URL="https://slack.com/api/conversations.join?channel=$ID&pretty=1"
        echo $URL
        curl -X POST -H "Authorization: Bearer $TOKEN" -H "application/x-www-form-urlencoded" "$URL"
    done

### Export all users in a Slack Workspace
#### API Reference: https://api.slack.com/methods/users.list

    TOKEN='xoxb-XXXXXXXXXXXXX-XXXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXX'
    URL='https://slack.com/api/users.list'

    curl -X GET -H "Authorization: Bearer $TOKEN" \
    -H 'Content-type: application/x-www-form-urlencoded' \
    $URL > users.list.json
 
### Archive public Slack channels that have only 1 member
#### API Reference: https://api.slack.com/methods/admin.conversations.archive
*Note: You must export all the public channels to a file named channels.list.json before executing*
                
    CHANNEL_IDS=$(cat ./channels.list.json | jq '.channels[] | select(.num_members == 1) | .id' | sed -e 's/"//g')
    TOKEN='xoxb-XXXXXXXXXXXXX-XXXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXX'

    for ID in $CHANNEL_IDS; do
        URL="https://slack.com/api/admin.conversations.archive?channel=$ID&pretty=1"
        echo $URL
        curl -X POST -H "Authorization: Bearer $TOKEN" -H "application/x-www-form-urlencoded" "$URL"
    done

### Archive public Slack channels that match a string condition
#### API Reference: https://api.slack.com/methods/admin.conversations.archive
*Note: You must export all the public channels to a file named channels.list.json before executing*

    STRING_MATCH="website"
    CHANNEL_IDS=$(cat ./channels.list.json | jq '.channels[] | select(.name | contains("'$STRING_MATCH'")) | .id' | sed -e 's/"//g')
    TOKEN='xoxb-XXXXXXXXXXXXX-XXXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXX'

    for ID in $CHANNEL_IDS; do
        URL="https://slack.com/api/admin.conversations.archive?channel=$ID&pretty=1"
        echo $URL
        curl -X POST -H "Authorization: Bearer $TOKEN" -H "application/x-www-form-urlencoded" "$URL"
    done

### Reference

https://stedolan.github.io/jq/manual/



