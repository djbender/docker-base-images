#!/usr/bin/env bash
# Publishes the tags of one image version, for both its regular and dev variant.
#
# A built image is merged from this run's per-arch images. An unchanged image is
# re-tagged from the first of its *_SOURCES that exists. Tags ending in the
# commit SHA are written once and never moved.
set -euo pipefail

: "${IMAGE_BASE:?}" "${GITHUB_RUN_ID:?}" "${GITHUB_SHA:?}" "${PRIMARY_TAGS:?}" "${DEV_TAGS:?}"

# Returns 1 only when the registry says "not found"; any other error is fatal
exists() {
  local output
  if output=$(docker buildx imagetools inspect "$1" 2>&1); then
    return 0
  fi
  if [[ $output == *"$1: not found"* ]]; then
    return 1
  fi
  echo "$output" >&2
  exit 1
}

first_existing() {
  local ref
  for ref in "$@"; do
    if exists "$ref"; then
      echo "$ref"
      return
    fi
  done
  echo "No source found among: $*" >&2
  exit 1
}

create() {
  local tag=$1
  shift
  if [[ $tag == *"$GITHUB_SHA" ]] && exists "$tag"; then
    echo "Skipping existing SHA tag $tag"
    return
  fi
  echo "Creating $tag from $*"
  docker buildx imagetools create -t "$tag" "$@"
}

merge_variant() {
  local suffix=$1 tag found
  local -a tags candidates sources
  read -ra tags <<<"$2"
  read -ra candidates <<<"$3"

  if ((${#candidates[@]})); then
    found=$(first_existing "${candidates[@]}")
    sources=("$found")
  else
    sources=("${IMAGE_BASE}${suffix}-${GITHUB_RUN_ID}-amd64" "${IMAGE_BASE}${suffix}-${GITHUB_RUN_ID}-arm64")
  fi

  for tag in "${tags[@]}"; do
    create "$tag" "${sources[@]}"
  done
}

merge_variant "" "$PRIMARY_TAGS" "${PRIMARY_SOURCES:-}"
merge_variant "-dev" "$DEV_TAGS" "${DEV_SOURCES:-}"
