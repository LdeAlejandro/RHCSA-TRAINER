#!/usr/bin/env bash
# RHCSA mini-trainer — by Alejandro Amoroso

# ===== Exercício Q1 =====
Q1_DESC="Criar um arquivo hello.txt contendo 'hello world'"
check_Q1() { [[ -f hello.txt ]] && grep -qx "hello world" hello.txt; }

TASKS=(Q1)
declare -A STATUS

evaluate_all() {
  for id in "${TASKS[@]}"; do
    if "check_${id}"; then STATUS[$id]="PASSED"; else STATUS[$id]="PENDING"; fi
  done
}
board() {
  echo "==== RHCSA Mini-Trainer ===="
  for id in "${TASKS[@]}"; do
    desc_var="${id}_DESC"
    printf "%-3s | %-7s | %s\n" "$id" "${STATUS[$id]}" "${!desc_var}"
  done
}
usage() {
  cat <<EOF
Usage: rhcsa-trainer [command]

Commands:
  board     mostra status dos exercícios
  eval      reavalia os checks
  help      esta ajuda
EOF
}

case "${1-}" in
  eval) evaluate_all; board ;;
  board|"") evaluate_all; board ;;
  help|-h|--help) usage ;;
  *) echo "Unknown command: $1"; usage; exit 1 ;;
esac
