# PZ Viewpoint Starter

Windows setup for **Project Zomboid Build 42.21** with **Project Viewpoint** first/third-person camera, tactical gunplay, immersion mods, and a selectable **Medium** or **Advanced** modpack.

The installer downloads a versioned mod archive from this repository's GitHub Releases, installs ZombieBuddy, and activates only the pack you choose. SteamCMD remains only as a fallback.

## Requirements

- Windows 10/11
- Steam + Project Zomboid (Build 42.21)
- Project Zomboid closed during installation
- **Medium:** ~4 GB free disk space
- **Advanced:** ~5 GB free disk space
- 8 GB RAM minimum, 16 GB recommended
- GPU with 8 GB VRAM recommended (RX 6600 tested)
- Any Windows username, folder, drive, or Steam library on a local disk

## Install

1. Download or clone this repository to a local folder (not a network share).
2. Double-click **`Install.bat`**. It requests administrator permission automatically.
3. In the console, choose the modpack:
   - `1` + Enter - **Medium** (current pack, 38 client mods)
   - `2` + Enter - **Advanced** (57 client mods, includes Medium + additions)
   - Enter alone selects Medium.
4. Wait for the archive download and extraction. Medium is about 1.1 GB; Advanced is about 1.3 GB.
5. The ZombieBuddy installer opens. Type:
   - `1` + Enter - Install ZombieBuddy
   - `2` + Enter - Normal Launch
   - `2` + Enter - ProjectZomboid64.json
   - `y` + Enter if asked to confirm
   Steam can stay open with this option; the installer only patches the JSON launcher here.
6. Launch Project Zomboid. For a new world, create one. For an existing save, continue normally.

The installer finds Steam and Project Zomboid in any Steam library. It also sets the Java heap automatically based on the PC's RAM.

The chosen profile is saved in `%USERPROFILE%\Zomboid\ViewpointPacks\profile.txt`, so `Activate-All.bat` and `Setup-Host.bat` reuse it without asking again.

## Profiles

| Profile | Client mods | Host IDs | Archive | Use |
|---|---:|---:|---|---|
| **Medium** | 38 | 39 | `mods-v1` | Current pack, unchanged; safest for the existing save |
| **Advanced** | 57 | 58 | `mods-v2` | Medium + fixes, 3D world, realism, swimming, and RV |

Advanced is **additive**: it does not remove or replace the Medium mods. It is built on top of the same base groups.

Command-line examples:

```powershell
powershell -ExecutionPolicy Bypass -File .\Install.ps1 -Profile Medium
powershell -ExecutionPolicy Bypass -File .\Install.ps1 -Profile Advanced
```

## What gets installed

### Medium - current pack

| Group | Contents |
|---|---|
| `Pack1_Core` | ZombieBuddy, Viewpoint, Voxel Studio, Viewpoint Interface |
| `Pack2_Tactical` | Advanced Movement, Equipment Overlays, Throwables, True Ballistics, ADS |
| `Pack3_Atmosphere` | True Weathers, Minimap, Rain Cleans Blood, Immersive Blackouts, Thump, Collision, Push Doors |
| `Pack4_Survival` | Vanilla Foods, Bath/Shower, Repair Clothes, Virus Vaccine, Plumbing, damnlib, Containers!, Weapon Sling |
| `Pack5_QoL` | Draw On The Map, Skill Recovery Journal, errorMagnifier, Mod Update Alert, Spawn Selector |
| `Pack6_Extras` | Faster Reading, Immersive Driving, Visceral, Simple Crossbows |
| `Pack7_Immersion` | Immersive Effects, Camera Motion, Visible Loot, Roofs (WIP) |

### Advanced - additions

| Group | Contents |
|---|---|
| `Pack8_AdvancedFixes` | Surface Fix, Door Fix, Barricade Fix, Light Fix, Viewpoint QOL, Right Click Fix |
| `Pack9_AdvancedWorld` | 3D Doors, Gates & Garages; 3D Curtains & Blinds; 3D Windows; 3D Fences |
| `Pack10_AdvancedRealism` | True Weathers Gameplay, Immersive Map, Foraging, Fishing, 3D Helicopter Event, True Swimming, Construction 1P |
| `Pack11_AdvancedVehicles` | GridRV, GridRVHost |

Advanced deliberately does **not** include KK's Tree, WinterFX, Immersive Snow, Tile Fix, Rolling Hills, Better Terrain, True Water, Yeah It's Water, Living Props, KK's Shelves, Working TVs, Shoot to Thrill, Blood VFX, or Physics & Collision.

## Save compatibility

Advanced is designed to be added to the existing save:

- All fixes, UI mods, 3D doors/windows/curtains/fences, map, foraging, fishing, and the helicopter are client-side or visual and do not write world data.
- `True Weathers Gameplay` changes weather and zombie senses at runtime; it does not generate or modify the map.
- `True Swimming` explicitly supports being added to an existing save.
- `Construction 1P` adds first-person construction actions; it does not change generated terrain.
- `GridRV` is the only addition that creates new entities. It supports existing saves, but it is **WIP**: back up the save, and new RVs only spawn in areas that have not been explored yet.

