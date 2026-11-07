# Wireframe Mapping — DW vs. the Official F3 Nation App

Maps all 36 screens from Moneyball's low-fi wireframes (5 HTML files: onboarding,
home/map/cal, commz, resources, profile — shared Nov 5) against what Digital
Weinke does today, after the demo-prep pass on branch
`feat/moneyball-wireframe-demo`.

**Methodology note:** this session worked from the task brief's own screen
descriptions and the earlier `DW vs official F3 app wireframes` comparison
artifact (published Nov 5, sourced against DW commit `6f42493` and the raw
wireframe files directly). This session itself did not re-open the 5 attached
HTML files or their embedded SLT/dev-notes/open-questions JS data — so the
**area-level** status below (Onboarding, Home/Map-Cal, Commz, Resources,
Profile) is accurate, but the exact boundaries between individual screens
within FNG-02..06 and PAX-01/02/04 specifically are an approximation, not a
literal re-parse of the wireframe markup. Worth a quick pass against the
actual files before the demo to confirm screen-by-screen wording matches.

**Status key:**
- **done** — real, working DW equivalent today
- **partial** — DW covers the core idea but not every element of the wireframe screen
- **placeholder** — DW shows something, but it's explicitly a stand-in (no backend yet)
- **not possible without backend** — the F3 Nation API has no endpoint this needs

## Onboarding (10 screens)

| Screen | What the wireframe asks for | DW screen/file | Status | Notes |
|---|---|---|---|---|
| FNG-01 | Welcome fork: "I'm new to F3" vs "I already post with F3" | `welcome_fork_screen.dart` | done | New this pass — previously jumped straight into the sign-in screen with no fork |
| FNG-02 | FNG account creation + emergency info | `fng_welcome_screen.dart` (placeholder step) | placeholder | No account-creation endpoint; emergency info itself is real (`emergency_edit_screen.dart`) but reached from Profile, not this flow |
| FNG-03 | Intro video | — | not possible / not built | No video asset or hosting; out of scope for this pass |
| FNG-04 | Lingo card | `fng_welcome_screen.dart` → `showF3GlossarySheet` | done | Reuses the existing F3 glossary sheet |
| FNG-05 | Pick region, sends Commz approval request | — | not possible without backend | No `region_membership_status` field or approval endpoint exists in the F3 API |
| FNG-06 | Tab tour + notification prefs | `fng_welcome_screen.dart` (notif step) | partial | Notification prefs are real (wires `SettingsService`/`NotificationService`); no tab tour/walkthrough overlay |
| PAX-01 | F3 Name confirmation after first post | — | not built | No "first post" detection flow; out of scope for this pass |
| PAX-02 | F3 SSO sign-in | `login_gate_screen.dart` | done | Public PKCE client against `auth2.f3nation.com`, pre-existing |
| PAX-03 | Confirm profile and home region | `onboarding_screen.dart` (`_ConfirmProfilePage`, new this pass) | done | Surfaces what sign-in already resolved; "Change region" re-uses Profile's own org picker |
| PAX-04 | Land in the app shell | `shell_screen.dart` | done | Pre-existing |

## Home / Map-Cal (8 screens)

