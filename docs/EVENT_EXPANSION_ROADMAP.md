# 180-Event Expansion Roadmap & AI Prompt Specification (8-Phase Master Plan)
**Project:** *Yes, Mr. Mayor!* (`yes-mr-mayor`)  
**Document Target:** Narrative Scaling, 8-Phase Content Expansion, Branching Event Chains & Prompt Engineering  
**Target Event Volume:** 168 New Events (`EVT_013` through `EVT_180`) ➔ **Total: 180 Events**  
**Status:** **100% COMPLETED & QA-VERIFIED (EVT_001 – EVT_180 Integrated)**  
**Game Pacing:** Tiered Progression (Days 1–10 Early, Days 11–20 Mid, Days 21–30 Climax)  
**Language Standards:** Strict i18n JSON + CSV (`en`, `tr`, `es`)  


---

## 1. Executive Summary & Scaling Strategy

### 1.1 The Math: Why 180 Events?
* **Mandate Length:** 30 in-game days (`MAX_DAYS = 30`).
* **Daily Quota:** 4 dossiers per day (`DEFAULT_DAILY_QUOTA = 4`).
* **Single Playthrough Consumption:** $30 \times 4 = \mathbf{120\text{ unique events}}$.

A 100-event expansion (112 total) would run out before Day 29 of a single playthrough. Expanding the library to **180 events** achieves two vital goals:
1. **Zero Repeats in a Full 30-Day Run:** The player experiences a completely fresh, unrepeated narrative from inauguration to election night (120 events seen, 60 unseen).
2. **High Replay Value:** Starting a 2nd or 3rd mandate presents **over 50% brand-new events**, branching choices, and alternative endings.

### 1.2 The 8-Phase Structure Overview

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│                           180-EVENT MUNICIPAL PIPELINE                            │
└────────────────────────────────────────┬──────────────────────────────────────────┘
                                         │
     ┌───────────────────────────────────┼───────────────────────────────────┐
     ▼                                   ▼                                   ▼
