# Demo Script — 20 Minutes

One PAX's week, in Digital Weinke's own tab order (now Home → Map/Cal →
Commz → Resources → Profile, reorganized this pass to match the official
app's wireframes). Run it live on a phone with a signed-in account that has
real HC/Q history — see the pre-demo checklist at the bottom.

## Framing (1 min)

"I'm on board with a ground-up build. This is what I learned running a real
client against the real F3 Nation API for the last few months, so you don't
have to relearn it. I built DW's tab structure to match your wireframes for
this walkthrough, so you can see it screen-for-screen against what you're
planning."

## 1. Onboarding — Welcome fork (2 min)

Sign out first if needed. Show the new fork: **"I already post with F3"**
vs **"I'm new to F3."**

- Tap **I'm new to F3** → browse the map (no account needed) → the Lexicon
  (F3 lingo primer) → notification prefs → the honest placeholder: *no
  account creation or region approval here yet — the F3 Nation API has
  neither endpoint for this app to call.*
- Back out, tap **I already post with F3** → real F3 SSO sign-in
  (`auth2.f3nation.com`, public PKCE client, no secret anywhere in the
  binary) → lands on the new **confirm profile & home region** step (your
  real name and region, pulled from the F3 Nation profile the sign-in
  itself just resolved) → optional app-lock/emergency-info setup → the
  shell.

**Point out:** no account creation, no region-approval request — both
require F3 Nation API endpoints that don't exist yet. Browsing before an
account is real, not a mockup.

## 2. Home (1 min)

Today's focus card (Q'ing, HC'd, or find a beatdown), the new **Region
Info** card (region name + live AO count, tapping through to Map/Cal), and
the At The Flag check-in. Mention: no SLT announcements feed — the API has
no backing for one.

## 3. Map/Cal (6 min) — DW's strongest area

Tap the **Map/Cal** tab. Toggle between **Map** and **Calendar** — same
toggle remembers whichever view was used last (also settable as a default
in Profile → Settings).

- **Map**: real, live, nationwide AO data. Search, filter by day/state/
  region/workout-type, Near Me Right Now, real AO logos, Get Directions.
- **Calendar**: find a real upcoming beatdown — now navigable week by week
  (prev/next), not locked to a fixed 8-day window. **HC** (sign up) — this
  is a real write to the F3 Nation API, not a local checkbox. Open the
  event, **take Q** for an open slot, write a **preblast** (point out: the
  gear chips — Coupons/Sandbags/Weight Vest-Ruck/Jump Rope/Headlamp — are
  optional and round-trip on edit; posts the real `preblastRich` Slack
  block too, not just plain text — otherwise Slack's own bot would think
  no preblast was ever posted). Name-O-Rama roll call now prefills from the
  real HC list for the linked event instead of only DW's local tracking.

**Point out:** the whole chain — HC, take-Q, preblast — stays threaded on
the same event instance id, so the app never re-asks "which event is this
for?"

## 4. Resources — the Q flow (6 min)

Tap **Resources**. Walk the grouping: **Q Tools** (Q Mode, Build a Weinke,
Q Builder — newly wired into the nav this pass, previously dead code — Deck
of Pain), **The Codex** (Exicon + Lexicon), **QSource**, **App Help**.

- **Build a Weinke**: generate a 50-minute plan from the real 907-exercise
  Exicon, swap any exercise with one tap.
- **Q Mode**: run the live phase timer (Disclaimer → Warm-O-Rama → The
  Thang → Mary → COT) to COT. Show Emergency Mary (one-tap skip, with a
  confirm dialog — sweaty/gloved hands at 5:30 AM mis-tap).
- **Publish the backblast**: real write to the F3 Nation API — backblast
  text, PAX count, FNG count, attendance per PAX. This is the moment DW
  stops being a local notes app and starts being a real F3 Nation client.

## 5. Profile (2 min)

Tap **Profile** — now a hub, grouped under the wireframes' own PROF-01..06
naming instead of landing straight on Settings. **Identity card** up top
(real F3 Me name, roles, positions, region) opening into the full profile
(edit, emergency contact — most fields now best-effort sync to F3 Nation
when signed in, not local-only). Below it: **PAX Vault** (saved-session
trends and the activity heatmap), **Badges & Milestones** (achievements,
Founding Quest), a **Leaderboards** card shown disabled with an honest
one-line reason (no region-wide stats endpoint), and **Settings** as its
own card (appearance, voice, music, the "Map/Cal opens to" default-view
toggle, data/backup).

## 6. Commz and what DW doesn't do (1 min)

Tap **Commz** signed in: Region Chat, channel switcher per AO, clearly
labeled **"Preview — not connected to Slack yet. Messages stay on this
device only."** Sign out and tap it again: a lock screen instead of an
empty chat view.

**Be upfront, in this order:**
- **Commz** is a local-only UI sketch. No chat server exists; the
  wireframes' own notes point at something like Matrix with a Slack
  bridge for hybrid regions — that's the single biggest build-vs-buy call
  in this whole comparison.
- **Announcements** have no backing at all — no pinned posts, no read
  state, no reactions, no feed endpoint.
- **Region approval** — there's no `region_membership_status` field or
  approval workflow in the API. Any gate on who's "really" in a region has
  to be built from scratch either way.

These three gaps live in the F3 Nation API itself, not in DW — a ground-up
build inherits them regardless of which codebase it starts from.

## 7. Ask (1 min)

"Where can I help? I can hand over the written access-pattern and API-quirk
notes (`docs/learnings-for-official-app.md`), and I'd like to join the
build-vs-buy tech series if there's a seat."

---

## Pre-demo checklist

- [ ] Build from this branch's HEAD and run the full sign-in → HC → take-Q
      → preblast → backblast loop against prod once, start to finish.
- [ ] Confirm sign-in scope includes `openid` (already does) — and ideally
      do a real device pass on `offline_access` once auth3 goes strict
      OIDC, since this session couldn't test that live (no device/browser
      access in this sandbox).
- [ ] Use a signed-in account with real HC/Q history so Calendar and
      Profile aren't empty during the walkthrough.
- [ ] Walk the new Welcome fork once end-to-end beforehand — it's new this
      pass and hasn't had a live device pass either.
- [ ] Decide in advance whether to mention the API key removal — worth a
      one-line callout if anyone asks about security, but not load-bearing
      for the demo itself.
- [ ] None of the following has had a live device pass yet — all reasoned
      through and unit-tested, but worth a quick walk before the demo:
  - [ ] Map/Cal's new workout-type filter pill (alongside day/state/region).
  - [ ] Calendar's week-by-week prev/next nav, especially around a month
        boundary and the "jump to today" reset.
  - [ ] Preblast gear chips — post one with a couple selected, reopen "Edit
        Preblast," confirm the same chips come back selected.
  - [ ] Name-O-Rama roll call prefilling from the real HC list for a linked
        event (vs. the old local-tracking fallback when nothing's linked).
  - [ ] The new Profile hub: every card opens the right screen (identity →
        full profile, PAX Vault → history, Badges → achievements,
        Settings), and the Leaderboards card stays inert, not a dead tap.
  - [ ] Confirm the pagination field names (`total`/`hasMore`/
        `hasNextPage`) in `F3ApiService._getAllPages` against a real
        paginated response — implemented defensively since this sandbox
        has never been able to reach `api.f3nation.com` (confirmed again
        this pass: the egress proxy 403s it) to see a real payload shape.
