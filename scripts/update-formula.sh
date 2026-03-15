#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CONFIG_FILE="${ROOT_DIR}/formulas.json"
GITHUB_API_URL="${GITHUB_API_URL:-https://api.github.com}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

usage() {
  cat <<'EOF'
Usage:
  scripts/update-formula.sh --all
  scripts/update-formula.sh <formula-name> [<formula-name> ...]
EOF
}

sha256_file() {
  local file=$1

  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
    return
  fi

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
    return
  fi

  echo "missing required command: shasum or sha256sum" >&2
  exit 1
}

list_formula_names() {
  jq -r '.formulas[].name' "$CONFIG_FILE"
}

fetch_repo_tags_tsv() {
  local repo=$1
  local page=1
  local response
  local count

  while :; do
    response=$(
      curl -fsSL --retry 3 \
        -H 'Accept: application/vnd.github+json' \
        "${GITHUB_API_URL}/repos/${repo}/tags?per_page=100&page=${page}"
    )

    count=$(printf '%s' "$response" | jq 'length')
    if [ "$count" -eq 0 ]; then
      break
    fi

    printf '%s' "$response" | jq -r '.[] | [.name, .commit.sha] | @tsv'

    if [ "$count" -lt 100 ]; then
      break
    fi

    page=$((page + 1))
  done
}

latest_tag_for_repo() {
  local repo=$1
  local tag_match=$2
  local cache_file=$3

  awk -F '\t' '{print $1}' "$cache_file" | grep -E "$tag_match" | sort -V | tail -n 1
}

revision_for_tag() {
  local tag=$1
  local cache_file=$2

  awk -F '\t' -v tag="$tag" '$1 == tag {print $2; exit}' "$cache_file"
}

version_from_tag() {
  local transform=$1
  local tag=$2

  case "$transform" in
    tag)
      printf '%s\n' "$tag"
      ;;
    trim_v)
      printf '%s\n' "${tag#v}"
      ;;
    curl_underscores)
      local version=${tag#curl-}
      printf '%s\n' "${version//_/.}"
      ;;
    *)
      echo "unsupported version_from_tag: ${transform}" >&2
      exit 1
      ;;
  esac
}