Do not switch **Advanced -> Medium** on the same save after using an RV. Restore the backup or use a new save instead. Medium -> Advanced is additive and is supported with a backup.

Advanced does not include mods that alter terrain, map tiles, roofs, or water, so it does not require a new world.

## Backups

Before installing Advanced, the installer creates:

`%USERPROFILE%\Zomboid\backups\save-before-advanced-<date-time>\`

It contains:

- `Saves\Multiplayer\servertest`
- `Saves\Multiplayer\servertest_player`
- `Server\servertest.ini`
- `Server\servertest_SandboxVars.lua`
- `mods\default.txt`

Configuration files are also backed up to `Zomboid\backups\setup-<date-time>`.

To restore: close the game/host, rename the current save folder, copy the backup folders back into `Zomboid\Saves\Multiplayer`, restore the `Server` files, then reinstall the matching profile.

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

## Hosting and activation

- `Activate-All.bat` reapplies the saved profile's mod list; it only rewrites `default.txt`.
- `Deactivate-All.bat` moves the mods to `Zomboid\backups\mods-removed` and empties `default.txt`. Use `Deactivate-All.ps1 -Purge` to delete them.
- `Setup-Host.bat` writes the saved profile's mod list into `servertest.ini` and creates a backup. Medium writes 39 IDs; Advanced writes 58.
- After a Steam/PZ update, run `Repair.bat` (or `Install.bat` again) to restore the ZombieBuddy agent and launchers.
- `Verify-Packs.ps1` shows which mods are installed. Add `-Profile Medium` or `-Profile Advanced` to inspect a specific pack.

For co-op, every player must install the same profile and the same archive version. With `DoLuaChecksum=true`, mismatched mods can prevent joining. `GridRVHost` is required on the host; in-game Host handles the RV bootstrap automatically. Dedicated servers may need the extra `-javaagent` described on the 3D RVs Workshop page.

## Notes

- `default.txt` applies to single-player worlds. For co-op, run `Setup-Host.bat`; every player must use the same pack.
- **Roofs** and **Visible Loot** are WIP.
- **Camera Motion** and **Roofs** are not fully multiplayer-tested.
- Do not combine with Knox Inventory, Tactical Grid Inventory, Equipment UI, CleanUI, Modern Status, or Clean HotBar.
- If roofs disappear after fast travel, raise `memory.packMiB` in `%USERPROFILE%\Zomboid\viewpoint-live.properties`.
- Advanced is heavier than Medium because of 3D windows/doors/fences and the RV interior. Test FPS near an RV and during a storm. If frame rate drops below 60, disable 3D Windows first, then 3D Fences, then the RV.

## Troubleshooting

- Read `%USERPROFILE%\Zomboid\console.txt`.
- Check paths without changing mods:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\Install.ps1 -CheckOnly -Profile Medium
  powershell -ExecutionPolicy Bypass -File .\Install.ps1 -CheckOnly -Profile Advanced
  ```
- Re-run `Install.bat` if the GitHub archive failed. If GitHub is blocked, run `Install.ps1 -UseSteamCmd -Profile Advanced`.
- Manual downloads if the installer stalls:
  - Medium: `https://github.com/GustavoHeringerCurcio/pz-viewpoint-starter/releases/download/mods-v1/PZ-Viewpoint-Mods.tar`
  - Advanced: `https://github.com/GustavoHeringerCurcio/pz-viewpoint-starter/releases/download/mods-v2/PZ-Viewpoint-Mods-Advanced.tar`
  - Save them as `%LOCALAPPDATA%\PZViewpoint\archive\<file name>`, then run `Install.bat` again.
- If Windows runs it from inside the ZIP, `Install.bat` copies itself to `%LOCALAPPDATA%\PZViewpoint\installer` automatically.
- If Windows blocks the script: right-click `Install.bat` -> Properties -> Unblock.
- If UAC is denied, right-click `Install.bat` -> Run as administrator.
- ZombieBuddy installer cannot detect the mod: run `Install.bat` again; it creates the expected Workshop folder automatically and falls back to copying `ZombieBuddy.jar`/`zbNative.dll` manually.
- ZombieBuddy missing: run `Install.bat` again and choose `1`, then `2`, then `2`.
- If you previously chose `Both`, remove `-agentlib:zbNative --` from Steam Launch Options; otherwise the agent may load twice.
- `Setup-Host.bat` requires `Zomboid\Server\servertest.ini` to exist. If the host fails, restore the backup created in `Zomboid\backups`.

## Credits

All mods belong to their respective authors. The release archive is a convenience mirror for this setup; it is not claimed as original work. Not affiliated with The Indie Stone.

## License

MIT for the scripts in this repository.
