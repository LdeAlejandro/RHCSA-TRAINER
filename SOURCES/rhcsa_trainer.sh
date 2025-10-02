#!/usr/bin/env bash
# RHCSA mini-trainer — by Alejandro Amoroso
set -euo pipefail

# ===== Colors (portable via tput) =====
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)

# ===== Exercício Q1 =====
Q1_DESC="Usar o vim para criar e salvar um arquivo hello.txt contendo 'hello world'"

check_Q1() {
  # garante que o histórico atual foi salvo
  if [ -n "${BASH_VERSION-}" ]; then
    builtin history -a 2>/dev/null || true
  fi

  # Arquivo existe e conteúdo correto?
  if [[ -f hello.txt ]] && grep -qx "hello world" hello.txt; then
    # Procurar por "vim hello.txt" ou "vim ./hello.txt" no histórico
    if grep -Eq '(vim|vi)[[:space:]]+(\./)?hello\.txt' ~/.bash_history; then
      return 0
    else
      echo "[FALHOU] Arquivo correto, mas não encontrei uso de 'vim hello.txt' no histórico."
      return 1
    fi
  fi
  return 1
}

# ===== Infra do Trainer =====
TASKS=(Q1)
declare -A STATUS

evaluate_all() {
  for id in "${TASKS[@]}"; do
    if check_"$id"; then
      STATUS[$id]="${GREEN}PASSED${RESET}"
    else
      STATUS[$id]="${RED}PENDING${RESET}"
    fi
  done
}

reset_all() {
  for id in "${TASKS[@]}"; do
    STATUS[$id]="${YELLOW}PENDING${RESET}"
  done
  echo ">> Progress reset: all tasks are now ${YELLOW}PENDING${RESET}."
   # clean bash history
  : > "$HOME/.bash_history" 2>/dev/null || true

  #delete hello.txt
  rm -f hello.txt
}

board() {
  echo -e "${CYAN}==== RHCSA Trainer ====${RESET}"
  for id in "${TASKS[@]}"; do
    desc_var="${id}_DESC"
    printf "%b%-3s%b | %b | %s\n" "$YELLOW" "$id" "$RESET" "${STATUS[$id]}" "${!desc_var}"
  done
}

usage() {
  cat <<EOF
Usage: rhcsa-trainer [command]

Commands:
  board   mostra status dos exercícios
  eval    reavalia os checks
  reset   marca todos como PENDING
  help    esta ajuda
EOF
}

case "${1-}" in
  eval) evaluate_all; board ;;
  board|"") evaluate_all; board ;;
  reset) reset_all; board ;;
  help|-h|--help) usage ;;
  *) echo "Unknown command: $1"; usage; exit 1 ;;
esac
