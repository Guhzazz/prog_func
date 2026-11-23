jogadas=()
while ./sgleam run menu.gleam "${jogadas[@]}"; do
  read -rp 'Sua escolha: ' escolha || break
  [[ $escolha == q ]] && break
  jogadas+=("$escolha")
done