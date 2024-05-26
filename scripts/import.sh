#!/bin/bash

urlencode() {
  echo "$1" | jq -Rr @uri
}

tarball_sha512() {
  local repo="$1"
  local release="$2"
  curl -SsL "$(tarball_url "$repo" "$release")" | sha512sum | cut -d' ' -f1
}

tarball_url() {
  local repo="$1"
  local release="$2"
  gh release view -R "$repo" "$release" --json tarballUrl --jq .tarballUrl
}

import() {
  local repo="$1";
  local release="$2";
  local opam_files="$3";
  if [ -z "$opam_files" ]; then
    opam_files=$(gh api "repos/$repo/contents" --jq '.[]|.name' | rg '.opam$')
  fi
  echo "$opam_files" | while read file; do
    local name="$(basename "${file%.opam}")"
    echo "importing package $name.$release from $repo"
    local pkg_dir="packages/$name/$name.$release"
    local pkg_opam="$pkg_dir/opam"
    local pkg_url="$pkg_dir/url"
    mkdir -p "$pkg_dir"
    gh api "repos/$repo/contents/$file?ref=$(urlencode "$release")" --jq '.content' | base64 --decode > "$pkg_opam"
    echo "version: \"$release\"" >> "$pkg_opam"
    echo "importing package $name.$release from $repo: computing tarball checksum"
    local tarball=$(tarball_url "$repo" "$release")
    local tarball_shasum=$(tarball_sha512 "$repo" "$release")
    echo -e "url {\n  archive: \"$tarball\"\n  checksum: [ \"sha512=$tarball_shasum\" ]\n}" >> "$pkg_opam"
    echo "importing package $name.$release from $repo: done"
  done
}

import "$@"
