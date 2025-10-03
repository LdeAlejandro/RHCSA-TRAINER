#!/usr/bin/env bash
# RHCSA mini-trainer — by Alejandro Amoroso
set -euo pipefail

# ===== Colors (portable via tput) =====
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)

# ===== Start trainer =====
start_monitor() {
  RHCSA_SHM_DIR="$RHCSA_SHM_DIR" expect <<'EOF'
    set shm_dir $env(RHCSA_SHM_DIR)
    file mkdir $shm_dir

    proc mark {name} {
      global shm_dir
      catch {exec sh -c "touch $shm_dir/$name"}
    }

    spawn bash --noprofile --norc -i
    send_user "\n\[RHCSA TRAINER] Shell monitorado. Digite 'exit' para sair.\n"


    interact {
      -o -re {^vim[ \t]+(\./)?hello\.txt(\s|$)} {
        mark "Q1.vim_used"
        send_user "\n>> ✅ Detectado 'vim hello.txt'\n"
      }
      -o -re {^vi[ \t]+(\./)?hello\.txt(\s|$)} {
        mark "Q1.vim_used"
        send_user "\n>> ✅ Detectado 'vi hello.txt'\n"
      }
    }
EOF
}

# ===== Check expect and install if not found =====
if ! command -v expect >/dev/null 2>&1; then
  echo ">> 'expect' não encontrado, instalando..."
  sudo dnf install -y expect || sudo yum install -y expect || {
    echo "ERRO: não consegui instalar 'expect'. Instale manualmente."; exit 1;
  }
fi

# ===== Question flags directory =====
RHCSA_SHM_DIR="/dev/shm/rhcsa-trainer"
mkdir -p "$RHCSA_SHM_DIR"

# ===== Exercício Q1 =====
Q1_DESC="Usar o vim para criar e salvar um arquivo hello.txt contendo 'hello world'"

check_Q1() {
  if [[ -f hello.txt ]] && grep -qx "hello world" hello.txt; then
    [[ -f "$RHCSA_SHM_DIR/Q1.vim_used" ]] || { 
        echo "[FALHOU] Arquivo ok, mas não vi uso de 'vim hello.txt' no shell monitorado."; 
        return 1
    }
    return 0
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

  rm -f hello.txt
  rm -f "$RHCSA_SHM_DIR"/* 2>/dev/null || true
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

Commands:
  start   abre shell monitorado
  board   mostra status dos exercícios
  eval    reavalia os checks
  reset   marca todos como PENDING
  help    esta ajuda
EOF
}

case "${1-}" in
  start) start_monitor ;;
  eval) evaluate_all; board ;;
  board|"") evaluate_all; board ;;
  reset) reset_all; board ;;
  help|-h|--help) usage ;;
  *) echo "Unknown command: $1"; usage; exit 1 ;;
esac
