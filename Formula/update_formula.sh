#!/bin/bash
set -e

FILE="curl-http3-libressl.rb"
echo "Updating file: $FILE"

###############################
# Update main formula (curl)  #
###############################
echo "Fetching latest curl info from GitHub API..."
CURL_JSON=$(curl -s "https://api.github.com/repos/curl/curl/tags")
# Get a tag like "curl-8_10_1"
CURL_NEW_TAG_RAW=$(echo "$CURL_JSON" | jq -r '.[].name' | grep -E '^curl-[0-9]+_[0-9]+_[0-9]+$' | sort -V | tail -n1)
# Convert to version with dots (e.g. "8.10.1")
CURL_NEW_VERSION=${CURL_NEW_TAG_RAW#curl-}
CURL_NEW_VERSION=${CURL_NEW_VERSION//_/.}
echo "curl new version: $CURL_NEW_VERSION"

# Build new curl URL and download tarball
NEW_CURL_URL="https://curl.se/download/curl-${CURL_NEW_VERSION}.tar.bz2"
echo "New curl URL: $NEW_CURL_URL"
TMPFILE=$(mktemp)
curl -sL "$NEW_CURL_URL" -o "$TMPFILE"
if command -v shasum >/dev/null 2>&1; then
    CURL_NEW_SHA=$(shasum -a 256 "$TMPFILE" | cut -d' ' -f1)
else
    CURL_NEW_SHA=$(sha256sum "$TMPFILE" | cut -d' ' -f1)
fi
rm "$TMPFILE"
echo "curl new sha256: $CURL_NEW_SHA"

# Update main formula URL line
purl -overwrite -replace '@url "https://curl\.se/download/curl-[0-9]+\.[0-9]+\.[0-9]+\.tar\.bz2"@url "'"${NEW_CURL_URL}"'"@' "$FILE"
# Update main formula sha256 line (assumes the line after the comment "# curl sha256 checksum")
purl -overwrite -replace '@[0-9a-f]+" # curl sha256@'"${CURL_NEW_SHA}"'" # curl sha256@' "$FILE"

###############################
# Update libressl resource    #
###############################
echo "Fetching latest LibreSSL info from GitHub API..."
LIBRESSL_JSON=$(curl -s "https://api.github.com/repos/libressl/portable/tags")
LIBRESSL_NEW_TAG=$(echo "$LIBRESSL_JSON" | jq -r '.[].name' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1)
echo "LibreSSL new tag: $LIBRESSL_NEW_TAG"

# Build new LibreSSL URL and download tarball
NEW_LIBRESSL_URL="https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_NEW_TAG:1}.tar.gz"
echo "New LibreSSL URL: $NEW_LIBRESSL_URL"
TMPFILE=$(mktemp)
curl -sL "$NEW_LIBRESSL_URL" -o "$TMPFILE"
if command -v shasum >/dev/null 2>&1; then
    LIBRESSL_NEW_SHA=$(shasum -a 256 "$TMPFILE" | cut -d' ' -f1)
else
    LIBRESSL_NEW_SHA=$(sha256sum "$TMPFILE" | cut -d' ' -f1)
fi
rm "$TMPFILE"
echo "LibreSSL new sha256: $LIBRESSL_NEW_SHA"

# Update libressl resource URL line (replace FTP URL with GitHub URL)
purl -overwrite -replace '@url "https://ftp\.openbsd\.org/pub/OpenBSD/LibreSSL/libressl-[0-9]+\.[0-9]+\.[0-9]+\.tar\.gz"@url "'"${NEW_LIBRESSL_URL}"'"@' "$FILE"
# Update libressl resource sha256 line (update the sha256 in the libressl resource block)
purl -overwrite -replace '@[0-9a-f]+" # libressl sha256@'"${LIBRESSL_NEW_SHA}"'" # libressl sha256@' "$FILE"

###############################
# Update nghttp3 resource     #
###############################
echo "Fetching latest nghttp3 info from GitHub API..."
NGHTTP3_JSON=$(curl -s "https://api.github.com/repos/ngtcp2/nghttp3/tags")
NGHTTP3_NEW_TAG=$(echo "$NGHTTP3_JSON" | jq -r '.[].name' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1)
NGHTTP3_NEW_REV=$(echo "$NGHTTP3_JSON" | jq -r --arg tag "$NGHTTP3_NEW_TAG" '.[] | select(.name == $tag) | .commit.sha')
echo "nghttp3 new tag: $NGHTTP3_NEW_TAG"
echo "nghttp3 new revision: $NGHTTP3_NEW_REV"

# Update nghttp3 tag line in resource block
purl -overwrite -replace '@tag: "v[0-9]+\.[0-9]+\.[0-9]+",@tag: "'"${NGHTTP3_NEW_TAG}"'",@' "$FILE"
# Update nghttp3 revision line (line ending with "# nghttp3 sha256")
purl -overwrite -replace '@[0-9a-f]+" # nghttp3 sha256@'"${NGHTTP3_NEW_REV}"'" # nghttp3 sha256@' "$FILE"

###############################
# Update ngtcp2 resource      #
###############################
echo "Fetching latest ngtcp2 info from GitHub API..."
NGTCP2_JSON=$(curl -s "https://api.github.com/repos/ngtcp2/ngtcp2/tags")
NGTCP2_NEW_TAG=$(echo "$NGTCP2_JSON" | jq -r '.[].name' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1)
echo "ngtcp2 new tag: $NGTCP2_NEW_TAG"

# Update ngtcp2 URL line in resource block
purl -overwrite -replace '@url "https://github.com/ngtcp2/ngtcp2/archive/refs/tags/v[0-9]+\.[0-9]+\.[0-9]+\.tar\.gz"@url "https://github.com/ngtcp2/ngtcp2/archive/refs/tags/'"${NGTCP2_NEW_TAG}"'.tar.gz"@' "$FILE"

echo "Fetching new tarball for ngtcp2 and computing sha256..."
NGTCP2_URL="https://github.com/ngtcp2/ngtcp2/archive/refs/tags/${NGTCP2_NEW_TAG}.tar.gz"
TMPFILE=$(mktemp)
curl -sL "$NGTCP2_URL" -o "$TMPFILE"
if command -v shasum >/dev/null 2>&1; then
    NGTCP2_NEW_SHA=$(shasum -a 256 "$TMPFILE" | cut -d' ' -f1)
else
    NGTCP2_NEW_SHA=$(sha256sum "$TMPFILE" | cut -d' ' -f1)
fi
rm "$TMPFILE"
echo "ngtcp2 new sha256: $NGTCP2_NEW_SHA"

# Update ngtcp2 sha256 line in resource block (line ending with "# ngtcp2 sha256")
purl -overwrite -replace '@[0-9a-f]+" # ngtcp2 sha256@'"${NGTCP2_NEW_SHA}"'" # ngtcp2 sha256@' "$FILE"

echo "Update process completed."
