PZ VIEWPOINT STARTER (Windows)
=============================

Instalador automatico do Project Zomboid em primeira/terceira pessoa com
Project Viewpoint + mods de imersao, HUD, armas e sobrevivencia.

REQUISITOS
- Windows 10 ou 11
- Steam + Project Zomboid (Build 42.21)
- Project Zomboid fechado
- Cerca de 2 GB livres
- 16 GB de RAM e placa de video com 8 GB de VRAM (recomendado)

COMO INSTALAR
1. Extrai esta pasta para onde quiser (ex.: Desktop).
2. Clica com o botao direito em Install.bat e escolhe
   "Executar como administrador".
3. Espera baixar os mods do Workshop. Pode demorar.
4. O instalador do ZombieBuddy vai abrir. No terminal dele:
   - escreve 1 e Enter  (Install ZombieBuddy)
   - escreve 1 e Enter  (Both)
   - se pedir confirmacao, escreve y e Enter
5. Quando terminar, abre o Project Zomboid e cria um mundo NOVO.

CONTROLES
- O ........ primeira pessoa
- Shift+O .. alternar primeira/terceira
- Botao do meio do mouse .. capturar/soltar cursor
- I ........ inventario
- H ........ saude
- K ........ construcao
- V ........ mirar (ADS)
- G ........ arremessar

TESTAR EM LEVAS
O instalador ativa todos os packs. Se algo falhar, volta ao pack anterior:
  Activate-Pack.ps1 -Pack Pack6_Extras -Cumulative
  Activate-Pack.ps1 -Pack Pack5_QoL -Cumulative
  Activate-Pack.ps1 -Pack Pack4_Survival -Cumulative
  Activate-Pack.ps1 -Pack Pack3_Atmosphere -Cumulative
  Activate-Pack.ps1 -Pack Pack2_Tactical -Cumulative
  Activate-Pack.ps1 -Pack Pack1_Core
Tambem podes usar Activate-All.bat e Deactivate-All.bat.

SE DER ERRO
- Le C:\Users\<voce>\Zomboid\console.txt
- Fecha o jogo e roda Install.bat de novo.
- Se o Windows bloquear o script, clica com o botao direito no
  Install.bat > Propriedades > Desbloquear.
- Se o ZombieBuddy nao instalar, roda Install.bat de novo e escolhe
  1 (Install) e 1 (Both).
- Se os telhados sumirem, aumenta memory.packMiB em
  C:\Users\<voce>\Zomboid\viewpoint-live.properties.

MULTIPLAYER
- Cada amigo precisa rodar o Install.bat no proprio PC.
- Todos precisam da mesma versao do jogo e dos mesmos mods.
- O Host deve usar os mesmos packs.
- Os mods do default.txt valem para mundos novos single-player. Para
  hospedar co-op, adiciona os mesmos mods nas configuracoes do Host.
- Viewpoint Roofs e WIP e nao foi testado em multiplayer; para jogar
  online, desativa o Pack7 primeiro.

NAO USE JUNTO
Knox Inventory, Tactical Grid Inventory, Equipment UI, CleanUI,
Modern Status ou Clean HotBar. O Viewpoint Interface ja faz o HUD.

CREDITOS
Este repositorio contem apenas scripts. Nenhum mod e redistribuido.
Os mods sao baixados do Steam Workshop/SteamCMD e pertencem aos seus
autores. Nao afiliado a The Indie Stone.

DESINSTALAR
- Roda Deactivate-All.bat para desativar os mods.
- Para remover o ZombieBuddy, roda o instalador dele e escolhe Uninstall.
