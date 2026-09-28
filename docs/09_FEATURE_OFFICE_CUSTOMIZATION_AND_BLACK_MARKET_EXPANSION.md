# Feature Prompt Specification: Office Customization & Offshore Black Market Expansion

## Feature Summary & Vision
In the existing codebase, the **Offshore Ledger** (`OffshoreLedgerModal.gd`) offers only 3 one-time luxury vanity props and 3 basic consumable actions. Accumulating hundreds of thousands of dollars in illicit kickbacks loses excitement when there are few meaningful ways to invest that money.

This feature transforms the secret desk safe into a full-fledged **Mayoral Black Market & Office Customization Suite**. Players can spend their illicit wealth on permanent functional desk upgrades, clandestine investments that generate daily kickback dividends, and visual executive status symbols that permanently deck out City Hall.

---

## Catalog of Upgrades & Investments

### Category A: Functional Desk Hardware Upgrades
| Upgrade Item | Cost | Visual Asset on Desk | Mechanical Perk |
| :--- | :--- | :--- | :--- |
| **Italian Espresso Machine** | $35,000 | Chrome retro espresso machine beside coffee mug | Permanently raises Max Inspect Focus from 4 to 5 pips; free morning refill |
| **Tape Dictaphone Recorder** | $25,000 | Cassette recorder with spinning spools beside Red Phone | Tap incoming calls to gain leverage; unlocks Blackmail action against callers |
| **Shredder Silencer & Shute** | $20,000 | Under-desk chute attachment | Shredding documents produces zero noise and never raises tampering suspicion |
| **Banker's Emerald Lamp** | $15,000 | Green glass vintage pull-chain lamp | Casts warm luminous tint over paper; increases discrepancy match visual cues |

### Category B: Clandestine Slush Fund Investments
| Financial Asset | Cost | Passive Benefit | Risk / Drawback |
| :--- | :--- | :--- | :--- |
| **Panama Shell Holding Corp** | $50,000 | Generates +4% daily interest on all stashed offshore wealth | Triggers random international tax leak events if balance > $200k |
| **Judicial Defense Retainer** | $45,000 | Blocks the first Federal Arrest trigger, commuting it to a public fine | One-time shield consumption |
| **Tabloid Media Stake** | $40,000 | End-of-day newspaper headlines are always spun favorably | Reduces public opinion penalties by 50% |

### Category C: Executive Visual Prestige Props
- **Mahogany Presidential Desk Finish** ($30,000): Replaces blotter texture with polished burl mahogany.
- **Panoramic Bulletproof Glass Window** ($40,000): Window frame reinforced with steel rivets; immune to protest mob rock thrown animations.
- **Solid Gold Pen Set** ($25,000): Replaces cursor with a fountain pen dripping gold ink.

---

## Architecture & File Additions

### Files to Modify:
1. `scripts/ui/OffshoreLedgerModal.gd`:
   - Expand `LUXURY_CATALOG` to include functional equipment and financial asset tabs.
   - Add purchase callbacks that emit signals for equipment unlocking.
2. `scripts/desk/DeskView.gd`:
   - Add node placeholders for new visual desk props (`%PropEspressoMachine`, `%PropDictaphone`, `%PropBankersLamp`).
   - Listen for equipment purchase signals to toggle visibility and apply permanent gameplay buffs.
3. `scripts/autoload/GameManager.gd`:
   - In `advance_day()`: Calculate and credit daily investment dividends (e.g. +4% interest from shell companies).
4. `scripts/autoload/SaveLoadManager.gd`:
   - Ensure all unlocked equipment and investment flags are serialized into `game_state["event_flags"]`.
5. `data/localization.csv`:
   - Add localized titles, descriptions, and effect descriptions for the expanded black market catalog.

---

## Step-by-Step Implementation Instructions

### Step 1: Update `OffshoreLedgerModal.gd` Catalog
```gdscript
const EXPANDED_EQUIPMENT_CATALOG: Array[Dictionary] = [
    {
        "id": "espresso_machine",
        "cost": 35000,
        "flag": "FLAG_EQUIP_ESPRESSO_MACHINE",
        "title_key": "EQUIP_ESPRESSO_TITLE",
        "desc_key": "EQUIP_ESPRESSO_DESC",
        "effect_key": "EQUIP_ESPRESSO_EFFECT",
        "icon": "☕"
    },
    {
        "id": "dictaphone",
        "cost": 25000,
        "flag": "FLAG_EQUIP_DICTAPHONE",
        "title_key": "EQUIP_DICTAPHONE_TITLE",
        "desc_key": "EQUIP_DICTAPHONE_DESC",
        "effect_key": "EQUIP_DICTAPHONE_EFFECT",
        "icon": "🎙️"
    },
    {
        "id": "panama_shell",
        "cost": 50000,
        "flag": "FLAG_INVEST_PANAMA_SHELL",
        "title_key": "INVEST_PANAMA_TITLE",
        "desc_key": "INVEST_PANAMA_DESC",
        "effect_key": "INVEST_PANAMA_EFFECT",
        "icon": "💼"
    }
]
```

### Step 2: Implement Dividend Yield in `GameManager.gd`
```gdscript
func _apply_daily_investments() -> void:
    if event_flags.get("FLAG_INVEST_PANAMA_SHELL", false):
        var interest: int = int(float(personal_wealth) * 0.04)
        if interest > 0:
            personal_wealth += interest
            print("[GameManager] Panama shell holding paid $%d in dividends." % interest)
```
Connect `_apply_daily_investments()` to `day_started` in `GameManager.gd`.

### Step 3: Implement Max Focus Expansion in `DeskView.gd`
```gdscript
func _get_max_focus() -> int:
    var base_max: int = MAX_INSPECT_FOCUS
    if GameManager != null and GameManager.event_flags.get("FLAG_EQUIP_ESPRESSO_MACHINE", false):
        base_max += 1
    return base_max
```
Replace all references to `MAX_INSPECT_FOCUS` with `_get_max_focus()`.

---

## Verification & Automated Test Plan
Create test script `tests/test_black_market_expansion.gd`:
1. **Espresso Machine Buff**: Purchase Espresso Machine via Offshore Ledger. Verify `_get_max_focus() == 5` and desk prop becomes visible.
2. **Investment Dividends**: Set `personal_wealth = 100,000` with Panama Shell unlocked. Advance day. Verify personal wealth increases to $104,000.
3. **Save/Load Persistence**: Save game with unlocked Dictaphone. Reload save slot. Verify Dictaphone prop remains active and visible.
