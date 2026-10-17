# PZ Viewpoint Starter

One-click Windows setup for **Project Zomboid Build 42.21** with **Project Viewpoint** first/third-person camera, a Tarkov-style interface, tactical gunplay, and immersion mods.

The installer downloads a **single all-in-one mod archive** from this repository's GitHub Releases and installs the ZombieBuddy Java loader. SteamCMD remains only as a fallback.

## Requirements

- Windows 10/11
- Steam + Project Zomboid (Build 42.21)
- Project Zomboid closed during installation
- ~4 GB free disk space
- 8 GB RAM minimum, 16 GB recommended
- GPU with 8 GB VRAM recommended (RX 6600 tested)
- Any Windows username, folder, drive, or Steam library on a local disk

## Install

1. Download or clone this repository to a local folder (not a network share).
2. Double-click **`Install.bat`**. It requests administrator permission automatically.
3. Wait while the installer downloads the ~1.1 GB archive from this repository's GitHub Release. It shows percentage, speed, and ETA. Download time depends on the connection; extraction takes another 1-3 minutes.
4. The ZombieBuddy installer opens. Type:
   - `1` + Enter — Install ZombieBuddy
   - `2` + Enter - Normal Launch
   - `2` + Enter - ProjectZomboid64.json
   - `y` + Enter if asked to confirm
   Steam can stay open with this option; the installer only patches the JSON launcher here.
5. Launch Project Zomboid and create a **new world**.

The installer finds Steam and Project Zomboid in any Steam library. It also
sets the Java heap automatically based on the PC's RAM.

Mods are moved into `%USERPROFILE%\Zomboid\mods` only once. Later runs of
`Install.bat` or `Activate-All.bat` do not copy the 1 GB again; activation
just rewrites `default.txt`.

## Controls

| Key | Action |
|---|---|
| `O` | First person |
| `Shift + O` | Toggle first/third person |
| Middle mouse | Capture/release cursor |
| `I` | Inventory |
| `H` | Health |
| `K` | Build |
| `V` | Aim down sights |
| `G` | Throw |

## What gets installed

All 38 mods are installed and enabled in one pass. The groups below are only
for documentation; there is no separate activation step.

| Group | Contents |
|---|---|
| `Pack1_Core` | ZombieBuddy, Viewpoint, Voxel Studio, Viewpoint Interface |
| `Pack2_Tactical` | Advanced Movement, Equipment Overlays, Throwables, True Ballistics, ADS |
| `Pack3_Atmosphere` | True Weathers, Minimap, Rain Cleans Blood, Immersive Blackouts, Thump, Collision, Push Doors |
| `Pack4_Survival` | Vanilla Foods, Bath/Shower, Repair Clothes, Virus Vaccine, Plumbing, damnlib, Containers!, Weapon Sling |
| `Pack5_QoL` | Draw On The Map, Skill Recovery Journal, errorMagnifier, Mod Update Alert, Spawn Selector |
| `Pack6_Extras` | Faster Reading, Immersive Driving, Visceral, Simple Crossbows |
| `Pack7_Immersion` | Immersive Effects, Camera Motion, Visible Loot, Roofs (WIP) |

The installer activates everything at once. There is no pack-by-pack mode.

- `Activate-All.bat` reapplies the full mod list; it only rewrites `default.txt`.
- `Deactivate-All.bat` moves the mods to `%USERPROFILE%\Zomboid\backups\mods-removed` and empties `default.txt`. Use `Deactivate-All.ps1 -Purge` to delete them.
- `Setup-Host.bat` writes the full mod list into `servertest.ini` for co-op hosting and creates a backup.
- After a Steam/PZ update, run `Repair.bat` (or `Install.bat` again) to restore the ZombieBuddy agent and launchers.

## Notes

- `default.txt` applies to **new single-player worlds**. For co-op, run `Setup-Host.bat`; every player must use the same pack.
- **Roofs** and **Visible Loot** are WIP.
- **Camera Motion** and **Roofs** are not multiplayer-tested; remove them in the Mods menu before hosting.
- Do not combine with Knox Inventory, Tactical Grid Inventory, Equipment UI, CleanUI, Modern Status, or Clean HotBar.
- If roofs disappear after fast travel, raise `memory.packMiB` in `%USERPROFILE%\Zomboid\viewpoint-live.properties`.

## Troubleshooting

- Read `%USERPROFILE%\Zomboid\console.txt`.
- Check paths without changing anything:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\Install.ps1 -CheckOnly
  ```
- Re-run `Install.bat` if the GitHub archive failed. If GitHub is blocked, run `Install.ps1 -UseSteamCmd`.
- Manual download if the installer download stalls:
  `https://github.com/GustavoHeringerCurcio/pz-viewpoint-starter/releases/download/mods-v1/PZ-Viewpoint-Mods.tar`
  Save it as `%LOCALAPPDATA%\PZViewpoint\archive\PZ-Viewpoint-Mods.tar`, then run `Install.bat` again.
- If Windows runs it from inside the ZIP, `Install.bat` copies itself to `%LOCALAPPDATA%\PZViewpoint\installer` automatically.
- If Windows blocks the script: right-click `Install.bat` -> Properties -> Unblock.
- If UAC is denied, right-click `Install.bat` -> Run as administrator.
- ZombieBuddy installer cannot detect the mod: run `Install.bat` again; it now creates the expected Workshop folder automatically and falls back to copying `ZombieBuddy.jar`/`zbNative.dll` manually.
- ZombieBuddy missing: run `Install.bat` again and choose `1`, then `2`, then `2`.
- If you previously chose `Both`, remove `-agentlib:zbNative --` from Steam Launch Options; otherwise the agent may load twice.
- `Setup-Host.bat` requires `Zomboid\Server\servertest.ini` to exist. If a mod is client-only and the host fails, restore the backup created in `Zomboid\backups`.

## Credits

All mods belong to their respective authors. The release archive is a convenience mirror for this setup; it is not claimed as original work. Not affiliated with The Indie Stone.

## License

MIT for the scripts in this repository.