render_url_template() {
  local template=$1
  local tag=$2
  local version=$3
  local rendered=$template

  rendered=${rendered//\$\{tag\}/$tag}
  rendered=${rendered//\$\{version\}/$version}
  printf '%s\n' "$rendered"
}

update_formula_archive() {
  local file=$1
  local target_type=$2
  local resource_name=$3
  local new_url=$4
  local new_sha=$5
  local checksum_comment=$6

  TARGET_TYPE=$target_type \
  RESOURCE_NAME=$resource_name \
  NEW_URL=$new_url \
  NEW_SHA=$new_sha \
  CHECKSUM_COMMENT=$checksum_comment \
  perl -0pi -e '
    my $updated = 0;
    my $target_type = $ENV{TARGET_TYPE};
    my $resource_name = $ENV{RESOURCE_NAME};
    my $new_url = $ENV{NEW_URL};
    my $new_sha = $ENV{NEW_SHA};
    my $checksum_comment = $ENV{CHECKSUM_COMMENT};

    if ($target_type eq "formula") {
      $updated += s{(\A.*?^\s*url\s+")[^"]+(")}{$1.$new_url.$2}ems;
      $updated += s{(\A.*?^\s*sha256\s+")[0-9a-f]+("\s+#\s+\Q$checksum_comment\E)}{$1.$new_sha.$2}ems;
    } else {
      $updated += s{(resource "\Q$resource_name\E" do.*?^\s*url\s+")[^"]+(")}{$1.$new_url.$2}ems;
      $updated += s{(resource "\Q$resource_name\E" do.*?^\s*sha256\s+")[0-9a-f]+("\s+#\s+\Q$checksum_comment\E)}{$1.$new_sha.$2}ems;
    }

    die "failed to update archive target\n" unless $updated >= 2;
  ' "$file"
}

update_formula_git() {
  local file=$1
  local resource_name=$2
  local new_tag=$3
  local new_revision=$4
  local revision_comment=$5

  RESOURCE_NAME=$resource_name \
  NEW_TAG=$new_tag \
  NEW_REVISION=$new_revision \
  REVISION_COMMENT=$revision_comment \
  perl -0pi -e '
    my $updated = 0;
    my $resource_name = $ENV{RESOURCE_NAME};
    my $new_tag = $ENV{NEW_TAG};
    my $new_revision = $ENV{NEW_REVISION};
    my $revision_comment = $ENV{REVISION_COMMENT};

    $updated += s{(resource "\Q$resource_name\E" do.*?^\s*tag:\s+")[^"]+(",)}{$1.$new_tag.$2}ems;
    $updated += s{(resource "\Q$resource_name\E" do.*?^\s*revision:\s+")[0-9a-f]+("\s+#\s+\Q$revision_comment\E)}{$1.$new_revision.$2}ems;

    die "failed to update git target\n" unless $updated >= 2;
  ' "$file"
}

update_target() {
  local formula_name=$1
  local formula_file=$2
  local target_json=$3
  local target_name
  local target_type
  local resource_name
  local kind
  local repo
  local tag_match
  local revision_comment
  local checksum_comment
  local url_template
  local transform
  local tag_cache
  local latest_tag
  local latest_revision
  local version
  local download_url
  local tmpfile
  local new_sha

  target_name=$(printf '%s' "$target_json" | jq -r '.name')
  target_type=$(printf '%s' "$target_json" | jq -r '.target')
  resource_name=$(printf '%s' "$target_json" | jq -r '.resource // empty')
  kind=$(printf '%s' "$target_json" | jq -r '.kind')
  repo=$(printf '%s' "$target_json" | jq -r '.repo')
  tag_match=$(printf '%s' "$target_json" | jq -r '.tag_match')

  echo "Updating ${formula_name}:${target_name}"

  tag_cache=$(mktemp)
  fetch_repo_tags_tsv "$repo" >"$tag_cache"

  latest_tag=$(latest_tag_for_repo "$repo" "$tag_match" "$tag_cache")
  if [ -z "$latest_tag" ]; then
    rm -f "$tag_cache"
    echo "failed to resolve latest tag for ${repo}" >&2
    exit 1
  fi

  case "$kind" in
    archive)
      transform=$(printf '%s' "$target_json" | jq -r '.version_from_tag')
      checksum_comment=$(printf '%s' "$target_json" | jq -r '.checksum_comment')
      url_template=$(printf '%s' "$target_json" | jq -r '.url_template')
      version=$(version_from_tag "$transform" "$latest_tag")
      download_url=$(render_url_template "$url_template" "$latest_tag" "$version")
      tmpfile=$(mktemp)
      curl -fsSL --retry 3 "$download_url" -o "$tmpfile"
      new_sha=$(sha256_file "$tmpfile")
      rm -f "$tmpfile"
      update_formula_archive "$formula_file" "$target_type" "$resource_name" "$download_url" "$new_sha" "$checksum_comment"
      echo "Resolved ${target_name} tag ${latest_tag} (${new_sha})"
      ;;
    git)
      revision_comment=$(printf '%s' "$target_json" | jq -r '.revision_comment')
      latest_revision=$(revision_for_tag "$latest_tag" "$tag_cache")
      if [ -z "$latest_revision" ]; then
        rm -f "$tag_cache"
        echo "failed to resolve revision for ${repo}:${latest_tag}" >&2
        exit 1
      fi
      update_formula_git "$formula_file" "$resource_name" "$latest_tag" "$latest_revision" "$revision_comment"
      echo "Resolved ${target_name} tag ${latest_tag} (${latest_revision})"
      ;;
    *)
      rm -f "$tag_cache"
      echo "unsupported target kind: ${kind}" >&2
      exit 1
      ;;
  esac

  rm -f "$tag_cache"
}

update_formula() {
  local formula_name=$1
  local formula_json
  local formula_file

  formula_json=$(jq -c --arg name "$formula_name" '.formulas[] | select(.name == $name)' "$CONFIG_FILE")
  if [ -z "$formula_json" ]; then
    echo "unknown formula: ${formula_name}" >&2
    exit 1
  fi

  formula_file=$(printf '%s' "$formula_json" | jq -r '.file')
  formula_file="${ROOT_DIR}/${formula_file}"

  while IFS= read -r target_json; do
    update_target "$formula_name" "$formula_file" "$target_json"
  done < <(printf '%s' "$formula_json" | jq -c '.targets[]')
}

main() {
  local formulas=()
  local formula_name

  require_command jq
  require_command curl
  require_command perl
  require_command grep
  require_command sort
  require_command awk

  if [ ! -f "$CONFIG_FILE" ]; then
    echo "missing config file: $CONFIG_FILE" >&2
    exit 1
  fi

  if [ $# -eq 0 ]; then
    usage >&2
    exit 1
  fi

  if [ "$1" = "--all" ]; then
    while IFS= read -r formula_name; do
      formulas+=("$formula_name")
    done < <(list_formula_names)
  else
    formulas=("$@")
  fi

  for formula_name in "${formulas[@]}"; do
    update_formula "$formula_name"
  done
}

main "$@"
