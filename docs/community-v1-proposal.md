# Community v1 — Proposal

Status: draft, not started. This is the write-up for the roadmap's 2.7–2.8
phase — greenlit to start now on the reasoning that Tackle has stated
Slack-independence as a long-term goal, so building toward it is safe even
before the SLT's formal requirements land.

---

## 1. Why now

Moneyball's tier framework (July 2026) places Digital Weinke at "Regional
Innovation," moving up with team alignment. Separately, both he and Dark
Helmet want tech independence from Slack long-term, and Moneyball's own
words: work here "could definitely move up" the tier ladder, and he can see
`#the-f3-app` "stemming from what you're building." Community v1 is the
single highest-leverage thing to build next for that trajectory — it's the
one piece of the app that's currently a placeholder (Brotherhood Board is a
read-only dashboard, no actual community layer) and the one piece that maps
directly onto "replace Slack."

The risk is building the wrong shape: a client-only feature that looks like
community but has nowhere to plug into F3 Nation's real data model. This doc
splits the work into what's safe to build alone vs. what needs the F3 team.

## 2. What exists today

- **`lib/screens/brotherhood_screen.dart`** — "Brotherhood Board": hero card,
  FNG pipeline, AO list, crew, hard commits, recent beatdowns. All read
  directly from data the app already fetches (attendance, event instances,
  Q history). No message/post/comment concept exists anywhere in the app.
- **F3 Nation's actual schema** (confirmed by reading the live schema, not
  guessing): `orgs` is self-referencing Nation → Sector → Area → Region → AO.
  `users.homeRegionId` scopes a person to a region. `rolesXUsersXOrg` grants
  org-scoped roles (editor/admin) with inheritance downward. **There is no
  chat, message, post, or comment table anywhere in the schema.** All
  region-to-PAX and PAX-to-PAX communication today is Slack, driven by the
  Python `slackbot` app in the monorepo — the backblast/preblast posting the
  app already does is itself just one Slack message type among many.

The conclusion this forces: a "Community" tab can't be a real messaging
product without new backend tables. F3 Nation owns the org/user identity
graph; Digital Weinke doesn't get to invent a parallel one.

## 3. Scope split — build alone vs. need the team

**Buildable now, zero backend dependency (v1.0):**
An AO-scoped **activity feed** assembled entirely from data the app already
pulls from the real API — no new endpoints, no new tables, nothing to ask
the F3 team for. Feed items: posted backblasts (text + Pic-o-Rama photos,
already built this session), achievement unlocks, new HCs/Qs claimed,
FNG counts. This is a read model over data that already has a system of
record (the API) — it's not inventing state, just presenting it as a feed
instead of a dashboard. Ships as an evolution of Brotherhood Board, not a
new backend integration.

**Needs a small new table, low risk to propose (v1.1):**
Reactions (👊, 🙏) on feed items. Either (a) genuinely client-local
(SharedPreferences, this-device-only — cheap, but not "community," since
nobody else sees your reaction), or (b) a real `reactions` table
(`userId`, `targetType`, `targetId`, `emoji`) the F3 team would need to add.
Recommend proposing (b) as a small, low-risk, easy-to-review addition — it's
a good first ask to test whether the team wants incremental PRs from us on
the API/DB side at all, before proposing anything bigger.

**The real ask — needs the F3 team's design buy-in (v1.2, "replace Slack"):**
Actual messaging: a `messages`/`threads` schema, org-scoped like everything
else in their model (`orgId` + `rolesXUsersXOrg` for who can post/see).
This is not something to build unilaterally against a fork — it's the
actual shape of "the-f3-app" Moneyball is still gathering requirements for.
Building this alone risks presenting the team with a fait accompli on the
exact decision they've said they want SLT input on.

## 4. Recommended phasing

| Step | What | Backend dependency | Status |
|---|---|---|---|
| v1.0 | AO activity feed (backblasts, unlocks, Q claims) | None — reads existing data | Ready to build |
| v1.1 | Reactions on feed items | New `reactions` table (small, proposable) | Design + propose to team |
| v1.2 | Direct/group messaging | New `messages`/`threads` schema, org-scoped | Wait for SLT requirements |

v1.0 is worth starting immediately — it's real, useful, ships under the
app's own steam, and it's the natural home for Pic-o-Rama photos and the
call-style/achievement work already shipped in v2.4.3. v1.1 is a good test
of the working relationship with the F3 team on schema changes. v1.2 is
explicitly sequenced *after* Moneyball's formal requirements land, so the
timeline point Moneyball raised is respected rather than preempted.

## 5. Draft schema sketch (for v1.1, to bring to the team as a concrete ask)

```sql
-- follows the existing org-scoped convention (rolesXUsersXOrg)
create table reactions (
  id          serial primary key,
  user_id     integer not null references users(id),
  target_type text not null,   -- 'backblast' | 'achievement' | ...
  target_id   integer not null,
  emoji       text not null,
  created     timestamp not null default now(),
  unique (user_id, target_type, target_id, emoji)
);
```

Small, additive, no migration risk to existing tables — a reasonable first
PR to gauge appetite for API/DB contributions from outside the core team.

## 6. Positioning if this comes up with Moneyball or Tackle

"I read through the actual schema before building anything — there's no
chat model today, so a real Community tab is a data-model conversation, not
just a UI one. I've scoped a v1 that needs nothing from you (an activity
feed over data you already have), a v1.1 that's a small proposable table if
you're open to a PR, and left messaging itself — the actual Slack-replacement
piece — for after your team's requirements land. Wanted to build toward the
vision without getting ahead of the decision that's yours to make."
