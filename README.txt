PZ VIEWPOINT STARTER (Windows)
=============================

Instalador do Project Zomboid em primeira/terceira pessoa com Project Viewpoint,
mods de imersao, HUD, armas e sobrevivencia. Agora voce escolhe entre dois pacotes:

  MEDIO    - 38 mods no cliente, 39 IDs no host. E o pacote atual, sem mudancas.
  AVANCADO - 57 mods no cliente, 58 IDs no host. Adiciona correcoes, mundo 3D,
             realismo, natacao e RV, sem remover os mods do Medio.

REQUISITOS
- Windows 10 ou 11
- Steam + Project Zomboid (Build 42.21)
- Project Zomboid fechado
- Medio: cerca de 4 GB livres
- Avancado: cerca de 5 GB livres
- 8 GB de RAM no minimo, 16 GB recomendado
- Placa de video com 8 GB de VRAM (recomendado)
- Qualquer usuario, pasta, disco ou biblioteca Steam em disco local

COMO INSTALAR
1. Extrai esta pasta para um disco local (nao uses pasta de rede).
2. Da dois cliques em Install.bat. Ele pede permissao de administrador.
3. No console, escolhe o modpack:
   - digita 1 e Enter  -> Medio
   - digita 2 e Enter  -> Avancado
   - Enter sozinho     -> Medio
4. Espera baixar o pacote escolhido. Medio tem ~1.1 GB; Avancado tem ~1.3 GB.
   Quando aparecer "Extraindo", o download ja terminou; espere 1-3 min.
5. O instalador do ZombieBuddy vai abrir. No terminal dele:
   - escreve 1 e Enter  (Install ZombieBuddy)
   - escreve 2 e Enter  (Normal Launch)
   - escreve 2 e Enter  (ProjectZomboid64.json)
   - se pedir confirmacao, escreve y e Enter
   Com essa opcao a Steam pode ficar aberta.
6. Abre o Project Zomboid. Para um mundo novo, cria o mundo.
   Para o save atual, continua normalmente.

O instalador encontra o Steam e o jogo em qualquer biblioteca/disco.
A memoria do jogo (heap) e ajustada automaticamente pela RAM do PC.

O perfil escolhido fica salvo em:
  %USERPROFILE%\Zomboid\ViewpointPacks\profile.txt

Depois, Activate-All.bat e Setup-Host.bat usam esse mesmo perfil sem perguntar
de novo. Para forcar um perfil pela linha de comando:
  powershell -ExecutionPolicy Bypass -File .\Install.ps1 -Profile Medium
  powershell -ExecutionPolicy Bypass -File .\Install.ps1 -Profile Advanced

O QUE ENTRA NO AVANCADO
- Correcoes: Surface Fix, Door Fix, Barricade Fix, Light Fix, Viewpoint QOL,
  Right Click Fix.
- Mundo 3D: 3D Doors/Gates/Garages, 3D Curtains & Blinds, 3D Windows, 3D Fences.
- Imersao: True Weathers Gameplay, Immersive Map, Foraging, Fishing,
  3D Helicopter Event, True Swimming, Construction 1P.
- Veiculos: GridRV + GridRVHost.

O Avancado NAO inclui KK's Tree, WinterFX, Immersive Snow, Tile Fix,
Rolling Hills, Better Terrain, True Water, Yeah It's Water, Living Props,
KK's Shelves, Working TVs, Shoot to Thrill, Blood VFX ou Physics & Collision.

SAVE ATUAL
O Avancado foi feito para ser adicionado ao save existente:
- Correcoes, UI, 3D, mapa, foraging, fishing e helicoptero sao client-side
  ou visuais e nao gravam dados do mundo.
- True Weathers Gameplay so calcula clima e sentidos em runtime; nao gera mapa.
- True Swimming e explicitamente seguro para adicionar em save existente.
- Construction 1P nao altera o terreno ja gerado.
- GridRV e o unico que cria entidades novas. Ele suporta save existente, mas e
  WIP: faca backup e lembre que RVs novos so aparecem em areas nao exploradas.

NAO troque de Avancado para Medio no mesmo save depois de usar o RV.
Restaure o backup ou use um save novo. Medio -> Avancado e aditivo e e seguro
com backup.

O Avancado nao inclui mods que alteram terreno, tiles, telhados ou agua,
entao nao exige mundo novo.

BACKUP
Antes de instalar o Avancado, o instalador cria:
  %USERPROFILE%\Zomboid\backups\save-before-advanced-<data-hora>\

Com:
- Saves\Multiplayer\servertest
- Saves\Multiplayer\servertest_player
- Server\servertest.ini
- Server\servertest_SandboxVars.lua
- mods\default.txt

