# HANDOFF — Dossiê Técnico Completo do Notebook Batocera

> Este arquivo é o registro completo para um agente/IA/técnico reproduzir o
> MESMO resultado sem precisar de conversa prévia. Leia tudo antes de agir.
> Última atualização: sessão de trabalho (instalação concluída e testada).

---

## 1. OBJETIVO

Transformar um notebook fraco em um console retrô com **Batocera v30 (32-bit)**
que: inicializa em ~84s, não trava, roda jogos 8/16-bit, tem swap de 2GB,
áudio mudo no boot e **sem tela preta** (bug da GPU GMA3150).

**Resultado final alcançado e verificado:** sistema 100% funcional.

---

## 2. HARDWARE (alvo fixo)

| Componente | Modelo | Observações críticas |
|---|---|---|
| CPU | Intel Atom N455 | 1.66GHz, 2 núcleos, **32-bit** (i686) |
| RAM | 2GB DDR3 | Pouca RAM → swap obrigatório |
| GPU | Intel GMA3150 (Pineview) | **64 instruções shader** → bug do glamor |
| Tela | LVDS 1024x600 | resolução final do ES |
| SSD | Kingston 120GB | /dev/sda2 = /userdata (~105GB) |
| Rede | Wi-Fi + Ethernet | Wi-Fi desligado no boot (ganho de tempo) |

**Regra de ouro:** Batocera **v30 é a ÚLTIMA versão 32-bit** (i686).
v31+ é só x86_64. Para este notebook: SEMPRE v30.

---

## 3. REDE E CREDENCIAIS

| Item | Valor |
|---|---|
| Modem/roteador | ZTE F670L — 192.168.1.1 |
| PC (este) | 192.168.1.2 (Ethernet) / 192.168.1.5 (Wi-Fi) |
| Notebook Batocera | **192.168.1.3** (hostname BATOCERA) |
| SSH | `ssh root@192.168.1.3` — senha **`linux`** |
| SMB | `\\192.168.1.3\share` — usuário **root**, senha **`linux`** |
| SMB do share | aponta para `/userdata` do notebook |

> ⚠️ IPs podem mudar (DHCP). Se o notebook não responder, verificar no modem.

---

## 4. ESTADO ATUAL DO SISTEMA (verificado na última sessão)

- **Batocera v30** (2021-03-02), kernel 5.10.15, arquitetura **i686**
- **Boot: ~84s** até SSH online (era ~140s no 5.25 original)
- **X :0** rodando com software rendering (fix .xserverrc), ES em **1024x600**
- **Swap 2GB ativo** (`/userdata/swapfile`, swappiness 60)
- **Serviços parados no boot:** lircd, sixad, bluetoothd, rngd, ntpd,
  avahi-daemon, thd (via custom.sh)
- **Mute no boot** (amixer set Master mute)
- **ROMs instaladas (~5.5GB):** SNES 1354, GBA 1143, GBC 391, Master System
  308, Mega Drive 184, GB 200
- **BIOS instaladas:** gb, gbc, gba, SMS(E/J/U), SGB (1+2), SGB1.sfc, SGB2.sfc
- **Gamelists geradas** pelo ES (SNES 351KB, GBA 271KB, etc.)
- **Disco:** ~96.8GB livres de 105GB
- **Repositório git local:** `E:\AI GAME DEV COMMANDER\batocera-netbook`
  (commit `b0899b8` — configs reais + setup.sh + README)

---

## 5. LINHA DO TEMPO COMPLETA (o que foi feito e POR QUÊ)

### Fase 1 — Diagnóstico (Batocera 5.25)
- Notebook travava no boot. Hardware identificado (Atom N455/2GB/GMA3150).
- Acesso via SSH root/linux + SMB share (root/linux).
- Batocera 5.25 (2020, i686) instalado em /boot, userdata em /dev/sda2.

### Fase 2 — Otimizações no 5.25
- `batocera.conf`: desligados kodi, bluetooth, ps3/sixad, xarcade, bgmusic,
  updates. Backup salvo em `batocera.conf.bak`.
