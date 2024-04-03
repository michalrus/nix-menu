#!/usr/bin/env bash

set -euo pipefail

exec dialog \
    --backtitle "nix-menu 0.5.4" \
    --colors --keep-tite --ok-label "Select" --cancel-label "Back" --scrollbar \
    --title "Menu example" \
    --menu "$(printf "Choose an option\n\nand a \Zbmulti-line string\Zn!\n")" 25 78 16 \
    "Add User" "Add a user to the system." \
    "Modify User" "Modify an existing user." \
    "List Users" "List all users on the system." \
    "Add Group" "Add a user group to the system." \
    "Modify Group" "Modify a group and its list of members." \
    "List Groups" "List all groups on the system." \
    "Add User" "Add a user to the system." \
    "Modify User" "Modify an existing user." \
    "List Users" "List all users on the system." \
    "Add Group" "Add a user group to the system." \
    "Modify Group" "Modify a group and its list of members." \
    "List Groups" "List all groups on the system." \
    "Add User" "Add a user to the system." \
    "Modify User" "Modify an existing user." \
    "List Users" "List all users on the system." \
    "Add Group" "Add a user group to the system." \
    "Modify Group" "Modify a group and its list of members." \
    "List Groups" "List all groups on the system." \
    "Zażółć" "Zażółć gęślą jaźń."