┌─────────────────────────┐ ┌─────────────────────────┐ ┌─────────────────────────┐
│  TIER 1: EARLY MANDATE  │ │   TIER 2: MID-TERM OIL  │ │   TIER 3: ENDGAME RUN   │
│       (Days 1 - 10)     │ │      (Days 11 - 20)     │ │      (Days 21 - 30)     │
├─────────────────────────┤ ├─────────────────────────┤ ├─────────────────────────┤
│ • Phase 1: Real Estate  │ │ • Phase 4: Mafia/Cartels│ │ • Phase 6: Crises/Disast│
│ • Phase 2: Transit/Infra│ │ • Phase 5: Absurd Satire│ │ • Phase 7: Event Chains │
│ • Phase 3: Public Unions│ │                         │ │ • Phase 8: Federal Audit│
│ (66 Events: EVT_013-078)│ │ (44 Events: EVT_079-122)│ │ (58 Events: EVT_123-180)│
└─────────────────────────┘ └─────────────────────────┘ └─────────────────────────┘
```

---

## 2. Technical Data Architecture & Branching Schemas

To support event progression and branching consequences, events now support two optional metadata fields in `data/events.json`:
- `"day_range": [min_day, max_day]`: Restricts the event from appearing too early or too late.
- `"unlocks_event_id": "EVT_XXX"`: When approved (or rejected), unlocks a direct follow-up dilemma.

### 2.1 Complete Event Schema (`data/events.json`)

```json
{
  "id": "EVT_013",
  "category": "zoning",
  "day_range": [1, 15],
  "title_key": "EVT_013_TITLE",
  "description_key": "EVT_013_DESC",
  "applicant_key": "COMP_AURA_TOWERS",
  "bribe_offered": 60000,
  "application_data": {
    "applicant_name_key": "COMP_AURA_TOWERS",
    "project_title_key": "EVT_013_TITLE",
    "district_id": "DIST_HISTORIC",
    "floors": 12,
    "budget_stated": 1200000,
    "seal_id": "SEAL_MINISTRY_FAKE",
    "reg_code": "AT-2026-104",
    "expiry_date": "2026-11-30"
  },
  "report_data": {
    "inspector_name_key": "INSP_KAYA",
    "measured_floors": 12,
    "hazard_level": "HAZARD_STRUCTURAL_RISK",
    "tax_debt": 45000,
    "soil_status": "SOIL_GRADE_B",
    "notes_key": "EVT_013_INSP_NOTES"
  },
  "violations": [
    {
      "id": "VIOL_HEIGHT_LIMIT",
      "name_key": "VIOL_HEIGHT_LIMIT",
      "tags": ["app_floors", "rule_zoning_historic", "app_district"]
    },
    {
      "id": "VIOL_FORGED_SEAL",
      "name_key": "VIOL_FORGED_SEAL",
      "tags": ["app_seal", "rule_seal_guide"]
    },
    {
      "id": "VIOL_TAX_DEBT",
      "name_key": "VIOL_TAX_DEBT",
      "tags": ["rep_tax_debt", "rule_tax_guide"]
    }
  ],
  "effects_approve": {
    "budget": 30000,
    "personal_wealth": 60000,
    "public_opinion": -15.0,
    "suspicion": 20.0,
    "city_visual_flag": "add_luxury_tower",
    "unlocks_event_id": "EVT_143"
  },
  "effects_reject": {
    "budget": 0,
    "personal_wealth": 0,
    "public_opinion": 12.0,
    "suspicion": -8.0,
    "city_visual_flag": "preserve_historic_skyline",
    "unlocks_event_id": "EVT_144"
  },
  "news_headline_approve_key": "EVT_013_NEWS_APP",
  "news_headline_reject_key": "EVT_013_NEWS_REJ"
}
```

### 2.2 Inspectable Tag Registry

Every violation `tags` array must use valid tokens recognized by [`DocumentItem.gd`](file:///c:/Users/User/Documents/yes-mr-mayor/scripts/desk/DocumentItem.gd) and [`Rulebook.gd`](file:///c:/Users/User/Documents/yes-mr-mayor/scripts/desk/Rulebook.gd):

| Source Card | Valid Tag Tokens | Comparison Target |
| :--- | :--- | :--- |
| **Application Card** | `app_applicant` | `rule_blacklist_guide` |
| | `app_district` | `rule_zoning_historic`, `rule_zoning_river`, `rule_zoning_green`, `rule_zoning_central`, `rule_zoning_industrial` |
| | `app_floors` | `rep_measured_floors` (discrepancy) OR zoning height rules |
| | `app_budget` | Declared construction capital |
| | `app_seal` | `rule_seal_guide` (`SEAL_MINISTRY_FAKE`, `SEAL_CHAMBER_FAKE`) |
| | `app_expiry` | `rule_seal_guide` (`SEAL_EXPIRED`) |
| **Inspector Report** | `rep_inspector` | Assigned municipal inspector |
| | `rep_measured_floors`| Field measured height (cross-checks `app_floors`) |
| | `rep_hazard` | `rule_zoning_river` (`HAZARD_CRITICAL_FLOOD`), industrial hazards |
| | `rep_tax_debt` | `rule_tax_guide` (Arrears > $0 disqualify contracts) |
| | `rep_soil` | Geological stability (`SOIL_CRITICAL_UNSTABLE`, `SOIL_ALLUVIAL`) |

---

## 3. The 8-Phase Master Breakdown (180 Total Events)

| Phase | Thematic Arc | Event IDs | Count | Day Tier | Narrative Essence |
| :---: | :--- | :---: | :---: | :---: | :--- |
| **Phase 1** | **Urban Megaprojects & Real Estate Rackets** | `EVT_013` – `EVT_034` | 22 | Days 1–12 | Luxury high-rises, dry riverbed towers, historic demolitions, mall zoning. |
| **Phase 2** | **Transit Grabs, Utilities & Ecological Hazards** | `EVT_035` – `EVT_056` | 22 | Days 3–15 | Toxic waste bypasses, ghost subway lines, privatized toll highways, power monopolies. |
| **Phase 3** | **Labor Unions, Social Strife & Civic Welfare** | `EVT_057` – `EVT_078` | 22 | Days 5–18 | Sanitation strikes, teacher salaries, police riot gear, morgues, fire fleet funding. |
| **Phase 4** | **Underground Economy, Cartels & Money Laundering** | `EVT_079` – `EVT_100` | 22 | Days 10–22 | Front art galleries, underground casinos, mafia concrete cartels, port smuggling. |
| **Phase 5** | **Absurd Satire, Cults & Eccentric Billionaires** | `EVT_101` – `EVT_122` | 22 | Days 12–25 | Titanium Mayor statues, crypto city currency, doomsday cult bunkers, pet mammoths. |
| **Phase 6** | **Disasters, Emergencies & Infrastructure Collapse** | `EVT_123` – `EVT_142` | 20 | Days 15–28 | Post-earthquake permits, hospital oxygen shortages, reservoir contamination, heatwaves. |
| **Phase 7** | **Branching Chains & Cascading Consequences** | `EVT_143` – `EVT_162` | 20 | Days 16–30 | Direct aftermaths of earlier choices (e.g. collapsed towers vs. celebrated eco-parks). |
| **Phase 8** | **Endgame Federal Audits & Re-Election Climax** | `EVT_163` – `EVT_180` | 18 | Days 24–30 | Federal prosecutor warrants, foreign embassy disputes, opposition smear campaigns. |
| **TOTAL** | **Full Master Mandate Library** | **EVT_001 – EVT_180** | **180** | **Days 1–30** | **100% Unique Run + Over 50% New Content on Replay.** |

---

## 4. Phase-by-Phase AI Generation Prompts

Use these exact prompts sequentially to generate each phase's JSON and CSV datasets.

---

### Phase 1 AI Prompt: Urban Megaprojects & Real Estate Rackets (`EVT_013` – `EVT_034`, 22 Events)

```markdown
You are an expert narrative designer and systems engineer for "Yes, Mr. Mayor!".