- Criado swap 2GB: `dd if=/dev/zero of=/userdata/swapfile bs=1M count=2048;
  chmod 600; mkswap /userdata/swapfile`.
- `custom.sh` inicial: parar serviços + swapon + swappiness.

### Fase 3 — Upgrade 5.25 → v30
- Baixado `boot.tar.xz` (1.088.091.584 bytes) de
  `https://mirrors.o2switch.fr/batocera/x86/stable/last/`
- MD5 verificado: `14bf306ba87ee85cad877755dfe3e1ed`
- Transferido via SMB para `/userdata/system/upgrade/boot.tar.xz` (demorou
  ~10min), extraído para `/boot`, reboot. v30 instalado com sucesso.
- **Alternativa que NÃO funcionou:** wget/curl direto no notebook
  (timeout no mirror) e HTTP local no Windows (sem python; HttpListener =
  acesso negado).

### Fase 4 — BUG CRÍTICO: TELA PRETA no v30
- **Causa:** Xorg 1.20 do v30 usa modesetting com **glamor**, que exige
  **128 instruções de shader**. A GMA3150 tem apenas **64** → X falha → tela preta.
- **Fix:** criar `/userdata/system/.xserverrc`:
  ```
  export LIBGL_ALWAYS_SOFTWARE=1
  export MESA_LOADER_DRIVER_OVERRIDE=swrast
  exec /usr/bin/X "$@"
  ```
- Resultado: ES em 1024x600 com renderização por software. Testado OK.
- Obs.: X ativo é o `:0`. Um X de teste `:0` foi morto durante diagnóstico.

### Fase 5 — Refinamento do custom.sh (3 tentativas até acertar)
1. **v1 (init.d stop + killall multi-arg):** falhou no boot — os `stop`
   reportavam "No such process" porque **o boot do v30 é PARALELO** e o
   S99custom roda em background (`bash custom.sh $1 &`).
2. **v2 (loop pgrep):** BUG de precedência no shell — `pgrep A || pgrep B ||
   pgrep C && break` nunca executa o `break` (precedência `||`/`&&`) → script
   esperava 60s e o boot ficava LENTO (267s+). NÃO USAR ESSE PADRÃO.
3. **v3 (FINAL — atual):** `sleep 5` + **killall individual por serviço**
   (BusyBox falha com `killall -9 a b c` multi-arg) + swapon + swappiness +
   mute. **Funcionou.**

**Como o custom.sh atual se comporta no boot (IMPORTANTE):**
- O `/etc/init.d/S99custom` executa `bash /userdata/system/custom.sh $1 &`
  (background). A **1ª execução pode morrer durante o sleep 5** (boot paralelo),
  e uma **2ª execução completa o trabalho**. Isso é NORMAL e observado nos
  logs — não "corrigir" removendo o sleep 5.

### Fase 6 — Cópia de ROMs e BIOS
- ROMs de `E:\RetroBat\roms` e `F:\HD PS2\ROMS` (PC) → SMB do notebook.
- **Método que funciona para volume:** `robocopy origem \\192.168.1.3\share\roms\pasta /E /R:2 /W:2 /MT:8` (~11MB/s).
- Tabela copiada (ver §7).
- BIOS de `E:\RetroBat\bios` → `\\192.168.1.3\share\bios\`.
- Após cópia, o ES gera gamelist.xml automaticamente ao reiniciar.

### Fase 7 — Refresh do ES sem reboot
- `batocera-es-swissknife --restart` **mata o ES mas o openbox NÃO o relança**
  (comportamento observado). Depois disso, iniciar manualmente:
  `DISPLAY=:0 setsid emulationstation --windowed >/dev/null 2>&1 &`

---

## 6. ARQUIVOS DE CONFIGURAÇÃO (origem: `/userdata/system/` e `/boot/`)

| Arquivo | Destino no notebook | Papel |
|---|---|---|
| `configs/custom.sh` | `/userdata/system/custom.sh` | Boot: kill serviços + swap + swappiness 60 + mute |
| `configs/.xserverrc` | `/userdata/system/.xserverrc` | Fix tela preta (GMA3150) |
| `configs/batocera.conf` | `/userdata/system/batocera.conf` | Otimizações ES/Kodi/serviços |
| `configs/batocera.conf.bak` | backup | Original antes das mudanças |
| `configs/batocera-boot.conf` | `/boot/batocera-boot.conf` | Wi-Fi desligado no boot |
| `roms/LEIA-ME.txt` | — | Guia de pastas de ROMs |
| `bios/LEIA-ME.txt` | — | Guia de BIOS |

### Conteúdo do custom.sh (v3 FINAL — não alterar sem motivo)
```bash
#!/bin/bash
LOG=/userdata/system/custom.log
echo "custom.sh rodou em $(date)" >> $LOG
sleep 5
for name in lircd sixad-bin sixad bluetoothd rngd ntpd avahi-daemon thd; do
    killall -9 "$name" 2>>$LOG