Configuracoes tambem sao salvas em Zomboid\backups\setup-<data-hora>.
Para restaurar: fecha o jogo/host, renomeia o save atual, copia as pastas do
backup de volta para Zomboid\Saves\Multiplayer, restaura os arquivos de Server
e reinstala o mesmo perfil.

CONTROLES
- O ........ primeira pessoa
- Shift+O .. alternar primeira/terceira
- Botao do meio do mouse .. capturar/soltar cursor
- I ........ inventario
- H ........ saude
- K ........ construcao
- V ........ mirar (ADS)
- G ........ arremessar

ATIVACAO E HOST
  Activate-All.bat .... reaplica o perfil salvo (so escreve default.txt)
  Deactivate-All.bat .. move os mods para backups e limpa o default.txt
  Setup-Host.bat ...... configura o servertest.ini com o perfil salvo
  Verify-Packs.ps1 .... mostra os mods instalados; aceita -Profile
  Repair.bat .......... repara ZombieBuddy/config apos update da Steam/PZ

Medio grava 39 IDs no host. Avancado grava 58.
Cada amigo precisa do mesmo perfil e da mesma versao do arquivo.
Com DoLuaChecksum=true, mods diferentes podem impedir a entrada no servidor.
O GridRVHost precisa estar no host; o Host pelo menu do jogo cuida do bootstrap.
Servidor dedicado pode precisar do -javaagent extra descrito na pagina do 3D RVs.

SE DER ERRO
- Le C:\Users\<voce>\Zomboid\console.txt
- Testa os caminhos sem mudar mods:
  powershell -ExecutionPolicy Bypass -File .\Install.ps1 -CheckOnly -Profile Medium
  powershell -ExecutionPolicy Bypass -File .\Install.ps1 -CheckOnly -Profile Advanced
- Fecha o jogo e roda Install.bat de novo.
- Se o GitHub falhar, roda: Install.ps1 -UseSteamCmd -Profile Advanced
- Download manual (se travar):
  Medio:
  https://github.com/GustavoHeringerCurcio/pz-viewpoint-starter/releases/download/mods-v1/PZ-Viewpoint-Mods.tar
  Avancado:
  https://github.com/GustavoHeringerCurcio/pz-viewpoint-starter/releases/download/mods-v2/PZ-Viewpoint-Mods-Advanced.tar
  Salva como %LOCALAPPDATA%\PZViewpoint\archive\<nome do arquivo>
  e roda o Install.bat de novo.
- Se o Windows rodar direto do ZIP, o Install.bat copia o instalador
  para %LOCALAPPDATA%\PZViewpoint\installer automaticamente.
- Se o Windows bloquear o script, clica com o botao direito no
  Install.bat > Propriedades > Desbloquear.
- Se negar o pedido de administrador, clica com o botao direito no
  Install.bat > Executar como administrador.
- Se o ZombieBuddy nao detectar o mod, roda Install.bat de novo. O script
  cria a pasta da Workshop esperada e, se necessario, copia o JAR/DLL
  manualmente.
- Se o ZombieBuddy nao instalar, roda Install.bat de novo e escolhe
  1 (Install), 2 (Normal Launch) e 2 (ProjectZomboid64.json).
- Se antes escolheste "Both", remove -agentlib:zbNative -- das Steam
  Launch Options para o agente nao carregar duas vezes.
- Depois de atualizar o jogo pela Steam, roda Repair.bat.
- Para apagar os mods de vez: Deactivate-All.ps1 -Purge
- Se os telhados sumirem, aumenta memory.packMiB em
  C:\Users\<voce>\Zomboid\viewpoint-live.properties.

DESEMPENHO
O Avancado e mais pesado por causa das janelas/portas/cercas 3D e do interior
do RV. Testa o FPS perto do RV e durante tempestade. Se cair abaixo de 60,
desativa primeiro 3D Windows, depois 3D Fences, depois o RV.

MULTIPLAYER
- Cada amigo precisa rodar o Install.bat no proprio PC e escolher o mesmo perfil.
- Todos precisam da mesma versao do jogo e dos mesmos mods.
- O Host deve usar a mesma lista completa de mods.
- Para hospedar co-op, roda Setup-Host.bat. Ele faz backup do servertest.ini
  e grava a lista do perfil salvo.
- Roofs e WIP e nao foi testado em multiplayer; remova no menu Mods antes de
  hospedar se tiver problema.

NAO USE JUNTO
Knox Inventory, Tactical Grid Inventory, Equipment UI, CleanUI,
Modern Status ou Clean HotBar. O Viewpoint Interface ja faz o HUD.

CREDITOS
O pacote de mods e um espelho de conveniencia hospedado no Release do
GitHub. Os mods pertencem aos seus autores. Nao afiliado a The Indie Stone.

DESINSTALAR
- Roda Deactivate-All.bat para desativar os mods.
- Para remover o ZombieBuddy, roda o instalador dele e escolhe Uninstall.
