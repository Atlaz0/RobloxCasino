# Casino Empire Tycoon — Claude Context

## Game
Dropper-style Roblox tycoon. Players place casino machines/buildings on their lot,
earn chips passively, upgrade, and prestige. Multiple players share one server and
compete on a leaderboard.

## Architecture
- **Server** (`src/server/`) — authoritative. All economy, data, NPC logic lives here.
- **Client** (`src/client/`) — input, UI, visual feedback only. Never trust client for economy.
- **Shared** (`src/shared/`) — constants, types, net definitions, pure utility functions.
- **GUI** (`src/gui/`) — ScreenGui objects synced via Rojo.

## Key systems (server)
| File | Responsibility |
|------|---------------|
| `server/init.server.luau` | Bootstraps all systems in order |
| `server/data/DataManager.luau` | DataStore save/load, auto-save loop |
| `server/economy/EconomyService.luau` | Chip earning, spending, passive income tick |
| `server/systems/PlacementService.luau` | Machine/building placement validation |
| `server/systems/UpgradeService.luau` | Upgrade purchases and stat application |
| `server/systems/PrestigeService.luau` | Prestige reset logic |
| `server/systems/StaffService.luau` | VIP Staff NPC management |
| `server/systems/EventService.luau` | VIP Visitor events, rival challenges |
| `server/systems/MonetizationService.luau` | MarketplaceService, PolicyService, loot cases |

## Key systems (client)
| File | Responsibility |
|------|---------------|
| `client/init.client.luau` | Bootstraps client controllers |
| `client/controllers/PlacementController.luau` | Ghost preview, click-to-place |
| `client/controllers/UIController.luau` | Opens/closes screen GUIs |
| `client/controllers/EconomyController.luau` | Displays chip count, income rate |

## Shared
| File | Responsibility |
|------|---------------|
| `shared/net/Remotes.luau` | All RemoteEvent/RemoteFunction definitions |
| `shared/constants/GameConfig.luau` | Tunable numbers (income rates, upgrade costs, etc.) |
| `shared/constants/MachineData.luau` | Machine definitions (cost, income, model name) |
| `shared/types/ProfileTypes.luau` | Player data schema (typed) |
| `shared/utils/FormatNumber.luau` | 1234 → "1.2K" etc. |

## Luau conventions
- Use `local` for everything; no globals except Roblox services
- Type-annotate all functions: `function foo(x: number): string`
- Use `type` and `export type` in `shared/types/`; import with `require()`
- Services via `local X = game:GetService("X")` at top of file
- Remotes defined once in `Remotes.luau`, never created inline
- Passive income runs on server in a `task.defer` loop, never on client
- All DataStore calls wrapped in `pcall`
- PolicyService check before ANY loot case purchase prompt
- Never fire client-side RemoteEvents to modify economy state

## Monetization compliance
- Loot cases: must call `PolicyService:GetPolicyInfoForPlayerAsync()` and check
  `AreRandomItemsRestricted` before showing purchase UI
- Display numerical drop odds before purchase (stored in `GameConfig`)
- All loot pulls award something (no empty outcomes)
- Casino machines are income generators only — no simulated wagering/betting mechanic

## Naming
- PascalCase: modules, types, services (`EconomyService`, `PlayerProfile`)
- camelCase: local variables, function parameters (`chipCount`, `playerId`)
- SCREAMING_SNAKE: constants at module top (`MAX_MACHINES`, `BASE_INCOME_RATE`)
- `*Service.luau` — server-only singleton
- `*Controller.luau` — client-only singleton
- `*Types.luau` — type definitions only

## Progression phases
1. **The Floor** — tutorial, basic machines (slots, roulette, card tables)
2. **The Resort** — hotel wing, restaurant, parking garage, VIP lounge; staff NPCs
3. **The Strip** — server leaderboard, prestige system, rival challenges