done
grep -qs 'swapfile' /proc/swaps || swapon /userdata/swapfile 2>>$LOG
sysctl -w vm.swappiness=60 >> $LOG 2>&1
amixer set Master mute >> $LOG 2>&1
echo "custom.sh terminou em $(date)" >> $LOG
```

### Conteúdo do .xserverrc (fix tela preta)
```sh
#!/bin/sh
export LIBGL_ALWAYS_SOFTWARE=1
export MESA_LOADER_DRIVER_OVERRIDE=swrast
exec /usr/bin/X "$@"
```

---

## 7. ROMs INSTALADAS (verificadas com `find -type f`)

| Sistema | Pasta no notebook | Arquivos | Tamanho |
|---|---|---|---|
| SNES | /userdata/roms/snes | 1354 | 1.5 GB |
| GBA | /userdata/roms/gba | 1143 | 2.9 GB |
| GBC | /userdata/roms/gbc | 391 | 383 MB |
| Master System | /userdata/roms/mastersystem | 308 | 276 MB |
| Mega Drive | /userdata/roms/megadrive | 184 | 234 MB |
| Game Boy | /userdata/roms/gb | 200 | 144 MB |

### BIOS instaladas em /userdata/bios/
`gb_bios.bin`, `gbc_bios.bin`, `gba_bios.bin`, `bios_E.sms`, `bios_J.sms`,
`bios_U.sms`, `sgb_bios.bin`, `sgb_boot.bin`, `sgb2_boot.bin`, `SGB1.sfc`,
`SGB2.sfc`

---

## 8. PROBLEMAS CONHECIDOS E SOLUÇÕES (referência rápida)

| Problema | Causa | Solução |
|---|---|---|
| Tela preta no v30 | glamor precisa de 128 shader instr., GMA3150 tem 64 | `.xserverrc` com software rendering |
| custom.sh não para serviços no boot | boot paralelo + S99 em background | `sleep 5` + killall individual (v3) |
| Boot demorando 267s | loop pgrep com precedência errada (v2) | remover loop, usar v3 |
| killall multi-arg não mata nada | BusyBox killall com vários nomes falha | killall individual por nome |
| SMB "O caminho da rede não foi encontrado" | Samba instável para cópias grandes | usar SCP p/ pequenos, robocopy p/ grandes |
| wget/curl do notebook trava | mirror externo lento/timeout | baixar no PC e enviar via SMB/SCP |
| SCP com destino arquivo falha ("Not a directory") | Set-SCPItem só aceita diretório | `-Destination "/userdata/system/"` (com /) |
| `--restart` do ES não relança | openbox não reinicia ES | `DISPLAY=:0 setsid emulationstation --windowed &` |
| Invoke-SSHCommand timeout em reboot | sessão cai no reboot | reconectar; monitorar porta 22 com TcpClient |

---

## 9. PROCEDIMENTO DE INSTALAÇÃO DO ZERO (resumo executável)

1. Gravar Batocera v30 i686 (boot.tar.xz → extrair em /boot) ou usar
   instalador oficial.
2. Primeiro boot → configurar rede → SSH root/linux.
3. Copiar `.xserverrc` para `/userdata/system/` + `chmod +x` (fix tela preta).
4. Rodar `setup.sh` (configs + custom.sh + boot.conf) OU copiar manualmente
   os 4 arquivos de `configs/`.
5. Criar swap se não existir (dd + mkswap).
6. Reboot → verificar (comandos da §10).
7. Copiar ROMs (robocopy) e BIOS (SMB) para /userdata.
8. Reboot → ES gera gamelists → jogar.

---

## 10. COMANDOS DE VERIFICAÇÃO PÓS-BOOT (rodar via SSH)

```bash
# boot funcionou + ES ativo
ps aux | grep -E "X :|emulationstation" | grep -v grep
# custom.sh executou (deve ter "terminou" no log)
tail -6 /userdata/system/custom.log
# swap ativo
cat /proc/swaps | tail -2
# serviços parados
ps aux | grep -iE "lircd|rngd|ntpd|thd|avahi" | grep -v grep || echo PARADOS
# mute aplicado
amixer get Master | grep Mono   # deve mostrar [off]
# ROMs contadas
for d in snes gba gbc mastersystem megadrive gb; do
  echo "$d: $(find /userdata/roms/$d -type f | wc -l)"
