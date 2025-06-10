board=(" " " " " " " " " " " " " " " ")

savefile="savegame.txt"
turns=0

save_game() {
    printf '%s' "${board[@]}" > "$savefile"
    echo "" >> "$savefile"
    echo "$turns" >> "$savefile"
}

load_game() {
    if [[ -f $savefile ]]; then
        echo "save. upl? (y/n)"
        read -r answer
        if [[ "$answer" == "y" ]]; then

            local line
            read -r line < "$savefile"
            turns=$(sed -n '2p' "$savefile")


            for ((i=0; i<9; i++)); do
                board[$i]="${line:i:1}"

                if [[ -z "${board[$i]}" ]]; then
                    board[$i]=" "
                fi
            done
            echo "upl."
            return
        fi
    fi

    for i in {0..8}; do board[$i]=" "; done
    turns=0
}


print_board() {
    echo ""
    echo " ${board[0]} | ${board[1]} | ${board[2]}"
    echo "---+---+---"
    echo " ${board[3]} | ${board[4]} | ${board[5]}"
    echo "---+---+---"
    echo " ${board[6]} | ${board[7]} | ${board[8]}"
    echo ""
}

check_win() {
    local s=$1
    local w=(
        "0 1 2" "3 4 5" "6 7 8"
        "0 3 6" "1 4 7" "2 5 8"
        "0 4 8" "2 4 6"
    )
    for combo in "${w[@]}"; do
        set -- $combo
        if [[ "${board[$1]}" == "$s" && "${board[$2]}" == "$s" && "${board[$3]}" == "$s" ]]; then
            return 0
        fi
    done
    return 1
}

ai_move() {
    while true; do
        move=$((RANDOM % 9))
        if [[ "${board[$move]}" == " " ]]; then
            board[$move]="O"

            break
        fi
    done
    save_game
}

load_game

while true; do
    print_board

    echo "your turn (1-9):"
    read -r move

    if ! [[ "$move" =~ ^[1-9]$ ]]; then
        echo "❌"
        continue
    fi

    index=$((move - 1))

    if [[ "${board[$index]}" != " " ]]; then
        echo "❌"
        continue
    fi

    board[$index]="X"
    ((turns++))
    save_game

    if check_win "X"; then
        print_board
        echo "🎉"
        rm -f "$savefile"
        break
    fi

    if [[ $turns -eq 9 ]]; then
        print_board
        echo "🤝"
        rm -f "$savefile"
        break
    fi

    ai_move
    ((turns++))

    if check_win "O"; then
        print_board
        echo "💀"
        rm -f "$savefile"
        break
    fi

    if [[ $turns -eq 9 ]]; then
        print_board
        echo "🤝"
        rm -f "$savefile"
        break
    fi
done
