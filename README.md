# Table of Contents
- [Overview](#overview)
- [Logic Explanation](#logic-explanation)
- [Prerequisites](#prerequisites)
  * [Create Bot Token](#create-bot-token)
  * [Create User Token](#create-user-token)
- [Examples](#examples)
  * [Export all public channels](#export-all-public-channels)
  * [Add a bot to all public channels](#add-a-bot-to-all-public-channels)
  * [Export all users](#export-all-users)
  * [Export all user emails](#export-all-user-emails)
  * [Export all guest user emails](#export-all-guest-user-emails)
  * [Archive all public channels that have only 1 member](#archive-all-public-channels-that-have-only-1-member)
  * [Archive all public channels that match a string condition](#archive-all-public-channels-that-match-a-string-condition)
- [Reference](#reference)
# Overview

This repository shares examples for interacting with a Slack workspace through the Slack REST API. Using simple iteration coupled with jq we can extract and transform any json dataset using the slack api by running queries against a Slack workspace using [jq complex assignments](https://stedolan.github.io/jq/manual/#Assignment). This can prove to be a powerful solution at scale for automating the management of a Slack workspace of a large company.

# Logic Explanation

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

# Prerequisites
To execute any of the examples that use `admin.*` as the API method, you need the [Enterprise Grid](https://slack.com/intl/en-ca/enterprise) version of Slack. Slack used to have these features available on the [Standard](https://slack.com/intl/en-ca/pricing/standard) plan but deprecated usage of them as of February 2021. All examples without `admin.*` can be executed by anyone with a free workspace using a Bot Token.

## Create Bot Token
1. Go to https://api.slack.com/apps and create an application. Under ***OAuth and Permissions > Scopes > Bot Token Scopes*** add the following permissions: 

    - channels:manage
    - channels:join
    - channels:read
    - channels:history
    - users:read
    - users:read.email
    - users:profile.read

2. Copy the *Bot User OAuth Token* that starts with `xoxb-` and store it somewhere secure. This will be used to authenticate to to the Slack REST API.

3. Change the name, description and add an icon image to describe 

3. Install the application to the workspace.
## Create User Token
To execute the examples using `admin.*` in the request URL, a User Token is required. To create a User Token:
1. Go to https://api.slack.com/apps and create an application. Under ***OAuth and Permissions > Scopes > User Token Scopes*** add the following permissions: 

    - admin.conversations:write

2. Copy the ***User OAuth Token*** that starts with `xoxp-` and store it somewhere secure. This will be used as the `TOKEN` variable to authenticate to to the Slack REST API.

3. Install the application to the workspace.

# Examples

## Export all public channels
### API Reference: https://api.slack.com/methods/conversations.list
```sh                
TOKEN="xoxb-XXXXXXXXXXXXX-XXXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXX"
URL="https://slack.com/api/conversations.list"

curl -X GET -H "Authorization: Bearer $TOKEN" -H 'Content-type: application/x-www-form-urlencoded' \
  $URL > channels.list.json
```
## Export all public channels that have 1 member
*Note: You must first complete the step [Export all public channels](#export-all-public-channels) before executing*
```sh
cat ./channels.list.json | jq '.channels[] | select(.num_members == 1) | .name' | sed -e 's/"//g' > channels.1member.list
```

## Add a bot to all public channels
### API Reference: https://api.slack.com/methods/conversations.join
*Note: You must first complete the step [Export all public channels](#export-all-public-channels) before executing*
```sh
TOKEN="xoxb-XXXXXXXXXXXXX-XXXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXX"
CHANNEL_IDS=$(cat ./channels.list.json | jq '.channels[] | select(.name) | .id' | sed -e 's/"//g')

for ID in $CHANNEL_IDS; do
  URL="https://slack.com/api/conversations.join?channel=$ID&pretty=1"
  
  echo $URL
  
  curl -X POST -H "Authorization: Bearer $TOKEN" -H "application/x-www-form-urlencoded" "$URL"
done
```

## Rename public channel prefixes
*Note: You must first complete the step [Export all public channels](#export-all-public-channels) and [Add a bot to all public channels](#add-a-bot-to-all-channels) before executing*

Useful for finding channels with similar names.
```sh
TOKEN="xoxb-XXXXXXXXXXXXX-XXXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXX"
OLD_PREFIX="t-"
NEW_PREFIX="tech-"

declare -a arr=($(cat ./channels.list.json | jq '.channels[] | select(.name | contains("'$SOURCE_PREFIX'")) | (.id + "=" + .name)' | sed -e 's/"//g'))

for i in "${arr[@]}" 
do
  CHANNEL_ID=${i%=*}
  CHANNEL_NAME=${i#*=}
  
  URL="https://slack.com/api/conversations.rename?channel=${CHANNEL_ID}&name=${NEW_PREFIX}${CHANNEL_NAME//$OLD_PREFIX}&pretty=1"
  
  echo $URL
  
  curl -X POST -H "Authorization: Bearer $TOKEN" -H "application/x-www-form-urlencoded" "$URL"
done
```
## Export all users
### API Reference: https://api.slack.com/methods/users.list
```sh
TOKEN="xoxb-XXXXXXXXXXXXX-XXXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXX"
URL="https://slack.com/api/users.list"

curl -X GET -H "Authorization: Bearer $TOKEN" \
-H 'Content-type: application/x-www-form-urlencoded' \
$URL > users.list.json
```
## Export all user emails
*Note: You must first complete the step [Export all users](#export-all-users) before executing*

Return only the email address attribute and exclude any fields that are `null`.
```sh   
cat ./users.list.json | jq '.members[] | .profile.email' | sed -e 's/"//g' | grep -v "null" > user.emails.list
```
## Export all guest user emails
*Note: You must first complete the step [Export all users](#export-all-users) before executing*

We use the `COMPANY_DOMAIN` variable to exclude any emails that contain this domain. Only emails that do **NOT** contain the company domain will get exported.
```sh
COMPANY_DOMAIN="company.com"

cat ./users.list.json | jq '.members[] | .profile.email' | sed -e 's/"//g' | grep -v "null" | grep -v "$COMPANY_DOMAIN" > user.guest.emails.list
```
## Archive all public channels that have only 1 member
*Note: You must first complete the step [Export all public channels](#export-all-public-channels) before executing*
### API Reference: https://api.slack.com/methods/admin.conversations.archive
```sh
TOKEN="xoxb-XXXXXXXXXXXXX-XXXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXX"
CHANNEL_IDS=$(cat ./channels.list.json | jq '.channels[] | select(.num_members == 1) | .id' | sed -e 's/"//g')

for ID in $CHANNEL_IDS; do
  URL="https://slack.com/api/admin.conversations.archive?channel=$ID&pretty=1"
  
  echo $URL
  
  curl -X POST -H "Authorization: Bearer $TOKEN" -H "application/x-www-form-urlencoded" "$URL"
done
```
## Archive all public channels that match a string condition
*Note: You must first complete the step [Export all public channels](#export-all-public-channels) before executing*
### API Reference: https://api.slack.com/methods/admin.conversations.archive
```sh
TOKEN="xoxb-XXXXXXXXXXXXX-XXXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXX"
STRING_MATCH="website"
CHANNEL_IDS=$(cat ./channels.list.json | jq '.channels[] | select(.name | contains("'$STRING_MATCH'")) | .id' | sed -e 's/"//g')


for ID in $CHANNEL_IDS; do
  URL="https://slack.com/api/admin.conversations.archive?channel=$ID&pretty=1"
  
  echo $URL
  
  curl -X POST -H "Authorization: Bearer $TOKEN" -H "application/x-www-form-urlencoded" "$URL"
done
```
# Reference

- https://stedolan.github.io/jq/manual/
- https://api.slack.com/methods



