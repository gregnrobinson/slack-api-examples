    COMPANY_DOMAIN=company.com
    cat ./users.list.json | jq '.members[] | .profile.email' | sed -e 's/"//g' | grep -v "null" | grep -v "$COMPANY_DOMAIN" > user.guest.emails.list