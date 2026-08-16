# Batocera Netbook — Notebook Retrô (Intel Atom N455 / 2GB RAM)

Projeto de um notebook retrô com **Batocera v30 (32-bit)**, otimizado para um
**Atom N455 1.66GHz, 2GB RAM, GPU GMA3150, tela 1024x600** e SSD 120GB.

Este repositório contém **todas as configurações, scripts e o passo a passo**
para reproduzir o sistema do zero — inclusive o fix de tela preta (GMA3150),
otimizações de boot, swap e as ROMs/BIOS suportadas.

---

## 📋 Hardware alvo

| Componente | Modelo |
|---|---|
| CPU | Intel Atom N455 (1.66GHz, 2 núcleos, 32-bit) |
| RAM | 2GB DDR3 |
| GPU | Intel GMA3150 (Pineview, 64 instruções shader) |
| Tela | LVDS 1024x600 |
| SSD | 120GB |
| Rede | Wi-Fi + Ethernet |

> ⚠️ **Importante:** o Batocera **v30 é a última versão 32-bit**. Versões
> posteriores (v31+) só existem para x86_64. Para este notebook use v30.

---

## 🚀 Passo a passo completo de instalação

### 1. Download do Batocera v30 (32-bit)

Baixe o `boot.tar.xz` do mirror oficial (cerca de 1GB):

- **URL:** `https://mirrors.o2switch.fr/batocera/x86/stable/last/boot.tar.xz`
- **MD5:** `14bf306ba87ee85cad877755dfe3e1ed`

> O `last` aponta para a última versão 32-bit (v30). Se o mirror mudar,
> use a página do projeto: `https://batocera.org/download` (seção x86 32-bit).

### 2. Gravar o sistema no SSD

O notebook inicialmente tinha Batocera 5.25 instalado e foi atualizado para v30.
Para instalar do zero:

1. Baixe o **instalador oficial do Batocera v30** (arquivo `.img.gz`) de
   `https://mirrors.o2switch.fr/batocera/x86/stable/last/` (procure por
   `batocera-30-...-x86_64.img.gz` — para 32-bit, use o `i686` se disponível).
2. Grave com **balenaEtcher** ou **Rufus** em um pendrive USB.
3. Inicialize o notebook pelo pendrive (tecla de boot: F12 ou F2 no BIOS).
4. Escolha **INSTALL BATOCERA TO ANOTHER INTERNAL DRIVE/SSD**.
5. Aguarde a instalação e remova o pendrive.

> ✅ Se já houver Batocera funcionando (como no caso deste notebook), a
> **atualização por pacote** funciona assim:
> - Envie `boot.tar.xz` para `/userdata/system/upgrade/`
> - Execute: `batocera-es-swissknife --update` **ou** reinicie o sistema
>   (o Batocera detecta o pacote e extrai para `/boot` automaticamente).

### 3. Primeiro boot e ajustes básicos

1. Ligue o notebook — o Batocera sobe direto no EmulationStation (ES).
2. Configure Wi-Fi (menu > Network) ou use cabo Ethernet.
3. Descubra o IP do notebook (`ifconfig` via SSH ou menu System).
4. Acesse por SSH: `ssh root@IP` — **senha padrão: `linux`**.

### 4. Corrigir a TELA PRETA (GMA3150) — obrigatório no v30

O Xorg 1.20 do Batocera v30 usa `modesetting` com **glamor**, que exige
**128 instruções de shader** — a GMA3150 tem apenas **64**, causando tela preta.

**Correção:** criar `/userdata/system/.xserverrc` com:

```sh
#!/bin/sh
# GMA3150 fix: force software rendering (glamor needs 128 instructions, this GPU has 64)
export LIBGL_ALWAYS_SOFTWARE=1
export MESA_LOADER_DRIVER_OVERRIDE=swrast
exec /usr/bin/X "$@"
```

Arquivo pronto em [`configs/.xserverrc`](configs/.xserverrc). Transfira via
SMB/SCP e dê `chmod +x`.

> Resultado: EmulationStation roda em 1024x600 com renderização por software.
> Jogos 8/16-bit rodam perfeitamente.

### 5. Aplicar todas as otimizações (script automático)

Transfira o repositório para o notebook (SMB: `\\IP\share`) e execute:

```bash
chmod +x setup.sh
./setup.sh
```

Ou faça manualmente (o que o script faz):

| Arquivo | Origem → Destino | Efeito |
|---|---|---|
| `configs/custom.sh` | `/userdata/system/custom.sh` | Para serviços pesados, ativa swap 2GB, swappiness 60 e **mute no boot** |
| `configs/.xserverrc` | `/userdata/system/.xserverrc` | Fix tela preta (software rendering) |
| `configs/batocera.conf` | `/userdata/system/batocera.conf` | Desliga Kodi, Bluetooth, PS3, xarcade, música de fundo e verificações |
| `configs/batocera-boot.conf` | `/boot/batocera-boot.conf` | Desliga Wi-Fi no boot (ganho de velocidade) |