YOUR TASK:
Generate exactly 22 new event definitions (IDs EVT_013 through EVT_034) for Phase 1: "Urban Megaprojects & Real Estate Rackets".
Also generate the complete localization entries for English (en), Turkish (tr), and Spanish (es) for data/localization.csv.

THEMATIC FOCUS:
- Predatory construction companies, illegal luxury towers, riverbed encroachments, historical facade demolitions, green belt seizures, and zoning bribery.
- Pacing: Early-to-mid mandate (Days 1–12).
- Balance: 13 violating events (subtle Papers, Please style discrepancies) and 9 clean, fully compliant civic petitions.
- Bribes: Between $25,000 and $95,000 for corrupt developers; $0 for clean public housing petitions.

TECHNICAL RULES:
1. Output a valid JSON array matching the EventData format:
   - Fields: id, category ("zoning", "development"), day_range: [1, 15], title_key, description_key, applicant_key, bribe_offered, application_data (district_id, floors, budget_stated, seal_id, reg_code, expiry_date), report_data (inspector_name_key, measured_floors, hazard_level, tax_debt, soil_status, notes_key), violations (array of objects with id, name_key, tags), effects_approve, effects_reject, news_headline_approve_key, news_headline_reject_key.
2. Valid tags: "app_applicant", "rule_blacklist_guide", "app_district", "rule_zoning_historic", "rule_zoning_river", "rule_zoning_green", "rule_zoning_central", "app_floors", "rep_measured_floors", "app_seal", "rule_seal_guide", "app_expiry", "rep_tax_debt", "rule_tax_guide", "rep_hazard".
3. Output the CSV localization block:
   keys,en,tr,es
   (Ensure all text containing commas is wrapped in double quotes).

Generate the full, complete, untruncated JSON and CSV output now.
```

---

### Phase 2 AI Prompt: Transit Grabs, Utilities & Ecological Hazards (`EVT_035` – `EVT_056`, 22 Events)

```markdown
You are an expert narrative designer and systems engineer for "Yes, Mr. Mayor!".

YOUR TASK:
Generate exactly 22 new event definitions (IDs EVT_035 through EVT_056) for Phase 2: "Transit Grabs, Utilities & Ecological Hazards".
Also generate the complete localization entries for English, Turkish, and Spanish.

THEMATIC FOCUS:
- Overpriced light rail extensions, toxic chemical pipeline permits, private automated tollways, corrupt water treatment concessions, rolling blackout waivers, high-voltage transformers in residential courtyards.
- Pacing: Days 3–15.
- Balance: 13 violating events (forged Chamber seals, hazardous chemical soil, heavy tax arrears, blacklisted contractors) and 9 clean public infrastructure modernizations.
- Tabloid news headlines must feature biting satire (e.g. "Tap water glows neon blue; Mayor calls it free holiday lighting").

Produce the full, untruncated JSON and CSV output now.
```

---

### Phase 3 AI Prompt: Labor Unions, Social Strife & Civic Welfare (`EVT_057` – `EVT_078`, 22 Events)

```markdown
You are an expert narrative designer and systems engineer for "Yes, Mr. Mayor!".

