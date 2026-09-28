# Acceptance Criteria: Adoption Policy Auto-Evaluation — Advisory Request Screening with Natural-Language Shelter Policies

**Source plan:** `specs/49_adoption_policy_evaluation_plan.md`

---

## AC-1: Automatic evaluation on request receipt

**Given** an adopter submits an adoption request for a shelter pet
**Then** an evaluation is enqueued and runs automatically (system rules + enabled shelter rules)

**Given** the evaluation is running
**Then** the adopter's confirmation and the request creation are never blocked or delayed by it

**Given** a request is created
**Then** an evaluation snapshot is persisted on the request containing: verdict, summary, per-rule results (rule, severity, source, passed/failed, evidence), evaluated-at timestamp, and a version stamp

---

## AC-2: Verdicts are advisory — the shelter always decides

**Given** any evaluation verdict (red, yellow, or green) is produced
**Then** the request status is never changed by the evaluation — it remains `pending`

**Given** an evaluation verdict is produced
**Then** the adopter is never notified of any decision by the evaluation itself; only the shelter's own accept/validate/decline actions notify the adopter

**Given** a shelter disagrees with a red verdict
**Then** they can still accept the request through the existing decision flow — the evaluation never blocks a decision

---

## AC-3: Red verdict (High concern)

**Given** at least one enabled high-severity (reject) rule fails
**Then** the verdict is **High concern** (red badge) and the request status is never changed

**Given** a red verdict is shown
**Then** the section lists the failed high-severity rules with evidence and uses advisory copy ("we recommend reviewing") — never decision-like copy

---

## AC-4: Yellow verdict (Needs review)

**Given** at least one enabled warning-severity rule fails, or an enabled rule cannot be evaluated due to missing data
**Then** the verdict is **Needs review** (yellow badge) and the request status is never changed

**Given** a rule could not be evaluated because data was missing
**Then** the rule shows a "couldn't verify" result with evidence stating what was missing — never an inferred pass or fail

---

## AC-5: Green verdict (Pre-accept) never accepts

**Given** at least one rule was evaluated and all evaluated rules passed
**Then** the verdict is **Pre-accept** (green badge) and the request status is never changed

**Given** a pre-accept verdict
**Then** the request still requires a manual acceptance by the responsible party — the system never auto-accepts

---

## AC-6: System rules

**Given** any adoption request is evaluated
**Then** the platform system rules are always evaluated: account younger than 3 days → red; unverified email → red; adopter under 18 → red; profile below 60% completeness → yellow; prior declined/withdrawn request for the same pet → yellow

**Given** a shelter views their evaluation settings
**Then** system rules are visible but read-only (thresholds and severity are platform-owned)

---

## AC-7: Natural-language policies are translated into reviewable rules

**Given** a shelter saves natural-language adoption policies in the "Automatic evaluation" settings
**Then** each policy is translated by the AI service into proposed structured rules from the bounded vocabulary (rule type, parameters, suggested severity)

**Given** the translation is proposed
**Then** the shelter can review, edit parameters/severity, enable/disable, or discard each translated rule before it affects evaluation

**Given** only reviewed and enabled rules exist
**Then** only those rules participate in request-time evaluation

**Given** the AI provider fails or returns unparseable output during translation
**Then** policy saving is not blocked, the raw policy text is kept, and the shelter is offered a retry

---

## AC-8: Honest "not auto-evaluated" state

**Given** a natural-language policy cannot be mapped to a supported evaluable rule (e.g. "no small children in the home")
**Then** it is labeled "not auto-evaluated" with an explanation in the settings

**Given** a "not auto-evaluated" policy exists
**Then** it remains visible to adopters as a policy and never affects any verdict

---

## AC-9: Request detail "Policy check" section (shelter)

**Given** a shelter staff member opens an adoption request detail page
**Then** a "Policy check" section shows: a red/yellow/green badge with a text label (never color-only), a summary line, and a rule-by-rule breakdown (label, severity, pass/fail, evidence, source System/Shelter)

**Given** the section is visible
**Then** the copy is advisory (recommendation language), the existing accept/validate/decline actions remain primary, and "Re-run evaluation" plus a link to the shelter's "Automatic evaluation" settings are available