done
# gamelists geradas
ls /userdata/roms/*/gamelist.xml | wc -l   # ~11
```

### Medição de boot (monitorar porta 22 com PowerShell)
```powershell
$sw = [Diagnostics.Stopwatch]::StartNew()
while ($sw.Elapsed.TotalSeconds -lt 280) {
  $c = New-Object Net.Sockets.TcpClient
  try { $r = $c.BeginConnect("192.168.1.3",22,$null,$null)
    if ($r.AsyncWaitHandle.WaitOne(2000) -and $c.Connected) {
      "SSH ONLINE em $([math]::Round($sw.Elapsed.TotalSeconds))s"; break } }
  catch {}; $c.Close(); Start-Sleep 5
}
```

---

## 11. PADRÃO SSH DO WINDOWS (Posh-SSH) — funciona sempre

```powershell
Import-Module Posh-SSH
$pw = ConvertTo-SecureString "linux" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential("root", $pw)
$s = New-SSHSession -ComputerName 192.168.1.3 -Credential $cred -AcceptKey -ConnectionTimeout 10
(Invoke-SSHCommand -SessionId $s.SessionId -Command "SEU-COMANDO-AQUI" -TimeOut 20).Output
Remove-SSHSession -SessionId $s.SessionId | Out-Null
# arquivo pequeno:
Set-SCPItem -ComputerName 192.168.1.3 -Credential $cred -AcceptKey `
  -Path "C:\local\arquivo" -Destination "/userdata/system/" -Force
```

⚠️ Sessões SSH NÃO persistem entre execuções do tool — reconectar sempre.
⚠️ Evitar `$` dentro do comando remoto (PowerShell interpola) — usar aspas
simples no comando ou variável `$cmd = '...'`.

---

## 12. COISAS QUE NÃO FUNCIONARAM (não perder tempo de novo)

- wget/curl no notebook para o mirror externo → timeout.
- HTTP server local no Windows (python ausente; HttpListener acesso negado).
- SMB para cópias pontuais pequenas em alguns momentos ("caminho da rede").
- Script v2 com loop pgrep (precedência `||`/`&&`).
- `Set-SCPItem` com destino sendo o NOME do arquivo (usar diretório).

---

## 13. LIMITES DO HARDWARE (expectativa de uso)

- Roda bem: NES, SNES, Mega Drive, Master System, GB/GBC/GBA, Game Gear,
  Neo Geo, PC Engine (8/16-bit, com render por software).
- **NÃO rodar:** PS2, PSP, N64, PSX, Saturn, Dreamcast (Atom N455 + 2GB).
- GBA pesado (16MB+) pode engasgar — aceitável na coleção atual.