#!/bin/bash

usage() {
    #figlet slack
    echo "================================================================================"
    echo "      _            _ "
    echo "  ___| | __ _  ___| | __ "
    echo " / __| |/ _' |/ __| |/ / "
    echo " \__ \ | (_| | (__|   < "
    echo " |___/_|\__,_|\___|_|\_\ "
    echo "================================================================================"
    echo " Usage: slack.sh [args] {message} "
    echo " "
    echo " Basic Arguments: "
    echo "   webhook_url|url  Send your JSON payloads to this URL."
    echo "   channel          Channel, private group, or IM channel to send message to."
    echo "   username         Set your bot's user name."
    echo "   emoji            Emoji to use as the icon for this message."
    echo " "
    echo " Attachments Arguments: "
    echo "   color            Like traffic signals. [good, warning, danger, or hex code (eg. #439FE0)]."
    echo "   title            The title is displayed as larger, bold text near the top of a message attachment."
    echo "   image            A valid URL to an image file that will be displayed inside a message attachment."
    echo "   footer           Add some brief text to help contextualize and identify an attachment."
    echo "================================================================================"
    exit 1
}

for v in "$@"; do
    case ${v} in
    -d=*|--debug=*)
        debug="${v#*=}"
        shift
        ;;
    -u=*|--url=*|--webhook_url=*)
        webhook_url="${v#*=}"
        shift
        ;;
    --token=*)
        token="${v#*=}"
        shift
        ;;
    --channel=*)
        channel="${v#*=}"
        shift
        ;;
    --emoji=*|--icon_emoji=*)
        icon_emoji="${v#*=}"
        shift
        ;;
    --username=*)
        username="${v#*=}"
        shift
        ;;
    --color=*)
        color="${v#*=}"
        shift
        ;;
    --title=*)
        title="${v#*=}"
        shift
        ;;
    --image=*|--image_url=*)
        image_url="${v#*=}"
        shift
        ;;
    --footer=*)
        footer="${v#*=}"
        shift
        ;;
    *)
        text=$*
        break
        ;;
    esac
done

if [ "${token}" != "" ]; then
    webhook_url="https://hooks.slack.com/services/${token}"
fi

if [ "${webhook_url}" == "" ]; then
    usage
fi
if [ "${text}" == "" ]; then
    usage
fi

message=$(echo ${text} | sed 's/"/\"/g' | sed "s/'/\'/g" | sed "s/%/%25/g")

json="{"
    if [ "${channel}" != "" ]; then
        json="$json\"channel\":\"${channel}\","
    fi
    if [ "${icon_emoji}" != "" ]; then
        json="$json\"icon_emoji\":\"${icon_emoji}\","
    fi
    if [ "${username}" != "" ]; then
        json="$json\"username\":\"${username}\","
    fi
    json="$json\"attachments\":[{"
        if [ "${color}" != "" ]; then
            json="$json\"color\":\"${color}\","
        fi
        if [ "${title}" != "" ]; then
            json="$json\"title\":\"${title}\","
        fi
        if [ "${image_url}" != "" ]; then
            json="$json\"image_url\":\"${image_url}\","
        fi
        if [ "${footer}" != "" ]; then
            json="$json\"footer\":\"${footer}\","
        fi
        json="$json\"text\":\"${message}\""
    json="$json}]"
json="$json}"

if [ "${debug}" == "" ]; then
    curl -s -d "payload=${json}" "${webhook_url}"
else
    echo "url=${webhook_url}"
    echo "payload=${json}"
fi
