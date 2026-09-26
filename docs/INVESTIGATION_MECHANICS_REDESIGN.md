# Municipal Investigation Mechanics Redesign: Beyond Brute-Force Clicking
**Project:** *Yes, Mr. Mayor!* (`yes-mr-mayor`)  
**Document Target:** Gameplay Loop Analysis, Investigation Redesign, and Fun Maximization  
**Status:** Approved Architectural & Game Design Specification  

---

## 1. The Core Critique: Why Spam-Clicking Breaks the Game

### 1.1 The Current Problem
In the current implementation of `DeskView.gd`:
```gdscript
func _evaluate_discrepancy(token_a: String, token_b: String) -> void:
    var match_viol: Dictionary = GameManager.active_event.find_matching_violation(token_a, token_b)
    if not match_viol.is_empty():
        # Discrepancy Found!
        active_document.mark_violation_found(match_viol)
    else:
        # No Contradiction
        AudioManager.play_discrepancy_fail()
        inspect_status_label.text = "✗ " + tr("UI_NO_DISCREPANCY")
```
When a player clicks two unrelated fields (e.g., `app_budget` and `rule_zoning_river`), the game simply plays a dull buzz SFX and prints `"✗ No Discrepancy"`. There is:
- **Zero resource cost** (no time lost, no stamina spent, no budget fee).
- **Zero penalty or risk** (no suspicion increase, no public opinion hit, no error strikes).
- **Zero friction** (the player can click pairs as fast as their mouse allows).

### 1.2 The Resulting Gameplay Pathology
Because there is no downside to failing, the mathematically optimal player behavior is **pure brute-force combinatorial spamming**:
1. Click `app_applicant` ➔ Click every rulebook box.
2. Click `app_floors` ➔ Click every rulebook box.
3. Click `rep_hazard` ➔ Click every rulebook box.
4. If no green match triggers, stamp **APPROVED**. If a match triggers, stamp **REJECTED WITH CAUSE**.

This completely short-circuits the core fantasy of *Papers, Please* and *Yes, Minister*:
- Players **stop reading** the satirical applicant descriptions.
- Players **stop studying** the municipal zoning laws and authentic seal guides.
- The tension of detecting a clever fraud dissolves into mindless clicking.

---

## 2. Design Vision: What Makes Bureaucratic Investigation Fun?

To make municipal investigations thrilling, memorable, and satisfying, every investigation mechanic should adhere to three core principles:

1. **Decisions Must Cost Something:** Cross-referencing documents should consume a limited resource (Time, Coffee/Stamina, or Bureaucratic Political Capital). Players must read with their eyes *before* committing an investigation action with their mouse.
2. **Tactile & Diegetic Tools:** Players shouldn't just click abstract text boxes. They should manipulate physical desk props—a magnifying glass for micro-print seals, a UV blacklight for altered ink, an office ledger calculator, or the red desk telephone to interrogate inspectors.
3. **Double-Edged Stakes:** Making an unfounded accusation against an innocent citizen or prestigious corporation should backfire (lawsuits, lost approval, political embarrassment), while catching a corrupt mogul with ironclad proof should feel triumphant.

---

## 3. Concrete Mechanic Proposals for Gameplay Diversification

We propose 6 modular, high-impact systems that transform the desk from a static form into an interactive bureaucratic playground.

```
                           ┌──────────────────────────────┐
                           │    THE MAYOR'S DESK CANVAS   │
                           └──────────────┬───────────────┘
                                          │
        ┌─────────────────────────────────┼────────────────────────────────┐
        ▼                                 ▼                                ▼
┌──────────────────┐            ┌──────────────────┐             ┌──────────────────┐
│ LIMITS & PACING  │            │  TACTILE TOOLS   │             │ STAKES & TWISTS  │
├──────────────────┤            ├──────────────────┤             ├──────────────────┤
│ • Coffee/AP Bar  │            │ • Magnifying UV  │             │ • False Accuse   │
│ • 9-5 Desk Clock │            │ • Red Phone Wire │             │ • Sting Bribes   │
│ • Audit Warrants │            │ • Ledger Calc    │             │ • Daily Mandates │
└──────────────────┘            └──────────────────┘             └──────────────────┘
```

---

### System 1: The "Coffee & Cigarette" Stamina Limit (Action Points)

#### Concept
The Mayor is an exhausted, overworked bureaucrat operating on caffeine and nicotine. Each dossier grants a finite amount of **Mental Focus / Audit Points (AP)** (e.g., 3 to 4 Focus Points per document).

#### Gameplay Loop
- Inspecting a pair of tokens costs **1 Focus Point**.
- If the player finds a legitimate violation on their first or second try, they are rewarded with bonus satisfaction and conserved focus.
- If the player exhausts all Focus Points without finding a violation, the Mayor suffers "Bureaucratic Fatigue":
  - The Mayor's hand shakes slightly (subtle visual feedback).
  - Inspect mode is locked for the remainder of that document.
  - The player must make an intuitive gut-call: *Do they approve, reject on suspicion alone, or pocket the bribe?*

