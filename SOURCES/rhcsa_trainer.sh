#!/usr/bin/env bash
# RHCSA mini-trainer — by Alejandro Amoroso
set -euo pipefail

# ===== Exercício Q1 =====
Q1_DESC="Usar o vim para criar e salvar um arquivo hello.txt contendo 'hello world'"

check_Q1() {
  # Arquivo existe e conteúdo correto?
  if [[ -f hello.txt ]] && grep -qx "hello world" hello.txt; then
    # Verifica se o usuário usou 'vim hello.txt' no histórico
    if grep -Eq "vim(\s+\./)?hello\.txt" ~/.bash_history 2>/dev/null; then
      return 0   # OK → passou
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
    if "check_${id}"; then STATUS[$id]="PASSED"; else STATUS[$id]="PENDING"; fi
  done
}

board() {
  echo "==== RHCSA Trainer ===="
  for id in "${TASKS[@]}"; do
    desc_var="${id}_DESC"
    printf "%-3s | %-7s | %s\n" "$id" "${STATUS[$id]}" "${!desc_var}"
  done
}

usage() {
  cat <<EOF
Usage: rhcsa-trainer [command]

Commands:
  board   mostra status dos exercícios
  eval    reavalia os checks
  help    esta ajuda
EOF
}

case "${1-}" in
  eval) evaluate_all; board ;;
  board|"") evaluate_all; board ;;
  help|-h|--help) usage ;;
  *) echo "Unknown command: $1"; usage; exit 1 ;;
esac