> **Importante sobre o `custom.sh`:** o Batocera v30 faz **boot paralelo** e o
> `/etc/init.d/S99custom` executa o `custom.sh` em background — a 1ª execução
> pode morrer durante o `sleep 5`. O script é seguro: a 2ª execução (que ocorre
> na prática) completa o trabalho. Não remova o `sleep 5`.

### 6. Criar o swap (2GB) — evita travamentos com 2GB de RAM

O `custom.sh` ativa o swap automaticamente se `/userdata/swapfile` existir.
Para criar (uma vez só):

```bash
dd if=/dev/zero of=/userdata/swapfile bs=1M count=2048
chmod 600 /userdata/swapfile
mkswap /userdata/swapfile
```

---

## 🎮 ROMs (colocar em `/userdata/roms/`)

Copie os arquivos de ROM para a pasta do sistema correspondente
(**via SMB: `\\IP\share\roms\`** — usuário `root`, senha `linux`):

| Sistema | Pasta | Extensões |
|---|---|---|
| SNES / Super Nintendo | `snes` | `.smc` `.sfc` `.zip` |
| Game Boy Advance | `gba` | `.gba` `.zip` |
| Game Boy Color | `gbc` | `.gbc` `.zip` |
| Game Boy | `gb` | `.gb` `.zip` |
| Master System | `mastersystem` | `.sms` `.zip` |
| Mega Drive / Genesis | `megadrive` | `.bin` `.gen` `.smd` `.zip` |
| NES | `nes` | `.nes` `.zip` |
| Game Gear | `gamegear` | `.gg` `.zip` |
| Neo Geo | `neogeo` | `.zip` |
| PC Engine | `pcengine` | `.pce` `.zip` |

> ⚠️ **Limitação do hardware:** o Atom N455 roda muito bem 8/16-bit.
> Sistemas pesados (PS2, PSP, N64, PSX, Saturn, Dreamcast) **não rodam bem**.
> Foque em: SNES, Mega Drive, Master System, NES, GB/GBC/GBA, Game Gear.

### Coleção atual instalada (válida, testada)

| Sistema | Jogos | Tamanho |
|---|---|---|
| SNES | 1.354 | 1.5 GB |
| GBA | 1.143 | 2.9 GB |
| GBC | 391 | 383 MB |
| Master System | 308 | 276 MB |
| Mega Drive | 184 | 234 MB |
| Game Boy | 200 | 144 MB |

---

## 💾 BIOS (colocar em `/userdata/bios/`)

Copie via SMB para `\\IP\share\bios\`:

| Arquivo | Sistema |
|---|---|
| `gb_bios.bin` | Game Boy |
| `gbc_bios.bin` | Game Boy Color |
| `gba_bios.bin` | Game Boy Advance |
| `bios_E.sms` / `bios_J.sms` / `bios_U.sms` | Master System |
| `sgb_bios.bin` / `sgb_boot.bin` / `sgb2_boot.bin` | Super Game Boy (SNES) |
| `SGB1.sfc` / `SGB2.sfc` | Super Game Boy |
| `neogeo.zip` | Neo Geo |

---

## 🔧 Otimizações aplicadas (detalhes)

### O que o `custom.sh` faz no boot
1. Aguarda 5s (boot paralelo do v30)
2. **Mata** serviços desnecessários: `lircd`, `sixad`, `bluetoothd`, `rngd`,
   `ntpd`, `avahi-daemon`, `thd` (IR remoto, PS3 controllers, Bluetooth,
   entropia, NTP, avahi e teclas multimídia)
3. Ativa o **swap** `/userdata/swapfile` se não estiver ativo
4. Define **swappiness = 60**
5. **Mute** o áudio no boot

### Tempo de boot medido
| Estado | Tempo até SSH |
|---|---|
| Batocera 5.25 original | ~140s |
| v30 + otimizações | ~84s |

### Configurações desligadas no `batocera.conf`
- `kodi.enabled=0` — Kodi desligado
- `bluetooth.enabled=0`, `ps3.enabled=0`, `sixad.enabled=0`
- `xarcade.enabled=0`
- `audio.bgmusic=0` — música de fundo desligada
- `updates.enabled=0` — não checa atualizações

---

## 📁 Estrutura do repositório

```
batocera-netbook/
├── README.md            ← este arquivo (passo a passo completo)
├── setup.sh             ← aplica todas as configs automaticamente
├── configs/
│   ├── custom.sh        ← script de boot (serviços + swap + mute)
│   ├── .xserverrc       ← fix tela preta GMA3150
│   ├── batocera.conf    ← config principal otimizada
│   ├── batocera.conf.bak← backup da config original
│   └── batocera-boot.conf ← config de boot (Wi-Fi desligado)
├── roms/                ← (adicione suas ROMs aqui, organizadas por sistema)
└── bios/                ← (adicione suas BIOS aqui)
```

---

## 🔐 Acesso padrão do Batocera

| Item | Valor |
|---|---|
| SSH | `ssh root@IP` (senha `linux`) |
| SMB | `\\IP\share` (usuário `root`, senha `linux`) |
| Usuário ES | `root` |
| Tecla de reboot ES | Menu do ES → System Settings → Reboot |