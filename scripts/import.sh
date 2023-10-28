#!/bin/bash

urlencode() {
  echo "$1" | jq -Rr @uri
}

import() {
  local repo="$1";
  local release="$2";
  local files=$(gh api "repos/$repo/contents" --jq '.[]|.name' | rg '.opam$')
  echo "$files" | while read file; do
    local name="${file%.opam}"
    local pkg_dir="packages/$name/$name.$release"
    local pkg_opam="$pkg_dir/opam"
    local pkg_url="$pkg_dir/url"
    mkdir -p "$pkg_dir"
    gh api "repos/$repo/contents/$name.opam?ref=$(urlencode "$release")" --jq '.content' | base64 --decode > "$pkg_opam"
    echo "version: \"$release\"" >> "$pkg_opam"
    local tarball=$(gh release view -R "$repo" "$release" --json tarballUrl --jq .tarballUrl)
    echo "archive: \"$tarball\"" > "$pkg_url"
  done
}

import "$@"
