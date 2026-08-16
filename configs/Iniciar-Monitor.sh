#!/bin/bash
# Executavel do Monitor do PC - abre em tela cheia no display do notebook
# Uso: ./Iniciar-Monitor.sh   (ou rodar com duplo clique / F1 no EmulationStation)
DIR="$(dirname "$(readlink -f "$0")")"
pkill -f 'xterm -fullscreen' 2>/dev/null
sleep 1
DISPLAY=:0 setsid xterm -fullscreen -bg black -fg green -fa monospace -fs 14 -e "$DIR/monitor-pc.sh" >/dev/null 2>&1 &
echo "Monitor iniciado na tela. Ctrl+C na tela para sair."