# Casino Empire Tycoon — Claude Context

## Game
Dropper-style Roblox tycoon. Players place casino machines/buildings on their lot,
earn chips passively, upgrade, and prestige. Multiple players share one server and
compete on a leaderboard.

---

## Toolchain & sync

### How Rojo works
Rojo syncs **files → Studio only** (one-way). Changes made directly inside Studio
(moving parts, editing terrain, adding models by hand) do NOT flow back to files.

- Code changes: edit `.luau` files here → Rojo pushes them to Studio automatically
- 3D/map changes: must be saved out of Studio as `.rbxm` model files and committed
- Never edit the same script in both Studio and a file editor at the same time

### Running the stack
```
rojo serve          # in project root — must be running for Studio to sync
```
Studio: Plugins tab → Rojo → Connect (port 34872)
Claude Code MCP: StudioMCP at `%LOCALAPPDATA%\Roblox\Versions\version-46693bc0bc244907\StudioMCP.exe`

### Rojo init-file pattern (CRITICAL — caused bugs before)
When a folder has an `init.server.luau` / `init.client.luau` / `init.luau`, that file
**becomes the folder's script**. This means:
- `script` inside `init.server.luau` = the `Server` script itself
- `script.Parent` = `ServerScriptService` (NOT the Server folder)
- To reach subfolders use `script.data`, `script.systems`, etc. (not `script.Parent.data`)
- Services two levels deep (e.g. `systems/PlacementService.luau`) use `script.Parent.Parent`
  to reach the Server script, which is correct

### RemoteEvent API (CRITICAL — caused bugs before)
Never call `:Connect()` directly on a RemoteEvent. Use:
- Server-side: `Remote.OnServerEvent:Connect(function(player, ...) end)`
- Client-side: `Remote.OnClientEvent:Connect(function(...) end)`
- Fire from server to one client: `Remote:FireClient(player, ...)`
- Fire from server to all clients: `Remote:FireAllClients(...)`
- Fire from client to server: `Remote:FireServer(...)`

### Requiring modules safely
Always use `WaitForChild` when requiring across boundaries:
```lua
-- CORRECT (server or client requiring shared modules)
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Foo = require(Shared.constants.Foo)

-- WRONG — direct index can fail if not yet replicated
local Foo = require(game.ReplicatedStorage.Shared.constants.Foo)
```

---

## Collaboration (two developers)

### Git workflow
- One person codes, the other pulls: `git pull` before starting any session
- Commit after a meaningful working chunk — not every small edit, not broken code
- Push: `git push` so the other person can pull
- Avoid editing the same file simultaneously — modules are small and focused so this
  should be rare

### Map / 3D work (friend's domain)
The friend works on terrain, part layout, and 3D models in Studio. Since Rojo is
one-way, their workflow is:
1. Build in Studio
2. Select the model/folder in Explorer → right-click → **Save to File** → save as
   `.rbxm` into `assets/models/` (create that folder if needed)
3. `git add assets/ && git commit -m "Add model: ..."  && git push`
4. The other developer pulls and the model is in source control

Place file (`.rbxl`) can also be committed periodically as a full snapshot:
- File → Save to File → save as `CasinoEmpire.rbxl` in project root → commit

### Model gotchas (CRITICAL — caused repeated bugs)
- **No Unions/CSG in casino machine models.** A `UnionOperation` frequently does NOT
  render its shape when the server clones the model at runtime — the part is there and
  anchored, but draws invisible. This made roulette/poker/blackjack table tops vanish in
  game while cards/chips/legs still showed. Build surfaces from plain `Part`s (or
  `Separate` the union back into parts) before saving the `.rbxm`. MeshParts are fine.
- **Where machine models go:** casino machine `.rbxm` files live in `assets/machines/`
  (synced to `ReplicatedStorage.Machines`); world decoration packs live in
  `assets/models/` (synced to `ServerStorage.Assets`). The **filename = the machine's
  `modelName`** in MachineData (matched case/space-insensitively), e.g. `RouletteTable.rbxm`.
