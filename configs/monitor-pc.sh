#!/bin/bash
# ============================================================
# MONITOR DO PC - painel de CPU/RAM/TEMP em tempo real no notebook
# Teste 1: Terminal SSH + LibreHardwareMonitor (chave SSH ja configurada)
#
# Uso NO NOTEBOOK:
#   ./monitor-pc.sh
#   (Ctrl+C para sair)
#
# Requisitos (ja instalados):
#   - OpenSSH Server no PC (192.168.1.2) com chave do notebook em authorized_keys
#   - C:\PC-Monitor\monitor-sensors.ps1 + LibreHardwareMonitorLib.dll no PC
#   - Dropbear no notebook usa a chave /root/.ssh/id_dropbear
# ============================================================

PC_IP="192.168.1.2"
PC_USER="Jony"
SSH_KEY="/root/.ssh/id_dropbear"

# Note: dropbear do Batocera nao suporta -o ConnectTimeout/StrictHostKeyChecking
SSH_CMD="ssh -i $SSH_KEY"

CMD_REMOTE='powershell -NoProfile -ExecutionPolicy Bypass -File C:\PC-Monitor\monitor-sensors.ps1'

while true; do
    clear
    echo "============================================="
    echo "  MONITOR DO PC: $PC_IP  ($(date +'%d/%m %H:%M:%S'))"
    echo "============================================="
    $SSH_CMD "$PC_USER@$PC_IP" "$CMD_REMOTE" 2>/dev/null
    echo "---------------------------------------------"
    echo "  atualizando a cada 5s | Ctrl+C p/ sair"
    sleep 5
done