#### Diegetic Desk Prop: The Lukewarm Espresso Cup
- On the right side of the blotter sits a ceramic coffee cup with a steaming espresso.
- Each failed inspection drains a sip (3 sips total).
- **Risk/Reward Mechanic:** If out of AP, the player can click the coffee machine or call the assistant to *"Order Double Espresso"*:
  - **Cost:** Costs $500 from the City Budget (diverting municipal funds) OR pocketed personal cash.
  - **Tradeoff:** Restores 2 AP, but raises Federal Suspicion by +1.5% if auditors notice lavish personal expenses!

---

### System 2: Shift Clock & Time Pressure (The 9-to-5 Municipal Clock)

#### Concept
Introduce a ticking retro office wall/desk clock. Each working day runs from **09:00 AM to 05:00 PM** (8 municipal hours).

#### Gameplay Loop
- Reading and viewing documents is free.
- Activating a cross-reference inspection consumes **15 in-game minutes**.
- Ordering an official technical survey or dialing the telephone costs **30 in-game minutes**.
- If 05:00 PM hits before the daily quota of 4 dossiers is cleared:
  - **Overtime Penalty:** Unprocessed petitions result in administrative backlog fines ($5,000/doc) and citizen protests (-5% Approval per delayed project).
  - Or, the player is forced to **Rush-Sign (Blind Stamp)** remaining petitions with their eyes closed to make the evening press deadline!

#### Why It Increases Fun:
Time pressure creates genuine tension. Players can no longer take 10 minutes per document comparing every microscopic pixel—they must prioritize obvious red flags and make tough triage decisions under the ticking clock.

---

### System 3: "Auditor Incompetence" & False Accusation Penalties

#### Concept
In the real world, a mayor cannot baselessly accuse legitimate contractors of criminal fraud without severe political and legal blowback.

#### Mechanics:
- When a player pairs two tokens that have no violation, instead of a silent error, it registers as a **"Frivolous Inquiry"**.
- **First mistake:** A warning from your City Legal Counsel: *"Mr. Mayor, that claim will never hold up in administrative court."*
- **Second mistake on same docket:** 
  - **Public Opinion:** -3.0% (News leaks: *"Mayor Harasses Legitimate Business Owners With Baseless Audits!"*)
  - **Federal Suspicion:** +2.0% (Auditors think the Mayor is either incompetent or deliberately stalling clean infrastructure projects).
- **Sound & Visual Feedback:** A sharp paper rip sound, a buzzer, and the applicant's signature stamp shaking in irritation.

---

### System 4: Tactile Investigation Tools (Physical Desk Items)

Instead of a generic single "Inspect" button that checks everything uniformly, introduce distinct desk tools with specific investigative purposes:

| Tool | Visual Appearance | Investigative Function | Gameplay Experience |
| :--- | :--- | :--- | :--- |
| **Brass Magnifying Glass** | Vintage optical lens on desk blotter | Dragged over the **Ministry Seal** or **Permit Date** to reveal microscopic flaws: <br>• Authentic eagle watermarks vs. fake pigeons.<br>• Tiny forged serial numbers. | Engaging visual mini-game. Players actually look at the art rather than clicking tags. |
| **UV Blacklight Wand** | Compact tactical UV flashlight | Click to illuminate the document in glowing violet light. Reveals:<br>• Erased or altered numbers (e.g. 4 floors altered to 24).<br>• Secret chemical stains or invisible ink messages from corrupt officials. | Transforms the document into an atmospheric mystery prop. |
| **Desk Telephone Hotlines** | Heavy red rotary phone on desk | Dial 3 numbers:<br>• **Ext. 1 (Building Inspector):** Ask if the soil test was verified ($1,000 fee).<br>• **Ext. 2 (Police Intelligence):** Check if company is on the secret cartel watch list.<br>• **Ext. 3 (Party Whip):** Ask if the Party wants this project passed regardless of legality. | Introduces political maneuvering and dialogue choices into the deduction phase. |
| **Municipal Ledger & Calculator** | Wooden abacus or vintage adding machine | Click to auto-verify if: <br>`Budget Stated` minus `Tax Debt` covers estimated building cost. If balance is negative, triggers a **Financial Incompetence Violation**. | Rewards players who pay attention to numerical data. |

---

### System 5: Bribe Deduction & Federal Sting Operations

#### The Problem with Current Bribes:
Currently, bribes are simply free money deposited into the offshore safe with a flat +3% suspicion. Players always take the bribe unless their suspicion is near 100%.

#### The Redesign: Bribes as Interactive Deductions
1. **Federal Sting Operations (Marked Cash):**
   - Certain corrupt envelopes are actually planted by undercover federal task forces!
   - If the player uses the **UV Blacklight** on the bribe envelope before pocketing it, they can spot fluorescent FBI dye or recorded serial numbers.
   - If pocketed without checking: Immediate +25% Federal Suspicion and an urgent phone call from your panicked lawyer!