- Embedded scripts in placed machine models are auto-stripped on clone, but free Toolbox
  models still ship junk — prefer clean models.

### Code / logic work (your domain)
Edit `.luau` files in `src/`. Rojo syncs them live. No Studio interaction needed
for pure logic changes.

### Studio settings needed (one-time per machine)
- **API Services**: Home → Game Settings → Security → Enable Studio Access to API Services
- **Script injection**: Plugins → Plugin Manager → Rojo → enable Script Injection

---

## Architecture

- **Server** (`src/server/`) — authoritative. All economy, data, NPC logic lives here.
- **Client** (`src/client/`) — input, UI, visual feedback only. Never trust client for economy.
- **Shared** (`src/shared/`) — constants, types, net definitions, pure utility functions.
- **GUI** (`src/gui/`) — LocalScripts that build ScreenGuis in code (keeps UI in source control).

## Key systems (server)
| File | Responsibility |
|------|---------------|
| `server/init.server.luau` | Bootstraps all systems in order |
| `server/data/DataManager.luau` | DataStore save/load, auto-save loop |
| `server/economy/EconomyService.luau` | Chip earning, spending, passive income tick |
| `server/systems/PlacementService.luau` | Machine/building placement validation |
| `server/systems/UpgradeService.luau` | Upgrade purchases and stat application |
| `server/systems/PrestigeService.luau` | Prestige reset logic |
| `server/systems/MonetizationService.luau` | MarketplaceService, PolicyService, loot cases |

## Key systems (client)
| File | Responsibility |
|------|---------------|
| `client/init.client.luau` | Bootstraps client controllers |
| `client/controllers/PlacementController.luau` | Ghost preview, click-to-place |
| `client/controllers/UIController.luau` | Opens/closes screen GUIs |

## GUI scripts (StarterGui)
| File | Responsibility |
|------|---------------|
| `gui/HUD.client.luau` | Top-bar chip counter + income rate display |
| `gui/Shop.client.luau` | Shop panel with machine buy buttons |

## Shared
| File | Responsibility |
|------|---------------|
| `shared/net/Remotes.luau` | All RemoteEvent/RemoteFunction definitions (single source of truth) |
| `shared/constants/GameConfig.luau` | Tunable numbers (income rates, upgrade costs, etc.) |
| `shared/constants/MachineData.luau` | Machine definitions (cost, income, model name) |
| `shared/types/ProfileTypes.luau` | Player data schema (typed) |
| `shared/utils/FormatNumber.luau` | 1234 → "1.2K" etc. |

---

## Luau conventions
- Use `local` for everything; no globals except Roblox services
- Type-annotate all functions: `function foo(x: number): string`
- Use `type` and `export type` in `shared/types/`; import with `require()`
- Services via `local X = game:GetService("X")` at top of file
- Remotes defined once in `Remotes.luau`, never created inline
- Passive income runs on server in a `task.spawn` loop, never on client
- All DataStore calls wrapped in `pcall`
- PolicyService check before ANY loot case purchase prompt
- Never fire client-side RemoteEvents to modify economy state

## Naming
- PascalCase: modules, types, services (`EconomyService`, `PlayerProfile`)
- camelCase: local variables, function parameters (`chipCount`, `playerId`)
- SCREAMING_SNAKE: constants at module top (`MAX_MACHINES`, `BASE_INCOME_RATE`)
- `*Service.luau` — server-only singleton
- `*Controller.luau` — client-only singleton
- `*Types.luau` — type definitions only

---

## Monetization compliance
- Loot cases: must call `PolicyService:GetPolicyInfoForPlayerAsync()` and check
  `AreRandomItemsRestricted` before showing purchase UI
- Display numerical drop odds before purchase (stored in `GameConfig`)
- All loot pulls award something (no empty outcomes)
- Casino machines are income generators only — no simulated wagering/betting mechanic

---

## Progression phases
1. **The Floor** — tutorial, basic machines (slots, roulette, card tables)
2. **The Resort** — hotel wing, restaurant, parking garage, VIP lounge; staff NPCs
3. **The Strip** — server leaderboard, prestige system, rival challenges
