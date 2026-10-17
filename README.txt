PZ VIEWPOINT STARTER (Windows)
=============================

Instalador automatico do Project Zomboid em primeira/terceira pessoa com
Project Viewpoint + mods de imersao, HUD, armas e sobrevivencia.

REQUISITOS
- Windows 10 ou 11
- Steam + Project Zomboid (Build 42.21)
- Project Zomboid fechado
- Cerca de 4 GB livres
- 8 GB de RAM no minimo, 16 GB recomendado
- Placa de video com 8 GB de VRAM (recomendado)
- Qualquer usuario, pasta, disco ou biblioteca Steam em disco local

COMO INSTALAR
1. Extrai esta pasta para um disco local (nao uses pasta de rede).
2. Da dois cliques em Install.bat. Ele pede permissao de administrador.
3. Espera baixar o pacote unico (~1.1 GB) do Release do GitHub.
   Ele mostra porcentagem, velocidade e tempo restante.
   Quando aparecer "Extraindo", o download ja terminou; espere 1-3 min.
4. O instalador do ZombieBuddy vai abrir. No terminal dele:
   - escreve 1 e Enter  (Install ZombieBuddy)
   - escreve 2 e Enter  (Normal Launch)
   - escreve 2 e Enter  (ProjectZomboid64.json)
   - se pedir confirmacao, escreve y e Enter
   Com essa opcao a Steam pode ficar aberta.
5. Quando terminar, abre o Project Zomboid e cria um mundo NOVO.

O instalador encontra o Steam e o jogo em qualquer biblioteca/disco.
A memoria do jogo (heap) e ajustada automaticamente pela RAM do PC.

Os mods sao movidos para %USERPROFILE%\Zomboid\mods uma unica vez.
Depois, Install.bat e Activate-All.bat nao copiam 1 GB de novo; apenas
reescrevem o default.txt.

CONTROLES
- O ........ primeira pessoa
- Shift+O .. alternar primeira/terceira
- Botao do meio do mouse .. capturar/soltar cursor
- I ........ inventario
- H ........ saude
- K ........ construcao
- V ........ mirar (ADS)
- G ........ arremessar

INSTALAR TUDO DE UMA VEZ
O instalador ativa todos os mods juntos. Nao existe mais modo por levas.
  Activate-All.bat .... reaplica a lista completa (so escreve default.txt)
  Deactivate-All.bat .. move os mods para backups e limpa o default.txt
  Setup-Host.bat ...... configura o servertest.ini com todos os mods
  Repair.bat .......... repara ZombieBuddy/config apos update da Steam/PZ

SE DER ERRO
- Le C:\Users\<voce>\Zomboid\console.txt
- Testa os caminhos sem mudar nada:
  powershell -ExecutionPolicy Bypass -File .\Install.ps1 -CheckOnly
- Fecha o jogo e roda Install.bat de novo.
- Se o GitHub falhar, roda: Install.ps1 -UseSteamCmd
- Download manual (se travar):
  https://github.com/GustavoHeringerCurcio/pz-viewpoint-starter/releases/download/mods-v1/PZ-Viewpoint-Mods.tar
  Salva como %LOCALAPPDATA%\PZViewpoint\archive\PZ-Viewpoint-Mods.tar
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

MULTIPLAYER
- Cada amigo precisa rodar o Install.bat no proprio PC.
- Todos precisam da mesma versao do jogo e dos mesmos mods.
- O Host deve usar a mesma lista completa de mods.
- Os mods do default.txt valem para mundos novos single-player.
- Para hospedar co-op, roda Setup-Host.bat. Ele faz backup do
  servertest.ini e grava a lista completa de mods.
- Todos os jogadores precisam do mesmo pack.
- Viewpoint Roofs e WIP e nao foi testado em multiplayer; remove ele
  pelo menu Mods antes de hospedar.

NAO USE JUNTO
Knox Inventory, Tactical Grid Inventory, Equipment UI, CleanUI,
Modern Status ou Clean HotBar. O Viewpoint Interface ja faz o HUD.

CREDITOS
O pacote de mods e um espelho de conveniencia hospedado no Release do
GitHub. Os mods pertencem aos seus autores. Nao afiliado a The Indie Stone.

DESINSTALAR
- Roda Deactivate-All.bat para desativar os mods.
- Para remover o ZombieBuddy, roda o instalador dele e escolhe Uninstall.
