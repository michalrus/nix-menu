#!/usr/bin/env bash

set -uo pipefail

command -v sed >/dev/null 2>&1 || {
    echo >&2 'sed: command not found'
    exit 127
}
command -v jq >/dev/null 2>&1 || {
    echo >&2 'jq: command not found'
    exit 127
}

BACKTITLE_OPTS=("--backtitle" "nix-menu (%NIX_MENU_VERSION%)")

if command -v dialog >/dev/null 2>&1; then
    DIALOG_CMD=dialog
    DIALOG_OPTS=(--colors --keep-tite --scrollbar --no-mouse --ok-label "Select" --cancel-label "Back" "${BACKTITLE_OPTS[@]}")
    FMT_BOLD=$(printf "\Zb\Z7")
    FMT_RESET=$(printf "\Zn")
elif command -v whiptail >/dev/null 2>&1; then
    DIALOG_CMD=whiptail
    DIALOG_OPTS=(--ok-button "Select" --cancel-button "Back" "${BACKTITLE_OPTS[@]}")
    FMT_BOLD=
    FMT_RESET=
else
    echo >&2 'dialog: command not found'
    echo >&2 'whiptail: command not found'
    exit 127
fi

# TODO: check that "$1" is set or fail with usage
if [ "$#" -ne 1 ] || ! head -c1 "$1" >/dev/null; then
    echo "Usage: $(basename "$0") JSON_FILE"
    exit 1
fi

draw_menu() {
    local menu_json menu_items selected exitcode new_menu_json the_command escaped_command

    set -e
    menu_json=$(cat)
    mapfile -d $'\0' menu_items < <(
        jq -j '
       .subcommands
       | sort_by(.subcommands | length > 0 | not)
       | (map(.title | length) | max) as $max_length_alt
       | .[]
       | .title,
         (" " * ($max_length_alt - (.title | length))),
         if .subcommands | length > 0 then "  » " else "    " end,
         "\u0000",
         .description,
         "\u0000"
    ' <<<"$menu_json" | head -c -1
    )
    set +e

    exec 3>&1
    selected=$($DIALOG_CMD 2>&1 1>&3 \
        "${DIALOG_OPTS[@]}" \
        --title "$(jq -r '.title' <<<"$menu_json")" \
        --menu "$(jq -r 'if .longDescription == null or .longDescription == "" then .description else .longDescription end' <<<"$menu_json")" 0 0 0 \
        "${menu_items[@]}")
    exitcode=$?
    exec 3>&-

    if [ "$exitcode" == "0" ]; then
        set -e
        selected=$(sed -r 's/ +»? $//g' <<<"$selected")
        new_menu_json=$(jq --arg selected "$selected" '.subcommands[] | select(.title | gsub("^\\s+|\\s+$";"") == $selected)' <<<"$menu_json")
        set +e
        if jq -e '.subcommands' >/dev/null <<<"$new_menu_json"; then
            if ! draw_menu <<<"$new_menu_json"; then
                draw_menu <<<"$menu_json"
            fi
        else
            set -e
            mapfile -d $'\0' the_command < <(
                jq -j '.command[] | . + "\u0000"' <<<"$new_menu_json" | head -c -1
            )
            escaped_command=$(/usr/bin/env bash -c 'set -x && echo "$@"' -- "${the_command[@]}" 2>&1 1>/dev/null | tail -c +8)
            set +e

            if $DIALOG_CMD \
                "${DIALOG_OPTS[@]}" \
                --title "$(jq -r '.title' <<<"$new_menu_json")" \
                --yesno "$(printf "%s\n\n${FMT_BOLD}❯ %s${FMT_RESET}\n\nAre you sure you want to run this command?" \
                    "$(jq -r 'if .longDescription == null or .longDescription == "" then .description else .longDescription end' <<<"$new_menu_json")" \
                    "$escaped_command")" \
                0 0; then
                set -x
                exec "${the_command[@]}"
            else
                draw_menu <<<"$menu_json"
            fi
        fi
    else
        return 1
    fi
}

draw_menu <"$1"