YOUR TASK:
Generate exactly 22 new event definitions (IDs EVT_057 through EVT_078) for Phase 3: "Labor Unions, Social Strife & Civic Welfare".
Also generate the complete localization entries for English, Turkish, and Spanish.

THEMATIC FOCUS:
- Sanitation union strikes, public hospital ICU bed shortages, municipal cemetery privatization, school cafeteria meal cuts, firefighter hazard pay, riot police surplus vehicle procurement.
- Pacing: Days 5–18.
- Moral dilemmas: Legitimate public workers pleading for basic funding vs. private predatory subcontractors offering fat kickbacks to take over essential services.
- Balance: 12 violating predatory petitions and 10 clean social welfare/union petitions.

Produce the full, untruncated JSON and CSV output now.
```

---

### Phase 4 AI Prompt: Underground Economy, Cartels & Money Laundering (`EVT_079` – `EVT_100`, 22 Events)

```markdown
You are an expert narrative designer and systems engineer for "Yes, Mr. Mayor!".

YOUR TASK:
Generate exactly 22 new event definitions (IDs EVT_079 through EVT_100) for Phase 4: "Underground Economy, Cartels & Money Laundering".
Also generate the complete localization entries for English, Turkish, and Spanish.

THEMATIC FOCUS:
- Organized crime fronts: Contemporary art galleries laundering illicit cartel cash, concrete monopolies fixing municipal bids, underground VIP baccarat clubs masquerading as gymnastics centers, private docks bypassing customs inspections.
- Pacing: Days 10–22.
- High risk / high reward: Massive bribes ($60,000–$130,000), but heavy suspicion penalties (+15% to +25%).
- Balance: 14 violating mob schemes and 8 honest small businesses falsely accused by paranoid inspectors.

Produce the full, untruncated JSON and CSV output now.
```

---

### Phase 5 AI Prompt: Absurd Satire, Cults & Eccentric Billionaires (`EVT_101` – `EVT_122`, 22 Events)

```markdown
You are an expert narrative designer and systems engineer for "Yes, Mr. Mayor!".

YOUR TASK:
Generate exactly 22 new event definitions (IDs EVT_101 through EVT_122) for Phase 5: "Absurd Satire, Cults & Eccentric Billionaires".
Also generate the complete localization entries for English, Turkish, and Spanish.

THEMATIC FOCUS:
- Absurdist political satire:
  * Tech moguls petitioning to build commercial orbital launchpads in community dog parks.
  * Doomsday cults requesting permits for subterranean apocalypse bunkers beneath city hall.
  * Billionaires offering to pay the city debt if they are allowed to erect an 80-meter golden statue of the Mayor with laser eyes.
  * A scheme to replace the municipal currency with "MayorBucks" blockchain tokens.
- Pacing: Days 12–25.
- Balance: 13 corrupt/insane violating schemes and 9 harmless, eccentric community initiatives that boost civic happiness.

Produce the full, untruncated JSON and CSV output now.
```

---

### Phase 6 AI Prompt: Disasters, Emergencies & Infrastructure Collapse (`EVT_123` – `EVT_142`, 20 Events)

```markdown
You are an expert narrative designer and systems engineer for "Yes, Mr. Mayor!".

YOUR TASK:
Generate exactly 20 new event definitions (IDs EVT_123 through EVT_142) for Phase 6: "Disasters, Emergencies & Infrastructure Collapse".
Also generate the complete localization entries for English, Turkish, and Spanish.

THEMATIC FOCUS:
- Urban crisis management: Post-earthquake structural retrofits with counterfeit engineering stamps, municipal reservoir chemical contamination scares, extreme heatwave emergency shelter tenders, hospital oxygen contractor monopolies.
- Pacing: Days 15–28.
- Consequence weight: Rejections and approvals carry major public opinion swings (±20% to ±35%) and financial shocks.
- Balance: 12 fraudulent emergency profiteering petitions and 8 urgent legitimate disaster relief programs.

Produce the full, untruncated JSON and CSV output now.
```

---

### Phase 7 AI Prompt: Branching Chains & Cascading Consequences (`EVT_143` – `EVT_162`, 20 Events)

```markdown
You are an expert narrative designer and systems engineer for "Yes, Mr. Mayor!".

YOUR TASK:
Generate exactly 20 new event definitions (IDs EVT_143 through EVT_162) for Phase 7: "Branching Chains & Cascading Consequences".
Also generate the complete localization entries for English, Turkish, and Spanish.