| Screen | What the wireframe asks for | DW screen/file | Status | Notes |
|---|---|---|---|---|
| HOME-01 | Region hub: SLT announcements (read state, reactions) | `home_screen.dart` (`_RegionInfoCard`, new this pass) | partial | Region name + AO count shown; announcements are a placeholder — no `/v1/regions/{id}/home` feed or per-user read-state exists |
| HOME-02 | Special events, region info, SLT directory | `home_screen.dart` (`_RegionInfoCard`) | partial | Region info covered; no SLT/leadership directory — `/v1/org` carries no position/role data at the region level |
| MAP-01 | AO map with filters | `map_cal_screen.dart` → `browse_aos_screen.dart` | done | Map + day/weekday + state/region filters already existed; a workout-type filter (sourced from the same `eventTypeName` field already shown per-workout) was added in a follow-up pass |
| CAL-01 | Week calendar with Q status, week nav | `map_cal_screen.dart` → `schedule_screen.dart` | done | Month-grid nav already existed; the plain agenda's fixed 7-day window is now navigable week by week too (added in a follow-up pass) |
| EVT-01 | HC, take Q | `schedule_screen.dart` | done | Pre-existing, real writes to the API |
| EVT-02 | Preblast with gear chips and a private Q plan | `schedule_screen.dart` (preblast composer) | done | Preblast posting is real. "The Plan" (DW's own Weinke draft) carries an explicit caption stating only that plan text is sent and the draft itself stays on-device. Gear chips (Coupons/Sandbags/Weight Vest-Ruck/Jump Rope/Headlamp — a fixed app-side list, not from any API) are now selectable, round-trip through a `GEAR:` line in the posted text, and prefill correctly on "Edit Preblast." Still no private Q-plan field — that's the one genuinely not-possible-without-backend part of this screen |
| EVT-03 | Backblast with roster and FNG count | `history_screen.dart` / `save_session_sheet.dart` / `timer_screen.dart` | done | Publishing a real backblast + FNG count to the API is done; roll call (`timer_screen.dart`'s `_WorkoutSummarySheetState`) now prefills from the real HC list for the linked event (added in a follow-up pass), Q still adds walk-ups/removes no-shows by editing the text. FNG count stays manual by necessity — FNGs aren't on any HC list to prefill from |
| BB-01 | Backblast detail | `history_screen.dart`'s `BackblastScreen` | done | Pre-existing |

## Commz (6 screens)

| Screen | What the wireframe asks for | DW screen/file | Status | Notes |
|---|---|---|---|---|
| COMMZ-01 | Core/AO/topic channels | `chat_screen.dart` | partial | Channel switcher (#general + one per AO) is real UI; local-only, no live message relay |
| COMMZ-02 | Area → Nation channels | — | not possible without backend | No multi-region channel hierarchy in the API |
| COMMZ-03 | Event threads | — | not built | Not attempted this pass |
| COMMZ-04 | Global DMs | — | not possible without backend | No messaging backend at all |
| COMMZ-05 | Admin channel setup, @channel rules | — | not possible without backend | Same — no chat server |
| COMMZ-06 | Slack bridge | `chat_screen.dart`'s `_PreviewBanner` | placeholder | Explicitly labeled "Preview — not connected to Slack yet"; now also gated behind sign-in (`_CommzLockScreen`, new this pass) instead of showing to a signed-out PAX |

## Resources (6 screens)

| Screen | What the wireframe asks for | DW screen/file | Status | Notes |
|---|---|---|---|---|
| RES-01 | Q Tools hub | `resources_hub_screen.dart` (new this pass) | done | Groups Q Mode, Build a Weinke, Q Builder, Deck of Pain |
| RES-02 | Tips / structure | `q_builder_screen.dart` | done | Previously built but unreachable from any nav — wired in this pass |
| RES-03 | Q Builder | `q_builder_screen.dart` | done | Same screen as RES-02 in DW's structure |
| RES-04 | Live runner ("Gloom Mode") | `timer_screen.dart` | done | Elapsed clock, phase-aware countdown, checkable blocks via per-exercise advance, jump to backblast on save — pre-existing |
| RES-05 | Searchable Exicon + Lexicon, QSource, Freed to Lead | `library_screen.dart`, `f3_glossary_sheet.dart`, `qsource_screen.dart` | partial | Exicon, Lexicon, and QSource all done and now grouped together; Freed to Lead e-book deliberately skipped (no redistribution rights) |
| RES-06 | App Help | `resources_hub_screen.dart`'s `_AppHelpScreen` (new this pass) | done | Lightweight static help screen — no support-ticketing system behind it, by design |

## Profile (6 screens)

The Profile tab now routes to `profile_hub_screen.dart` (added in a follow-up
pass) instead of straight to `settings_screen.dart` — a hub grouping
PROF-01..06 the same way `resources_hub_screen.dart` grouped Resources,
instead of identity and app preferences sharing one long scroll. The
identity banner and manual-F3-name field moved there verbatim from Settings;
Settings itself is preferences-only now.

| Screen | What the wireframe asks for | DW screen/file | Status | Notes |
|---|---|---|---|---|
| PROF-01 | F3 Me identity | `profile_hub_screen.dart` (identity card) → `profile_screen.dart` | done | Real F3 Nation profile (name, roles, positions, region); identity card now lives in the hub, one tap from the full screen |
| PROF-02 | PAX Vault trends | `profile_hub_screen.dart` → `history_screen.dart` | partial | Now has its own card in the Profile hub (previously only reachable from Home) — but trends still come from DW's own saved sessions, not F3 Nation's PAX Vault (no such read endpoint integrated) |
| PROF-03 | Badges and milestones | `profile_hub_screen.dart` → `achievements_screen.dart` | done | Achievements + Founding Quest; now has its own card in the Profile hub (previously only reachable from Brotherhood) |
| PROF-04 | Leaderboards | `profile_hub_screen.dart` (disabled card) | not possible without backend | Shown as a disabled card explaining why, instead of a dead link or a missing screen — `/v1/org` and friends have no region-wide stats endpoint |
| PROF-05 | Edit profile, emergency contact | `profile_screen.dart`, `emergency_edit_screen.dart` | done | Pre-existing |
| PROF-06 | Settings, default Map vs Calendar view | `profile_hub_screen.dart` → `settings_screen.dart` | done | "Map/Cal opens to" toggle (added in an earlier pass); Settings is now a card in the hub rather than the whole tab |

## Not possible without backend — a standing list

These gaps live in the F3 Nation API itself, not in Digital Weinke, and would
block any ground-up build the same way:

- **Region membership / approval** — no `region_membership_status` field or
  approval endpoint (FNG-05).
- **Announcements** — no pinned-post feed, no per-user read state or
  reactions, no `/v1/regions/{id}/home` (HOME-01).
- **Chat server** — no messaging backend of any kind (COMMZ-01..05).
- **Private Q plan field** — no `q_plan` column on an event instance visible
  only to the Q/admins (EVT-02); DW's own Weinke draft stays local instead.
- **Region leadership/SLT directory** — `/v1/org` has no position/role data
  at the region level (HOME-02).
- **PAX Vault** — no endpoint for aggregated historical trends beyond what a
  client computes itself from attendance records (PROF-02).
- **Leaderboards** — no region-wide stats endpoint; `/v1/org` and friends
  only ever return the signed-in PAX's own data (PROF-04).
