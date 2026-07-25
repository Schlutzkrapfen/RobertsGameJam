#!/bin/sh
printf '\033c\033]0;%s\a' Der Böse Mann
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Der Böse Mann.x86_64" "$@"
