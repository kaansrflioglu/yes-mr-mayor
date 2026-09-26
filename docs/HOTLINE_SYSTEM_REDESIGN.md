# Red Telephone Hotline System & Dynamic Callers Roadmap
**Project:** *Yes, Mr. Mayor!* (`yes-mr-mayor`)  
**Document Target:** Feature Specification & Phased Engineering Plan  
**Module:** `scripts/desk/RedTelephone.gd` ➔ `scripts/gameplay/HotlineManager.gd`  
**Status:** Approved Architectural Specification  

---

## 1. Problem Statement & Motivation
Currently, [`scripts/desk/RedTelephone.gd`](file:///c:/Users/User/Documents/yes-mr-mayor/scripts/desk/RedTelephone.gd) has a single hardcoded interaction:
```gdscript
func accept_deal() -> void:
    dialog_panel.visible = false
    AudioManager.play_cash_register()
    GameManager.apply_resolution({
        "budget": -30000,
        "suspicion": -20.0
    })
```
Every time the hotline rings, the Party Boss makes the identical $30,000 PAC diversion pitch. This makes the telephone predictable and immersion-breaking after Day 2. The Red Telephone should be an unpredictable, high-stakes municipal lifeline featuring diverse callers with conflicting agendas.

---

## 2. Caller Archetypes & Thematic Calls

We define **6 distinct Caller Archetypes** with unique narrative flavor, audio ringtones, and moral dilemmas:

```
                                  ┌────────────────────────┐
                                  │   RED TELEPHONE (DESK) │
                                  └───────────┬────────────┘
                                              │
         ┌──────────────────┬─────────────────┼─────────────────┬──────────────────┐
         ▼                  ▼                 ▼                 ▼                  ▼
┌──────────────────┐ ┌──────────────┐ ┌──────────────┐ ┌────────────────┐ ┌────────────────┐
│ 1. PARTY BOSS    │ │ 2. POLICE    │ │ 3. MAFIA     │ │ 4. JOURNALIST  │ │ 5. ARCHITECT   │
│ Political favors,│ │ Vice raids,  │ │ Shakedowns,  │ │ Leaks, hush    │ │ Early collapse │
│ PAC money        │ │ crackdowns   │ │ bribes       │ │ money, smear   │ │ warnings       │
└──────────────────┘ └──────────────┘ └──────────────┘ └────────────────┘ └────────────────┘
```

| ID | Caller Entity | Typical Request / Dilemma | Accept Consequence | Reject Consequence |
| :--- | :--- | :--- | :--- | :--- |
| `CALL_PARTY_PAC` | **Party Boss Vance** | Divert municipal cash to the election super PAC in exchange for suppressing federal probes. | Budget -$30,000 <br>Suspicion -20% | Public Opinion +5% <br>Party Relations Strain |
| `CALL_POLICE_CHIEF` | **Police Chief Ramos** | Requests emergency authorization for a heavy-handed raid on dockland cartels. | Budget -$15,000 <br>Suspicion -10% <br>Opinion -10% (Excessive force) | Opinion +8% <br>Cartel Violence Rises |
| `CALL_MAFIA_DON` | **Don Falcone** | Offers offshore cash to halt a municipal fire code inspection at an underground club. | Offshore Wealth +$45,000 <br>Suspicion +15% | Opinion +10% <br>Mafia Threats Flag |
| `CALL_TABLOID_LEAK` | **Investigative Reporter** | Threatens to publish an exposé on the Mayor's offshore accounts unless hush money is wired. | Offshore Wealth -$25,000 <br>Suspicion -15% | Opinion -18% <br>Tabloid Headline Leaked |
| `CALL_CHIEF_ENGINEER`| **Chief Engineer Elena** | Urgent confidential warning: a pending riverbed project has catastrophic soil liquefaction. | Free Discrepancy Reveal on active document | Risk of approving catastrophic failure |
| `CALL_WHISTLEBLOWER` | **Anonymous City Clerk** | Tips off the Mayor that the current applicant is using an expired Chamber of Commerce seal. | Highlights forged seal tag instantly | Nothing (Information lost) |

---

## 3. Data Schema: `HotlineCallData.gd`

```gdscript
class_name HotlineCallData
extends Resource

@export var id: String = ""
@export var caller_name_key: String = ""
@export var caller_title_key: String = ""
@export var message_key: String = ""
@export var accept_btn_key: String = ""
@export var reject_btn_key: String = ""

@export var effects_accept: Dictionary = {
    "budget": 0,
    "personal_wealth": 0,
    "public_opinion": 0.0,
    "suspicion": 0.0,
    "reveal_violation": false
}

@export var effects_reject: Dictionary = {
    "budget": 0,
    "personal_wealth": 0,
    "public_opinion": 0.0,
    "suspicion": 0.0
}

@export var min_day: int = 1
@export var max_day: int = 30
@export var required_flag: String = ""
```

---

## 4. Phased Implementation Plan

### Phase 1: Data Model & Call Database
- Create `scripts/resources/HotlineCallData.gd`.
- Create `data/hotline_calls.json` containing 15 unique emergency calls across all 6 archetypes.
- Add corresponding localization keys to `data/localization.csv` across `en`, `tr`, and `es`.

### Phase 2: Dynamic Hotline Controller
- Refactor [`RedTelephone.gd`](file:///c:/Users/User/Documents/yes-mr-mayor/scripts/desk/RedTelephone.gd) to pick from `all_calls` filtered by `current_day` and active `event_flags`.
- Implement dynamic caller avatar or badge (e.g. Police Badge, Party Rose, Skull & Crossbones, Press Card).
- Add distinct audio SFX for incoming calls (e.g., frantic double ring vs. calm secure tone).

### Phase 3: Special Mechanics (Whistleblower & Investigative Tips)
- If a call offers an investigative tip (`reveal_violation: true`), trigger `active_document.highlight_suspicious_field()` or auto-uncover one hidden violation.
- Add telephone history tracking into `DayEndSummary` so evening tabloids can report: *"Mayor Seen Whispering on Encrypted Hotline"*.