2. **Blackmail Envelopes:**
   - Some envelopes don't just contain cash—they contain a compromising photograph of the Mayor with a note: *"Approve this industrial zoning by 5 PM, or this goes to the morning tabloid."*
   - Players must decide whether to comply, destroy the photo in the paper shredder, or call the police commissioner to arrest the blackmailer.
3. **The Kickback Counter-Offer:**
   - The Mayor can stamp a **"Tariff / Surcharge Stamp"** onto the bribe: demanding double the cash in exchange for overlooking critical violations, at the cost of doubling suspicion risk.

---

### System 6: Shifting Daily Directives & Morning Briefings

To prevent Day 15 from feeling identical to Day 1, each morning should introduce a **Daily Municipal Directive** published in the morning gazette:

- **Day 3 (Environmental Audit Week):** The Federal EPA is visiting. Catching environmental or riverbed violations grants **double public approval** (+30%), but approving an environmental violation triggers an instant **Federal Inquiry**.
- **Day 8 (Budget Crisis Day):** The city treasury is dry. Rejecting expensive public works does not incur approval penalties, but collecting tax arrears grants bonus revenue.
- **Day 14 (Anti-Corruption Crackdown):** A federal prosecutor is stationed directly in City Hall. Bribe pocketing is disabled, or carries 3x suspicion.
- **Day 22 (Election Sprint):** Public opinion changes are doubled; citizens are hyper-sensitive to every decision.

---

## 4. Prioritized Implementation Roadmap

To avoid overwhelming development, these enhancements are categorized into three agile implementation milestones:

### Milestone 1: Low Effort, High Impact (Quick Wins)
- [x] **Deduction Limits:** Implement 4-point Focus/AP per document in `DeskView.gd`.
- [x] **False Accusation Penalty:** Add minor Public Opinion (-2%) and Suspicion (+2%) penalties when 3 consecutive false token comparisons occur.
- [x] **Visual Focus Counter:** Display 3 coffee cup / stamp icons next to the Inspect Mode toggle.

### Milestone 2: Tactile Immersion (Core Polish)
- [x] **Shift Time Clock:** Add an 09:00–17:00 desk clock where each inspection consumes 15 minutes.
- [x] **UV Blacklight Tool:** Implement a toggleable shader/overlay revealing hidden watermarks on forged seals and dirty bribe envelopes.
- [x] **Red Phone Inquiries:** Allow the player to click the Red Telephone to spend $1,000 and reveal 1 guaranteed violation.

### Milestone 3: Deep Meta & Narrative Twists (Full Replayability)
- [ ] **Federal Sting Bribes:** Trapped envelopes with UV-detectable ink.
- [ ] **Daily Executive Directives:** Morning modifier cards that alter rules for that day's shift.
- [ ] **Twitch Chat "Inspector Vote":** Allow livestream viewers to spend channel points or vote on which desk tool the Mayor should use.

---

## 5. Architectural Implementation Sample: Adding Focus AP to `DeskView.gd`

Here is the clean, non-breaking architectural pattern to integrate the Focus/AP limit directly into the existing Godot codebase:

```gdscript
# Add to scripts/desk/DeskView.gd
const MAX_INSPECT_FOCUS: int = 4
var current_inspect_focus: int = MAX_INSPECT_FOCUS
var consecutive_false_inquiries: int = 0

func _present_next_document() -> void:
    # Reset focus for new dossier
    current_inspect_focus = MAX_INSPECT_FOCUS
    consecutive_false_inquiries = 0
    _update_focus_ui()
    # ... existing setup code ...

func _evaluate_discrepancy(token_a: String, token_b: String) -> void:
    if current_inspect_focus <= 0:
        AudioManager.play_discrepancy_fail()
        inspect_status_label.text = "⚠️ " + tr("UI_INSPECT_FATIGUED")
        return

    current_inspect_focus -= 1
    _update_focus_ui()

    var match_viol: Dictionary = GameManager.active_event.find_matching_violation(token_a, token_b)
    if not match_viol.is_empty():
        # Match found! Reset false inquiries
        consecutive_false_inquiries = 0
        AudioManager.play_discrepancy_match()
        active_document.mark_violation_found(match_viol)
    else:
        consecutive_false_inquiries += 1
        AudioManager.play_discrepancy_fail()
        
        # Penalize excessive false accusations
        if consecutive_false_inquiries >= 2:
            GameManager.apply_resolution({
                "public_opinion": -2.0,
                "suspicion": 1.5
            })
            inspect_status_label.text = "❌ " + tr("UI_FALSE_ACCUSATION_PENALTY")
```

---

## 6. Summary: The Transformed Player Experience

With these systems in place:
1. **No More Mindless Spam:** Players inspect with deliberate intent because every click spends Focus AP or office time.
2. **Deep Satisfaction:** Uncovering a forged seal with the UV blacklight or catching an unlisted shell corporation with a telephone tip feels like genuine detective work.
3. **Rich Satirical Theme:** The mechanics reinforce the narrative of a weary, morally conflicted mayor balancing greedy oligarchs, angry voters, and federal investigators.
