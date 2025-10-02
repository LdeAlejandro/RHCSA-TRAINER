#!/usr/bin/env bash
# RHCSA mini-trainer — by Alejandro Amoroso
set -euo pipefail

# ===== Cores com fallback =====
if command -v tput >/dev/null && [ -t 1 ]; then
  RED=$(tput setaf 1); GREEN=$(tput setaf 2); YELLOW=$(tput setaf 3); CYAN=$(tput setaf 6); RESET=$(tput sgr0)
else
  RED=""; GREEN=""; YELLOW=""; CYAN=""; RESET=""
fi

# Use o HISTFILE real (não dependa de ~/.bash_history)
HISTFILE="${HISTFILE:-$HOME/.bash_history}"

# ===== Exercício Q1 =====
Q1_DESC="Usar o vim para criar e salvar um arquivo hello.txt contendo 'hello world'"

check_Q1() {
  # sincronia extra (se o shell chamador não fez flush por algum motivo)
  builtin history -a 2>/dev/null || true
  builtin history -n 2>/dev/null || true

  # Arquivo e conteúdo
  [[ -f hello.txt ]] && grep -qx "hello world" hello.txt || return 1

  # Versão estrita (apenas 'vim hello.txt' ou 'vi hello.txt' e './hello.txt')
  if grep -Eq '(^|[[:space:]])(vi|vim)[[:space:]]+(\./)?hello\.txt([[:space:]]|$)' "$HISTFILE"; then
    return 0
  else
    echo "[FALHOU] Arquivo ok, mas não encontrei 'vim hello.txt' no histórico."
    return 1
  fi
}

# ===== Infra =====
TASKS=(Q1)
declare -A STATUS

evaluate_all() {
  for id in "${TASKS[@]}"; do
    if "check_${id}"; then STATUS[$id]="${GREEN}PASSED${RESET}"
    else STATUS[$id]="${RED}PENDING${RESET}"; fi
  done
}

reset_all() {
  for id in "${TASKS[@]}"; do STATUS[$id]="${YELLOW}PENDING${RESET}"; done
  rm -f hello.txt || true
  # limpa histórico em disco e (se possível) em memória
  : > "$HISTFILE" 2>/dev/null || true
  builtin history -c 2>/dev/null || true
  builtin history -w 2>/dev/null || true
  echo ">> Progress reset: all tasks are now ${YELLOW}PENDING${RESET}."
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
  board   mostra status
  eval    reavalia
  reset   zera progresso
  help    esta ajuda
EOF
}

case "${1-}" in
  eval)  evaluate_all; board ;;
  board|"") evaluate_all; board ;;
  reset) reset_all; board ;;
  help|-h|--help) usage ;;
  *) echo "Unknown command: $1"; usage; exit 1 ;;
esac
