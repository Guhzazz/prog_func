sgleam=$(command -v sgleam || command -v sgleam.exe)  # no WSL o binário do Windows se chama sgleam.exe
jogadas=()
while "$sgleam" run menu.gleam "${jogadas[@]}" </dev/null; do  
  read -rp 'Sua escolha: ' escolha || break
  [[ $escolha == q ]] && break
  jogadas+=("$escolha")
done
