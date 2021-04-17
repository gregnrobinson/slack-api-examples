    STRING_MATCH="website"
    CHANNEL_IDS=$(cat ./channels.list.json | jq '.channels[] | select(.name | contains("$STRING_MATCH")) | .id' | sed -e 's/"//g')