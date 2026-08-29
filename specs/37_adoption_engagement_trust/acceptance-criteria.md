# Acceptance Criteria: Adoption Engagement & Trust (37)

All criteria from `specs/37_adoption_engagement_trust_plan.md` §Acceptance Criteria.

---

## AC-37-1: Journey card has a Tovitu-related background

```
Given I am an individual user on my dashboard
When I view the Adoption Journey card
Then it uses a full brand-color surface tint (primary-50 gradient)
And text on the card retains WCAG AA contrast (headings neutral-800, body neutral-700+)
```

Verified by `spec/requests/dashboard_gamification_spec.rb` (gradient/primary surface classes present).

---

## AC-37-2: Journey card explains what the journey is

```
Given I view the Adoption Journey card
Then I see one brief sentence explaining what the Adoption Journey is
And the sentence is localized per my state (fresh / mid-journey / active applicant)
```

Verified by `spec/requests/dashboard_gamification_spec.rb` (explanation keys render).

---

## AC-37-3: Journey card shows achieved milestones

```
Given I view the Adoption Journey card
Then I see "X of Y milestones reached"
And I see compact milestone chips reflecting done/locked state
```

Verified by `spec/requests/dashboard_gamification_spec.rb`.

---

## AC-37-4: Journey card names the next step

```
Given I view the Adoption Journey card
Then I see a concrete "Next:" line (e.g. "Next: Complete your profile…")
```

Verified by `spec/requests/dashboard_gamification_spec.rb` (existing `next_step_key` keys).

---

## AC-37-5: Journey card has at least one clear CTA

```
Given I view the Adoption Journey card
Then I see a primary CTA button whose label and destination match my state
    (fresh → Complete your profile; mid-journey → Browse pets; active applicant → See your requests)
```

Verified by `spec/requests/dashboard_gamification_spec.rb`.

---

## AC-37-6: Card content adapts to user state

```
Given I am a fresh user (no onboarding, no saved pets, no requests)
Then the variant is fresh (journey explanation + complete-profile CTA)

Given I have completed onboarding and saved pets but have no active request
Then the variant is mid-journey (progress celebrated + browse-pets CTA)

Given I have an active request (pending/in_validation)
Then the variant is active_applicant (awaiting-shelter context + see-requests CTA)
```

Verified by `spec/lib/gamification/journey_spec.rb` (#card_variant) and request specs.

---

## AC-37-7: No excessive gamification

```
Given I view the journey card
Then no points, levels, or leaderboards appear anywhere on the card
And progress remains personal (milestones, not scores)
```

Verified by `spec/requests/dashboard_gamification_spec.rb` (no points/levels/leaderboard strings).

---

## AC-37-8: Accompaniment communicated

```
Given I view the journey card
Then I see an accompaniment line ("Tovitu is with you at every step")
Without being cloying or game-like
```

Verified by `spec/requests/dashboard_gamification_spec.rb`.

---

## AC-37-9: "Incoming requests" renamed for individuals

```
Given I am an individual user (adopter or publisher)
Then the navigation item reads "Requests for my pets" (not "Incoming Requests")
And the my/adoption_requests page title/subtitle match that wording
```

Verified by `spec/requests/dashboard_gamification_spec.rb` + `spec/requests/my/adoption_requests_spec.rb`.

---

## AC-37-10: Individual adopter cannot mistake the section

```
Given I am an individual who has never published a pet
Then the section is either hidden or shows an explanatory empty state
And the empty state clarifies requests appear "when you publish a pet for adoption"
And an adopter cannot read the item as "requests I sent"
```

Verified by `spec/requests/my/adoption_requests_spec.rb` (empty-state copy).

---

## AC-37-11: Consistent terminology

```
Given an individual user views the app
Then the sidebar, dashboard card, empty state, and page title use the same
    "Requests for my pets" vocabulary
```

Verified by request specs across dashboard + my/adoption_requests.

---

## AC-37-12: App does not assume individuals are shelters

```
Given an individual user who publishes a pet
Then the app labels the role as publisher/individual ("Requests for my pets")
And never presents the individual as a shelter organization
And shelter staff keep their genuine "Adoptions" vocabulary
```

Verified by sidebar spec (shelter sidebar unchanged) + REQ-13 copy specs.

---

## AC-37-13: Shelters/publishers can provide a recommendation

```
Given I am a shelter staff member or an individual publisher
Then I can enter a recommendation for a pet in the pet form
And it is saved with the pet
```

Verified by `spec/requests/pet_recommendation_spec.rb` + form presence.

---

## AC-37-14: Recommendation renders with "shelter says" framing

```
Given a pet has a recommendation
When I view its public profile
Then I see a section headed "What the shelter says about %{name}"
     (or "What %{publisher} says about %{name}" for individual-listed pets)
And the author is named
```

Verified by `spec/requests/pet_recommendation_spec.rb`.

---

## AC-37-15: No recommendation → section hidden

```
Given a pet has no recommendation (or whitespace-only)
Then the recommendation section does not render on the profile
```

Verified by `spec/requests/pet_recommendation_spec.rb`.

---

## AC-37-16: Content is pet-scoped

```
Given a recommendation exists for pet A
Then it only appears on pet A's profile
And editing pet A's recommendation does not affect any other pet
```

Verified by `spec/models/pet_spec.rb` + request spec (per-pet column).

---

## AC-37-17: Malicious/inappropriate content blocked

```
Given a shelter submits <script>alert('xss')</script> or <img onerror=...> or javascript: links
When the pet is saved and its profile is rendered
Then the stored value is plain text with all tags stripped
And the rendered body contains no executable HTML (verified by test)
And nothing executes

Given a shelter submits profanity
Then the pet is not saved and a friendly validation error is shown
```

Verified by `spec/lib/pets/recommendation_spec.rb` + `spec/requests/pet_recommendation_spec.rb`.

---

## AC-37-18: Shelter content visually differentiated from AI content

```
Given a pet profile with both a recommendation and an AI Life Preview
Then the recommendation section has distinct visual treatment (primary tint, author line)
And does NOT carry the AI badge used by the Life Preview
```

Verified by `spec/requests/pet_recommendation_spec.rb`.

---

## AC-37-19: i18n + accessibility

```
Given the locale is English or Spanish
Then every new string renders in the active locale (en/es parity)
And the journey card + recommendation section are keyboard accessible
And WCAG AA contrast is preserved (primary-50 surfaces with neutral-800 headings)
```

Verified by en/es key presence and rendering specs.

---

## Summary

All acceptance criteria implemented and verified by the spec suite.