# Acceptance Criteria: Adopter Personality Analysis (Phase 1)

## AC1: Adopter Insight Card on request review
```
Given I am a shelter staff member viewing an adoption request (pending or in_validation)
When the page loads
Then I see an "Adopter Insight" card in the adopter section
And the card shows an archetype badge, fit indicators, commitment signals,
    a pet-fit summary, suggested verification questions, and a confidence/provenance footer
And the card is labeled as AI-generated and advisory
And no PII beyond what is already shown today is exposed (no raw event logs, no extra contact info)

Given I am an individual publisher viewing a request for my pet
Then I see the same Adopter Insight card (shared component/partial)
```

## AC2: Zero new adopter friction (Phase 1)
```
Given an adopter submits a request
Then they encounter no new required fields, no new steps, and no new pages
And they see only a one-line transparency note
```

## AC3: Insight generation pipeline (Phase 1)
```
Given a new adoption request is submitted
When the request is created
Then a background job generates the Adopter Insight Profile (if not fresh) and the Pet-Fit Summary asynchronously
And the card appears when ready (progressive load, no blocking)
And generation failure does not block the request or the review page (fallback to today's static summary)

Given a signal changes (new saved pet, new request, onboarding completed)
When the insight is stale or older than the refresh threshold
Then it is regenerated asynchronously (deduped, no duplicate jobs)
```

## AC4: Insufficient data honesty
```
Given an adopter has very few signals (e.g., just completed onboarding, no activity)
Then the card shows only what is supported by evidence
And low-confidence sections display "Not enough activity yet" instead of fabricated conclusions
And overall confidence is labeled Low
And no AI claim is made about areas with no evidence
```

## AC5: Self-report vs. behavior handled correctly
```
Given the AI-derived archetype differs from the adopter's self-reported personality
Then the card shows both, labeled "How they describe themselves" and "What their activity suggests"
And it is phrased as "worth confirming", never as a contradiction or accusation
```

## AC7 (Phase 1 portion): No PII in analysis
```
Given a request is submitted
Then no AI prompt ever contains the adopter's name, email, phone, or exact address (asserted by test)
```

## Edge cases
- Brand-new adopter with no behavior → partial card, Low confidence, "not enough activity yet" states.
- AI provider down/timeout → job retries with backoff; review page never blocks; card shows fallback state.
- Malformed AI output → service returns failure; job raises and retries; persistent failure logs and card falls back.
- Adopter applies to many pets at once → commitment signals synthesized non-judgmentally.
- Self-report contradicts behavior → both labels shown, phrased as "worth confirming".
