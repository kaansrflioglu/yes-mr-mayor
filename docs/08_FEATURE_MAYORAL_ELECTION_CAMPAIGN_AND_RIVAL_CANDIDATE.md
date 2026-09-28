# Feature Prompt Specification: Mayoral Election Campaign & Rival Candidate Sprint (Days 23-30)

## Feature Summary & Vision
In the existing codebase, the campaign ending on Day 30 is decided by a simple binary threshold: `if public_opinion >= 50.0: reelected else: lost_election`. This makes the culmination of a 30-day term feel anti-climactic.

This feature transforms Days 23 through 30 into a frantic **Election Campaign Sprint**. The player faces a charismatic **Rival Candidate**, tracks a live **Polling Percentage Tracker** across the 5 city districts, spars in a high-stakes **Live TV Debate** on Day 27, and watches dramatic district-by-district ballot counting on Election Night.

---

## Gameplay Mechanics

### 1. Dynamic Rival Candidate Generation
On Day 23, the city election board certifies the Mayor's main challenger based on player playstyle:
- **If Suspicion > 40% or Wealth > $100k**: 
  - **Councilwoman Vera Sterling (The Crusading Reformer)**.
  - Slogan: *"Clean Up City Hall!"*
  - Attack angle: Leaks player's past bribes, audits questionable building variances.
- **If Opinion < 50% or Budget < $50k**: 
  - **Victor "Big Vic" Moreno (The Populist Tycoon)**.
  - Slogan: *"Jobs, Growth, and Prosperity for All!"*
  - Attack angle: Promises massive commercial development, tax cuts, and entertainment megaplexes.

### 2. Live Polling Tracker & District Battlegrounds
- On Day 23, the HUD adds a dynamic **Campaign Polling Bar** (`Incumbent % vs Rival %`).
- Every approved/rejected petition shifts votes in specific districts:
  * Pro-Labor decisions capture working-class `DIST_RIVERBED` and `DIST_SUBURBS`.
  * High-end commercial developments swing wealthy `DIST_CENTRAL`.
  * Preserving historic sites swings cultural `DIST_HISTORIC`.

### 3. Day 27 Live Television Debate
- On Day 27, the standard shift concludes with a televised debate against the rival candidate:
  * 3 debate rounds: Economy, Ethics & Corruption, Future of the City.
  * Rapid rebuttal choices: Rebut rival claims with official facts, smear rival campaign funding, or appeal directly to emotional voter loyalty.
  * Winning the debate swings 10% to 15% of undecided voters.

### 4. Election Night Ballot Count (Day 30 Climax)
- Replaces standard game-over screen with an animated **Election Night Results Board**:
  * District returns count up vote tallies sequentially.
  * Tension builds as swings determine whether the administration earns "4 More Years" or gets unseated.

---

## Architecture & File Additions

### New Files to Create:
1. `scripts/autoload/ElectionManager.gd`: Autoload managing rival candidate data, voter polling percentages, debate logic, and ballot counting.
2. `scenes/hud/CampaignTrackerHUD.tscn`: UI overlay displaying current polling percentages and countdown to Election Day.
3. `scenes/summary/ElectionNightModal.tscn`: Climax modal with district ballot animations and celebratory/somber outcome fanfare.

### Files to Modify:
1. `scripts/autoload/GameManager.gd`:
   - Extend `_evaluate_end_conditions()` to route Day 30 to `ElectionNightModal` instead of an immediate static modal.
2. `scripts/autoload/DirectiveManager.gd`:
   - Enhance `DIR_ELECTION_SPRINT` to double opinion gains and losses during Days 23-30.
3. `scripts/ui/TopBarHUD.gd`:
   - Display `CampaignTrackerHUD` when `GameManager.current_day >= 23`.
4. `data/localization.csv`:
   - Add localization strings for rival candidate dialogues, debate prompts, and election night broadcasts.

---

## Step-by-Step Implementation Instructions

### Step 1: Create `ElectionManager.gd`
```gdscript
extends Node

signal polling_updated(incumbent_pct: float, rival_pct: float)
signal election_concluded(victory: bool, final_incumbent_pct: float)

var is_campaign_active: bool = false
var rival_id: String = "reformer" # "reformer" or "populist"
var incumbent_poll: float = 48.0
var rival_poll: float = 52.0

var district_polls: Dictionary = {
    "DIST_CENTRAL": 50.0,
    "DIST_RIVERBED": 45.0,
    "DIST_INDUSTRIAL": 52.0,
    "DIST_HISTORIC": 46.0,
    "DIST_SUBURBS": 49.0
}

func activate_campaign(day: int) -> void:
    if day >= 23 and not is_campaign_active:
        is_campaign_active = true
        # Pick rival based on player corruption
        if GameManager.suspicion_level > 40.0 or GameManager.personal_wealth > 80000:
            rival_id = "reformer"
        else:
            rival_id = "populist"
        _recalculate_aggregate_poll()

func update_district_vote(district_id: String, delta: float) -> void:
    if district_polls.has(district_id):
        district_polls[district_id] = clampf(district_polls[district_id] + delta, 10.0, 90.0)
        _recalculate_aggregate_poll()

func _recalculate_aggregate_poll() -> void:
    var sum: float = 0.0
    for d in district_polls:
        sum += district_polls[d]
    incumbent_poll = sum / float(district_polls.size())
    rival_poll = 100.0 - incumbent_poll
    polling_updated.emit(incumbent_poll, rival_poll)

func run_election_tally() -> bool:
    var won_districts: int = 0
    for d in district_polls:
        if district_polls[d] >= 50.0:
            won_districts += 1
            
    var victory: bool = (won_districts >= 3)
    election_concluded.emit(victory, incumbent_poll)
    return victory
```

---

## Verification & Automated Test Plan
Create test script `tests/test_election_campaign.gd`:
1. **Campaign Trigger on Day 23**: Advance to Day 23. Assert `ElectionManager.is_campaign_active == true` and rival is selected.
2. **Polling Swing on Permit Decision**: Resolve an event in `DIST_HISTORIC`. Verify `district_polls["DIST_HISTORIC"]` updates and triggers `polling_updated`.
3. **Ballot Counting Climax**: Test `run_election_tally()`. Verify that winning 3 of 5 districts awards reelection victory.
