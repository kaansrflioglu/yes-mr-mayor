# Feature Prompt Specification: Expanded Narrative Endings & Mayoral Report Card

## Feature Summary & Vision
Currently, the endgame evaluation in `GameManager._evaluate_end_conditions()` and `GameOverModal.gd` checks only raw threshold cutoffs, producing generic outcomes. A 30-day political satire deserves an unforgettable, personalized post-mortem that reflects every moral compromise, backroom deal, and civic triumph the player engineered.

This feature expands the game to **12 Diverse Narrative Endings** and introduces the **Mayoral Report Card & 10-Year Epilogue**. Players receive an official civic performance grade (S through F), an indelible historical title bestowed by city historians, a list of unlocked historical deeds, and a narrative summary detailing what becomes of the city a decade after their tenure.

---

## The 12 Narrative Endings Matrix

| Ending Key | Title | Unlock Requirements | Narrative Epitaph |
| :--- | :--- | :--- | :--- |
| `END_SAINT` | **The Saint of the Slums** | Day 30, Opinion ≥ 85%, Personal Wealth == 0, Suspicion ≤ 10% | A bronze monument is erected in the central park. You leave office broke, but immortalized as the cleanest mayor in history. |
| `END_TEFLON_DON` | **The Teflon Mastermind** | Day 30, Wealth ≥ $200k, Opinion ≥ 70%, Suspicion ≤ 25% | Re-elected by a landslide while secretly running the largest offshore shell empire in municipal history. Untouchable. |
| `END_CORPORATE_PUPPET` | **Megacorp Chief Administrator** | Day 30, Approved 80%+ Megacorp petitions, Oligarch Faction ≥ 85% | City Hall is renamed Megacorp Municipal Headquarters. Citizens pay monthly subscription fees for clean tap water and sidewalk access. |
| `END_MOB_VICEROY` | **Consigliere of the Council** | Day 30, Accepted 80%+ Mafia hotline calls, Police Unrest high | The Syndicate openly runs city hall. You remain in office, guarded by dark-suited men with violin cases. |
| `END_ECO_UTOPIA` | **The Emerald Metropolis** | Day 30, Green Faction ≥ 85%, 0 toxic chimney flags, Floodways intact | The city becomes a world-renowned green oasis of elevated monorails and clean solar canals. |
| `END_AUSTERE_ACCOUNTANT`| **The Cold Technocrat** | Day 30, Budget ≥ $300,000, Opinion between 45% and 60% | The municipal treasury is bursting with cash, but the city has no nightlife, cultural events, or public joy. Voted out for sheer boredom. |
| `END_CAYMAN_EXILE` | **The Caribbean Corsair** | Day 30, Wealth ≥ $250,000 | You slip into a helicopter from City Hall's roof. Tomorrow's headlines report your disappearance to a private Caribbean atoll. |
| `END_FEDERAL_SUPERMAX` | **Inmate #4902-B** | Suspicion ≥ 100% or Sting Trap Caught | Handcuffs click on your wrists during a live press conference. 25 years without parole in federal penitentiary. |
| `END_REVOLUTION_STORM` | **Guillotine on the Plaza** | Opinion ≤ 15% | Rioters storm City Hall with torches. You barely escape through an underground sewage pipe in a sanitation worker uniform. |
| `END_MUNICIPAL_BANKRUPT`| **The Receivership Fire-Sale**| City Budget < -$50,000 | The state government declares emergency fiscal insolvency. City assets are auctioned off on eBay. |
| `END_ONE_TERM_MEDIOCRE` | **The Forgotten Interim** | Day 30, Opinion < 50%, Wealth < $100k | You pack your cardboard box in silence. Your name is misspelled in the municipal archive records. |
| `END_SHADOW_JUNTA` | **The Emergency Autocrat** | Suspicion ≥ 85%, Police Faction ≥ 90%, Curfew enacted | You suspend City Council elections under emergency decree. The sirens never stop blaring, but nobody dares challenge you. |

---

## The Mayoral Report Card (`MayoralReportCardModal.tscn`)

### 1. Visual Presentation
- Styled as an official **Archival Dossier / Leather-bound City Historian Review**.
- Displays:
  * **Historic Title Badge** (e.g., *"The Silver-Tongued Demagogue"*, *"The Honest Pauper"*, *"The Concrete Baron"*).
  * **Administrative Grade**: `S` (Godlike), `A` (Exceptional), `B` (Competent), `C` (Corrupt but Effective), `D` (Disaster), `F` (Impeached/Jailed).
  * **District Prosperity Breakdown**: Radial or bar breakdown of how each district evolved over the 30-day mandate.
  * **10-Year City Epilogue**: 3 procedural paragraphs explaining the long-term historical legacy of your choices (e.g. what happened to the riverbed, whether the monorail stayed running, what the newspapers say about you 10 years later).

