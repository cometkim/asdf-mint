#!/bin/bash

GITHUB_REPO="https://github.com/mint-lang/mint"
REGISTRY_URL="https://api.github.com/repos/mint-lang/mint/releases"

cmd="curl -s"
if [ -n "$GITHUB_API_TOKEN" ]; then
 cmd="$cmd -H 'Authorization: token $GITHUB_API_TOKEN'"
fi

function download_meatadata() {
  $cmd "$REGISTRY_URL"
}

# stolen from https://github.com/rbenv/ruby-build/pull/631/files#diff-fdcfb8a18714b33b07529b7d02b54f1dR942
function sort_versions() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

function extract_version() {
  grep -oE "tag_name\": \".{1,20}\"," | sed 's/tag_name\": \"//;s/\",//'
}

function get_platform() {
  case "$OSTYPE" in
    darwin*) echo -n "osx" ;;
    linux*) echo -n "linux" ;;
    *) fail "Unsupported platform" ;;
  esac
}

function get_bin_url() {
  local version=$1
  local platform=$2

  echo -n "$GITHUB_REPO/releases/download/$version/mint-$version-$platform"
}

function get_source_url() {
  local version=$1

  echo -n "$GITHUB_REPO/archive/$version.zip"
}

function get_temp_dir() {
  local tmpdir=$(mktemp -d asdf-mint.XXXX)

  echo -n $tmpdir
}

function check_install_type() {
  if [ "$ASDF_INSTALL_TYPE" != "version" ]; then
    fail "asdf-mint currently supports release install only"
  fi
}

function download_source() {
  local version=$1
  local download_path=$2
  local source_url=$(get_source_url $version)

  local tmpdir=$(get_temp_dir)
  trap "rm -rf $tmpdir" EXIT

  (
    mkdir -p $download_path

    echo "Downloading source from $source_url"
    curl -fLo $tmpdir/archive.zip $source_url

    unzip $tmpdir/archive.zip -d $tmpdir

    mv $tmpdir/mint-$version/* $download_path/
  ) || (rm -rf $download_path; exit 1)
}
