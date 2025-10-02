#!/usr/bin/env bash
set -euo pipefail

APP="rhcsa-trainer"
RAW_BASE="${RAW_BASE:-https://raw.githubusercontent.com/LdeAlejandro/rhcsa-trainer/main}"
TARGET="${TARGET:-}"

# Decide destino: /usr/local/bin (com sudo) senão ~/.local/bin
if [[ -z "${TARGET}" ]]; then
  if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    TARGET="/usr/local/bin/$APP"
  else
    TARGET="$HOME/.local/bin/$APP"
    mkdir -p "$HOME/.local/bin"
    # garante PATH
    if ! command -v "$APP" >/dev/null 2>&1 && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
      RC="$HOME/.bashrc"; [[ -n "${ZSH_VERSION-}" ]] && RC="$HOME/.zshrc"
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$RC"
      echo ">> Added ~/.local/bin to PATH in $RC (abra novo shell ou: source $RC)"
    fi
  fi
fi

echo ">> Baixando $APP para $TARGET"
TMP="$(mktemp)"
curl -fsSL "$RAW_BASE/$APP" -o "$TMP"
chmod +x "$TMP"

# (Opcional) checagem de integridade
if [[ -n "${SHA256-}" ]]; then
  echo "$SHA256  $TMP" | sha256sum -c -
fi

# Instala
if [[ "$TARGET" == /usr/local/bin/* ]]; then
  sudo install -m 0755 "$TMP" "$TARGET"
else
  install -m 0755 "$TMP" "$TARGET"
fi
rm -f "$TMP"

echo ">> Instalado: $TARGET"
echo ">> Teste: $APP -h || $APP"