---

## Architecture & File Additions

### New Files to Create:
1. `scripts/autoload/EndingsManager.gd`: Evaluates full game telemetry (factions, wealth, opinion, flags, event choices) to determine the exact ending and calculate the letter grade.
2. `scenes/summary/MayoralReportCardModal.tscn`: Archival scorecard UI scene with wax seal, grade stamp, and historical chronicle.
3. `scripts/ui/MayoralReportCardModal.gd`: Controller driving grade reveal animations, statistic counting, and epilogue text generation.

### Files to Modify:
1. `scripts/autoload/GameManager.gd`:
   - Replace simple `_evaluate_end_conditions()` branching with `EndingsManager.evaluate_mandate()`.
2. `scripts/desk/DeskView.gd`:
   - Route game conclusion to `MayoralReportCardModal`.
3. `data/localization.csv`:
   - Add narrative chronicles and epilogue paragraphs for all 12 endings in EN, TR, and ES.

---

## Step-by-Step Implementation Instructions

### Step 1: Create `EndingsManager.gd`
```gdscript
extends Node

func evaluate_mandate() -> Dictionary:
    var wealth: int = GameManager.personal_wealth
    var opinion: float = GameManager.public_opinion
    var susp: float = GameManager.suspicion_level
    var budget: int = GameManager.city_budget
    var flags: Dictionary = GameManager.event_flags
    var day: int = GameManager.current_day
    
    var end_key: String = ""
    var letter_grade: String = "C"
    var title_key: String = ""
    
    # 1. Sudden Failure Endings
    if susp >= 100.0:
        end_key = "END_FEDERAL_SUPERMAX"
        letter_grade = "F"
        title_key = "TITLE_CONVICTED_FELON"
    elif opinion <= 15.0:
        end_key = "END_REVOLUTION_STORM"
        letter_grade = "F"
        title_key = "TITLE_OUSTED_TYRANT"
    elif budget < -50000:
        end_key = "END_MUNICIPAL_BANKRUPT"
        letter_grade = "D"
        title_key = "TITLE_BANKRUPT_SPENDTHRIFT"
    elif day >= GameManager.MAX_DAYS:
        # 2. Full 30-Day Mandate Endings
        if opinion >= 85.0 and wealth == 0 and susp <= 15.0:
            end_key = "END_SAINT"
            letter_grade = "S"
            title_key = "TITLE_CIVIC_SAINT"
        elif wealth >= 250000 and opinion >= 65.0 and susp <= 30.0:
            end_key = "END_TEFLON_DON"
            letter_grade = "S"
            title_key = "TITLE_TEFLON_MASTERMIND"
        elif wealth >= 250000:
            end_key = "END_CAYMAN_EXILE"
            letter_grade = "B"
            title_key = "TITLE_OFFSHORE_CORSAIR"
        elif budget >= 250000 and opinion >= 50.0:
            end_key = "END_AUSTERE_ACCOUNTANT"
            letter_grade = "B"
            title_key = "TITLE_AUSTERE_TECHNOCRAT"
        elif flags.get("FLAG_ALLIED_MAFIA", false) and wealth >= 100000:
            end_key = "END_MOB_VICEROY"
            letter_grade = "C"
            title_key = "TITLE_SHADOW_CONSIGLIERE"
        elif opinion >= 50.0:
            end_key = "END_REELECTED"
            letter_grade = "A"
            title_key = "TITLE_PEOPLES_MAYOR"
        else:
            end_key = "END_ONE_TERM_MEDIOCRE"
            letter_grade = "D"
            title_key = "TITLE_FORGOTTEN_MAYOR"
            
    return {
        "end_key": end_key,
        "letter_grade": letter_grade,
        "title_key": title_key,
        "epilogue_text": _generate_epilogue(end_key, flags)
    }

func _generate_epilogue(end_key: String, _flags: Dictionary) -> String:
    return tr(end_key + "_EPILOGUE")
```

---

## Verification & Automated Test Plan
Create test script `tests/test_narrative_endings.gd`:
1. **Civic Saint Evaluation**: Set `current_day = 30`, `opinion = 90.0`, `wealth = 0`, `suspicion = 5.0`. Call `evaluate_mandate()`. Assert `end_key == "END_SAINT"` and `letter_grade == "S"`.
2. **Teflon Mastermind Evaluation**: Set `current_day = 30`, `wealth = 260,000`, `opinion = 72.0`, `suspicion = 20.0`. Assert `end_key == "END_TEFLON_DON"`.
3. **Report Card UI Display**: Instantiate `MayoralReportCardModal`. Populate with evaluation dictionary. Assert letter grade stamp and title label are populated properly.