**Given** an evaluation is still in flight
**Then** the section shows a non-blocking "evaluating" state

**Given** no evaluation exists for the request
**Then** the section shows a neutral localized empty state — never an error

---

## AC-10: Individual publisher view (system rules only)

**Given** an individual publisher opens a request detail page (`my/adoption_requests/show`)
**Then** the same "Policy check" section appears, evaluating system rules only

**Given** the publisher's request has an evaluation
**Then** the same badge, summary, and breakdown are shown; no publisher-facing policy settings exist in this feature

---

## AC-11: Triage chip on the shelter request list

**Given** a shelter staff member views the adoption request list
**Then** each request shows a small evaluation chip (red/yellow/green dot + verdict label) alongside, never replacing, the status badge

---

## AC-12: Shelter settings — "Automatic evaluation" management

**Given** a shelter owner/administrator opens Adoption Policies settings
**Then** they see an "Automatic evaluation" area with: natural-language policy input, a translation review list (enable/disable, edit severity/parameters), a "not auto-evaluated" list, and read-only system rules

**Given** the shelter has no policies yet
**Then** an empty state offers "Add a policy" and, once policies exist without translations, "Translate my policies"

---

## AC-13: Notifications and adopter transparency

**Given** a request is evaluated
**Then** no notification is sent to the adopter by the evaluation; the shelter receives the standard "new request" notification as today

**Given** the shelter later declines a request
**Then** the existing decline flow (with reasons) applies unchanged

**Given** an adopter views any surface
**Then** they never see the internal rule-by-rule evaluation breakdown

---

## AC-14: New structured adopter data (age, home, other pets)

**Given** a new adopter completes onboarding
**Then** they answer three new structured questions as part of completing onboarding: date of birth, home environment, and other pets

**Given** an adopter's profile has a date of birth, home environment, or other-pets value
**Then** rules referencing those fields evaluate correctly (age, fenced yard, other pets) and evidence uses derived values (e.g. "25 years old") — never a raw date of birth for shelter display

**Given** an existing adopter completed onboarding before this feature and has not answered the new questions
**Then** they are never blocked from applying; rules referencing the missing fields produce honest "couldn't verify" yellow results, and they see a gentle, non-blocking prompt to complete the fields

**Given** an adopter edits their profile
**Then** the new fields are editable in profile settings

---

## AC-15: Re-run evaluation

**Given** an authorized shelter member triggers "Re-run evaluation"
**Then** the evaluation recomputes against the adopter's current signals and replaces the snapshot

**Given** a re-run produces any verdict
**Then** the request status is never changed

---

## AC-16: Authorization (Pundit)

**Given** an adopter
**Then** they can never view the evaluation breakdown on any request

**Given** a shelter staff member not belonging to the request's shelter, or a non-publisher
**Then** they cannot view the evaluation section or re-run the evaluation

**Given** a shelter staff member (not owner/administrator)
**Then** they cannot manage the shelter's evaluation policies

**Given** a shelter owner/administrator
**Then** they can manage evaluation policies

---

## AC-17: Localization and accessibility

**Given** the locale is English
**Then** all new strings (section, badges, summaries, rule labels/evidence, settings, onboarding questions, notifications, empty states) render in English

**Given** the locale is Spanish
**Then** all new strings render in Spanish

**Given** a verdict badge renders
**Then** it always includes a text label in addition to color, with AA contrast, and no hardcoded user-facing strings exist in views

**Given** a shelter-authored natural-language policy is displayed
**Then** it renders as authored content (not machine-translated)

---

## AC-18: Regression

**Given** the test suite runs
**Then** existing adoption request submit/review/accept/decline/withdraw, notification, timeline, and onboarding specs continue to pass

**And** new specs cover: evaluation verdict aggregation (red/yellow/green), translation happy path + unparseable + provider failure, missing-data → yellow, snapshot persistence, re-run, the new onboarding fields, settings authorization, and Pundit boundaries on the breakdown

**And** tests assert that **no evaluation outcome ever changes request status or notifies the adopter** (all three verdict cases leave the request `pending`)

**And** negative tests assert the adopter-facing rendered output never contains the internal evaluation breakdown