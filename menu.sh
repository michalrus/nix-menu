#!/usr/bin/env bash

set -euo pipefail

# TODO: check for: dialog/whiptail, jq etc.

# TODO: check that "$1" is set or fail with usage

mapfile -d $'\0' menu_items < <(
    jq -j '
       .subcommands
       | sort_by(.subcommands | length > 0 | not)
       | (map(.title | length) | max) as $max_length_alt
       | .[]
       | "\u0000",
         .title,
         (" " * ($max_length_alt - (.title | length))),
         if .subcommands | length > 0 then "  » " else "    " end,
         "\u0000",
         .description
    ' example.json | cut -c2-
)

exec dialog \
    --backtitle "nix-menu %NIX_MENU_VERSION%" \
    --colors --keep-tite --ok-label "Select" --cancel-label "Back" --scrollbar --tab-correct \
    --title "$(jq -r '.title' example.json)" \
    --menu "$(jq -r 'if .longDescription == null or .longDescription == "" then .description else .longDescription end' example.json)" 0 0 0 \
    "${menu_items[@]}"
