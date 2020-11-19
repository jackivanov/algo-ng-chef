#!/bin/sh
# Block ads, malware, etc..

TEMP="$(mktemp)"
TEMP_SORTED="$(mktemp)"
WHITELIST="/etc/dnscrypt-proxy/white.list"
BLACKLIST="/etc/dnscrypt-proxy/black.list"
BLOCKHOSTS="/etc/dnscrypt-proxy/blacklist.txt"
BLOCKLIST_URLS="/etc/dnscrypt-proxy/adblock-urls"

#Delete the old block.hosts to make room for the updates
rm -f $BLOCKHOSTS

echo 'Downloading hosts lists...'
#Download and process the files needed to make the lists (enable/add more, if you want)
while read -r url; do
  wget --timeout=2 --tries=3 -qO- "$url" | grep -Ev "(localhost)" | grep -Ew "(0.0.0.0|127.0.0.1)" | awk '{sub(/\r$/,"");print $2}'  >> "$TEMP"
done < $BLOCKLIST_URLS

#Add black list, if non-empty
if [ -s "$BLACKLIST" ]
then
    echo 'Adding blacklist...'
    cat $BLACKLIST >> "$TEMP"
fi

#Sort the download/black lists
awk '/^[^#]/ { print $1 }' "$TEMP" | sort -u > "$TEMP_SORTED"

#Filter (if applicable)
if [ -s "$WHITELIST" ]
then
    #Filter the blacklist, suppressing whitelist matches
    #  This is relatively slow =-(
    echo 'Filtering white list...'
    grep -v -E "^[[:space:]]*$" $WHITELIST | awk '/^[^#]/ {sub(/\r$/,"");print $1}' | grep -vf - "$TEMP_SORTED" > $BLOCKHOSTS
else
    cat "$TEMP_SORTED" > $BLOCKHOSTS
fi

echo 'Restarting dns service...'
#Restart the dns service
systemctl restart dnscrypt-proxy.service

exit 0
