#!/bin/bash
# ============================================================
# Batocera Netbook - Setup automatico de otimizacoes
# Executar NO NOTEBOOK (via SSH ou terminal) como root:
#   chmod +x setup.sh && ./setup.sh
# ============================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
USERDATA="/userdata/system"

echo "=== Batocera Netbook Setup ==="

# --- 1. custom.sh (servicos + swap + mute) ---
echo "[1/4] Instalando custom.sh..."
cp "$SCRIPT_DIR/configs/custom.sh" "$USERDATA/custom.sh"
chmod +x "$USERDATA/custom.sh"
bash -n "$USERDATA/custom.sh" && echo "  custom.sh: sintaxe OK"

# --- 2. .xserverrc (fix tela preta GMA3150) ---
echo "[2/4] Instalando .xserverrc (fix GMA3150)..."
cp "$SCRIPT_DIR/configs/.xserverrc" "$USERDATA/.xserverrc"
chmod +x "$USERDATA/.xserverrc"

# --- 3. batocera.conf (otimizacoes) ---
echo "[3/4] Instalando batocera.conf otimizado..."
if [ -f "$USERDATA/batocera.conf" ] && [ ! -f "$USERDATA/batocera.conf.bak" ]; then
    cp "$USERDATA/batocera.conf" "$USERDATA/batocera.conf.bak"
    echo "  backup criado: batocera.conf.bak"
fi
cp "$SCRIPT_DIR/configs/batocera.conf" "$USERDATA/batocera.conf"

# --- 4. batocera-boot.conf (boot mais rapido) ---
echo "[4/4] Instalando batocera-boot.conf..."
cp "$SCRIPT_DIR/configs/batocera-boot.conf" "/boot/batocera-boot.conf"

# --- swap (se nao existir) ---
if [ ! -f /userdata/swapfile ]; then
    echo "[extra] Criando swap 2GB (uma vez)..."
    dd if=/dev/zero of=/userdata/swapfile bs=1M count=2048 status=none
    chmod 600 /userdata/swapfile
    mkswap /userdata/swapfile >/dev/null
fi

echo ""
echo "=== Concluido! Reinicie o sistema para aplicar. ==="
echo "    reboot"