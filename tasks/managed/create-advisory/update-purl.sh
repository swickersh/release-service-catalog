#!/bin/bash
set -exo pipefail

DATA_FILE="data.json"
ADVISORY_JSON_KEY=".releaseNotes"
advisoryData=$(jq -c "$ADVISORY_JSON_KEY" "$DATA_FILE")

echo $advisoryData


COMPONENTS=$(jq -c '.mapping.components[] | select(.contentGateway)' "$DATA_FILE")


#echo $COMPONENTS


while IFS= read -r component; do
    PRODUCT_CODE=$(jq -r '.contentGateway.productCode' <<< "$component")
    VERSION_NAME=$(jq -r '.contentGateway.productVersionName' <<< "$component")
    COMPONENT_NAME=$(jq -r '.name' <<< "$component")


    echo "Fetching download URLs for $PRODUCT_CODE $VERSION_NAME...$COMPONENT_NAME"

    # this should have something to let us know if it doesn't return any files. Not sure if it should fail in that event though.
    URLS_JSON=$(python3 utils/get_cgw_download_urls.py --product "$PRODUCT_CODE" --version "$VERSION_NAME")

    #echo $URLS_JSON

    # Create a map of basename -> full download URL
    declare -A FILE_URL_MAP
    while IFS= read -r url; do
    BASENAME=$(basename "$url")
    FILE_URL_MAP["$BASENAME"]="$url"
    done <<< "$URLS_JSON"


    $echo $FILE_URL_MAP

    # Get all advisory entries that match this component
    MATCHING_ENTRIES=$(jq -c --arg name "$COMPONENT_NAME" "${ADVISORY_JSON_KEY}[] | select(.component == \$name)" "$DATA_FILE")

    echo $MATCHING_ENTRIES

    while IFS= read -r entry; do
        ARCH=$(jq -r '.architecture' <<< "$entry")
        OS=$(jq -r '.os' <<< "$entry")

        FILENAME=$(jq -r --arg arch "$ARCH" --arg os "$OS" '.files[] | select(.arch == $arch and .os == $os) | .name' <<< "$component")
        URL=${FILE_URL_MAP[$FILENAME]}

        if [ -n "$URL" ]; then
          PURL="pkg:generic/$FILENAME@$VERSION_NAME?download_url=$URL"
        else
          echo "Warning: No download URL found for $FILENAME"
          PURL="MISSING"
        fi

        UPDATED_ENTRY=$(jq --arg purl "$PURL" '.purl = $purl' <<< "$entry")
        UPDATED_ENTRIES+=("$UPDATED_ENTRY")
    done <<< "$MATCHING_ENTRIES"

done <<< "$COMPONENTS"

# Merge updated advisory entries back into file
ENTRIES_JOINED=$(IFS=,; echo "${UPDATED_ENTRIES[*]}")
jq -n --argjson updated "[$ENTRIES_JOINED]" "$ADVISORY_JSON_KEY = \$updated" > /tmp/data.tmp && mv /tmp/data.tmp "$DATA_FILE"