SPECIAL MECHANIC:
- These events are direct follow-ups to decisions made in Phase 1 through Phase 5!
- Format them in connected pairs (10 pairs = 20 events):
  * Pair 1A (EVT_143): Triggered if EVT_013 (Aura Towers) was APPROVED -> "Aura Towers Structural Collapse: Contractor Flees to Caymans".
  * Pair 1B (EVT_144): Triggered if EVT_013 was REJECTED -> "Historic District Heritage Festival: UNESCO Award Ceremony".
  * Pair 2A (EVT_145): Triggered if toxic waste waiver was APPROVED -> "Aqueduct Mutation Scare: Angry Mothers Storm Council".
  * Pair 2B (EVT_146): Triggered if toxic waste was REJECTED -> "Clean Water Innovation Lab Inauguration".
  * And so on for 10 distinct decision aftermaths!
- Include `"unlocks_event_id"` metadata and explicit narrative continuity in descriptions and news headlines.

Produce the full, untruncated JSON and CSV output now.
```

---

### Phase 8 AI Prompt: Endgame Federal Audits & Re-Election Climax (`EVT_163` – `EVT_180`, 18 Events)

```markdown
You are an expert narrative designer and systems engineer for "Yes, Mr. Mayor!".

YOUR TASK:
Generate the final 18 event definitions (IDs EVT_163 through EVT_180) for Phase 8: "Endgame Federal Audits & Re-Election Climax".
Also generate the complete localization entries for English, Turkish, and Spanish.

THEMATIC FOCUS:
- The dramatic climax of the 30-day mandate (Days 24–30):
  * Federal Anti-Corruption Prosecutor subpoena for municipal bank records.
  * Secret police wiretap disclosure waivers.
  * Foreign Embassy extraterritorial land annexation requests with diplomatic threats.
  * Opposition candidate launching multi-million dollar smear campaign dossiers.
  * Last-minute slush fund diversion opportunities to secure offshore pensions.
- Consequence weight: Massive stakes. Single choices can trigger game-over arrests (Suspicion 100%) or citizen riots (Opinion <= 15%).
- Balance: 11 high-risk traps and 7 decisive statecraft triumphs.

Produce the full, untruncated JSON and CSV output now.
```

---

## 5. Localization & Translation Integrity Guidelines

Every single event across all 8 phases requires 6 synchronized keys in `data/localization.csv`:
```csv
keys,en,tr,es
EVT_XXX_TITLE,"English Title","Türkçe Başlık","Título en Español"
EVT_XXX_DESC,"English description...","Türkçe açıklama...","Descripción en español..."
EVT_XXX_INSP_NOTES,"Inspector technical field notes...","Müfettiş teknik inceleme notu...","Notas técnicas del inspector..."
EVT_XXX_NEWS_APP,"Approve headline!","Onay manşeti!","¡Titular de aprobación!"
EVT_XXX_NEWS_REJ,"Reject headline!","Ret manşeti!","¡Titular de rechazo!"
COMP_XXX,"Company Name","Şirket Adı","Nombre de la Empresa"
```

### 5.1 Satirical Tone Principles:
* **Turkish (`tr`):** Grounded in biting local political satire (*"Sayın Başkanım"*, rant lobisi, imar barışı, dere yatağı projeleri, fahiş ihale komisyonları, gizli İsviçre hesapları, gösterişli açılışlar).
* **English (`en`):** Punchy, cynical, dry bureaucratic wit (*"Mr. Mayor"*, PAC donations, offshore shell accounts, corporate loopholes, regulatory capture).
* **Spanish (`es`):** Sharp political irony (*"Señor Alcalde"*, recalificaciones fraudulentas, mordidas, testaferros, adjudicaciones a dedo).

---

## 6. Verification & Automated Quality Assurance

When integrating batches of events:
1. **JSON Syntax Integrity:** Validate with `JSON.parse_string()` to guarantee zero unescaped quotes or trailing commas.
2. **Tag Matching Guarantee:** Every violation tag must exist in `DocumentItem.gd` and `Rulebook.gd`.
3. **CSV Column Alignment:** Exactly 4 columns (`keys,en,tr,es`) per row, with quoted strings for multi-sentence texts.
4. **Day Pacing Filter:** In `EventManager.gd`, `prepare_daily_queue()` checks `day_range` so early-game events never spawn in the endgame, and vice versa.
