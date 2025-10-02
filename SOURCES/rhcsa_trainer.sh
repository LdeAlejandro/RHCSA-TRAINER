#!/usr/bin/env bash
set -euo pipefail

BASHRC="$HOME/.bashrc"
TAG="# >>> RHCSA trainer shim >>>"
END="# <<< RHCSA trainer shim <<<"

read -r -d '' SHIM <<'EOF'
# >>> RHCSA trainer shim >>>
# Garante flush do histórico da SESSÃO antes de rodar o binário
rhcsa-trainer() {
  builtin history -a
  builtin history -n
  ~/.local/bin/rhcsa-trainer-bin "$@"
}
# (Opcional) flush a cada ENTER:
# export PROMPT_COMMAND='history -a; history -n; '"$PROMPT_COMMAND"
# <<< RHCSA trainer shim <<<
EOF

# Instala o shim no ~/.bashrc (se faltar)
if ! grep -qF "$TAG" "$BASHRC" 2>/dev/null; then
  printf "\n%s\n%s\n%s\n" "$TAG" "$SHIM" "$END" >> "$BASHRC"
  echo "[rhcsa-trainer] Shim instalado no ~/.bashrc."
  echo "Abra um novo terminal ou rode:  source ~/.bashrc"
fi

# Se já existe função no shell atual, use-a; senão, execute via subshell interativo
if declare -F rhcsa-trainer >/dev/null 2>&1; then
  rhcsa-trainer "${@-}"
else
  bash -ic "rhcsa-trainer ${*@Q}"
fi
