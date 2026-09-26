# Offshore Safe & Illicit Funds Spending System (Money Sinks)
**Project:** *Yes, Mr. Mayor!* (`yes-mr-mayor`)  
**Document Target:** Feature Specification & Phased Engineering Plan  
**Module:** `scripts/desk/DeskView.gd` (Safe Drawer) & `scripts/autoload/GameManager.gd`  
**Status:** Approved Architectural Specification  

---

## 1. Problem Statement: The "Useless Money" Flaw
In the current version:
1. When players pocket a bribe, funds accumulate in `GameManager.personal_wealth` (the Offshore Safe).
2. Pocketing cash incurs a permanent **+3% to +15% Federal Suspicion** risk.
3. **However, personal wealth cannot be spent on anything during the actual gameplay.** It merely exists as a final numeric score on the Game Over screen (`stash_label`).

Because dirty money cannot solve problems, players quickly learn that taking bribes is almost purely a self-sabotage mechanic. To make corruption enticing, dangerous, and strategically rewarding, **illicit wealth must be spendable on powerful, morally bankrupt solutions**.

---

## 2. The 4 Core Money Sinks

Clicking the **Offshore Safe Drawer** on the bottom-right of the desk should slide open the safe, revealing the Mayor's secret ledger with 4 actionable spending channels:

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                      MAYOR'S PRIVATE OFFSHORE LEDGER                          │
│                      Stashed Balance: $145,000                                │
├───────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  [1. RETAIN ELITE DEFENSE FIXER]                      Cost: $40,000           │
│  "Shred subpoena documents and stall federal auditors."                       │
│  Effect: -25.0% Federal Suspicion                               [PURCHASE]    │
│                                                                               │
│  [2. ASTROTURF TABLOID PR CAMPAIGN]                   Cost: $30,000           │
│  "Bribe newspaper editors to run flattering photo-ops of the Mayor."          │
│  Effect: +18.0% Public Opinion                                  [PURCHASE]    │
│                                                                               │
│  [3. PURCHASE AUDIT IMMUNITY LEAK]                    Cost: $60,000           │
│  "Buy secret leaked list of upcoming ministry inspection targets."            │
│  Effect: Next 3 violating documents have their violations revealed! [PURCHASE]│
│                                                                               │
│  [4. MAYORAL DESK LUXURY ASSETS]                      Cost: $25,000 - $75,000 │
│  "Buy vanity assets: Solid Gold Stamp, Imported Cuban Cigar Box, Yacht Keys." │
│  Effect: Unlocks permanent cosmetic desk flair & ending bonus   [BROWSE]      │
│                                                                               │
└───────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Detailed Mechanic Specifications

### 3.1 Channel 1: The "Fixer" (Suspicion Eraser)
* **Cost:** $35,000 – $50,000 (Scales up as current day advances).
* **Mechanic:** The Mayor calls Attorney Arthur Sterling. Confidential legal filings challenge federal auditor jurisdiction.
* **Impact:** Lowers Federal Suspicion by 20% to 30%.
* **Gameplay Value:** Enables high-stakes "dirty playstyles" where players aggressively pocket $80,000 bribes, then launder half of it to evade prison.

### 3.2 Channel 2: Media Astroturfing (Approval Booster)
* **Cost:** $25,000 – $40,000.
* **Mechanic:** Secret cash envelopes delivered to chief tabloid editors and TV news anchors.
* **Impact:** Lowers public anger by +15% to +22% without spending city tax dollars.
* **Dilemma:** If Federal Suspicion is above 75%, there is a 20% chance the bribe leaks, triggering an immediate headline scandal: *"Mayor Caught Bribing Press With Illicit Slush Funds!"*

### 3.3 Channel 3: Buying Secret Department Intel
* **Cost:** $50,000.
* **Mechanic:** Buy inside information from a corrupt Ministry archivist.
* **Impact:** For the next 3 days, any forged seal or counterfeit permit glows with a discreet yellow highlighter when opened.

### 3.4 Channel 4: Vanity Desk Assets (Cosmetic Prestige)
Purchasing vanity assets permanently modifies the Mayor's desk visually:
* **The Solid 24K Gold Stamp ($50,000):** Replaces the wooden rubber stamp with a gleaming golden stamp and heavy metallic clang SFX.
* **Hand-Rolled Havana Cigar Box ($15,000):** Sits beside the telephone with a gentle wisp of rising smoke.
* **Monaco Yacht Brochure ($25,000):** Lies under the rulebook, teasing the "Tax Exile" secret ending.

---

## 4. Phased Implementation Plan

### Phase 1: Safe Drawer Modal & Data Binding
- Create `scenes/ui/OffshoreLedgerModal.tscn` and `scripts/ui/OffshoreLedgerModal.gd`.
- Connect `safe_drawer_panel.gui_input` in [`DeskView.gd`](file:///c:/Users/User/Documents/yes-mr-mayor/scripts/desk/DeskView.gd) to open the ledger modal with a smooth slide-up animation.
- Display current balance formatted via `GameManager.offshore_account`.

### Phase 2: Transaction Handlers & Dynamic Cost Scaling
- Implement purchase handlers:
  * `_on_buy_fixer_pressed()`: Decrements wealth, drops suspicion, plays paper shredder audio.
  * `_on_buy_pr_pressed()`: Decrements wealth, boosts approval, triggers camera flash SFX.
- Scale costs dynamically: As `current_day` increases, lawyers demand higher fees ($30k in Week 1 ➔ $65k in Week 4).

### Phase 3: Visual Desk Flair & Secret Corrupt Endings
- Add visual desk props instantiated when luxury items are purchased.
- Add 2 new game-over / victory endings to `GameManager.gd`:
  * `END_FLED_TO_CAYMANS`: Survived Day 30 with >$250,000 in personal wealth; mayor flees on a private jet before indictment.
  * `END_BRIBE_LEAK_SCANDAL`: Got caught attempting to bribe the press while suspicion was too high.
