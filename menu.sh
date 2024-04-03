#!/usr/bin/env bash

set -uo pipefail

# TODO: check for: dialog/whiptail, jq, sed

# TODO: check that "$1" is set or fail with usage

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
    selected=$(dialog 2>&1 1>&3 \
        --backtitle "nix-menu %NIX_MENU_VERSION%" \
        --colors --keep-tite --scrollbar --no-mouse \
        --ok-label "Select" --cancel-label "Back" \
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

            if dialog \
                --backtitle "nix-menu %NIX_MENU_VERSION%" \
                --colors --keep-tite --scrollbar --no-mouse \
                --title "$(jq -r '.title' <<<"$new_menu_json")" \
                --yesno "$(printf "%s\n\n\Zb\Z7❯ %s\Zn\n\nAre you sure you want to run this command?" \
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

draw_menu <example.json
