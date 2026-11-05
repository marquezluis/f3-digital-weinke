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
  region, Near Me Right Now, real AO logos, Get Directions.
- **Calendar**: find a real upcoming beatdown. **HC** (sign up) — this is a
  real write to the F3 Nation API, not a local checkbox. Open the event,
  **take Q** for an open slot, write a **preblast** (point out: posts the
  real `preblastRich` Slack block too, not just plain text — otherwise
  Slack's own bot would think no preblast was ever posted).

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

Real F3 Me identity (name, roles, positions from F3 Nation), achievements
and Founding Quest, history with the heatmap, the on-device-only emergency
contact card (never synced — PHI stays local by design), and Settings
(including the new "Map/Cal opens to" default-view toggle).

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
