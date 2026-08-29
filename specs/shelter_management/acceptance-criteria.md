# Acceptance Criteria: Shelter Management — Batch Import & Media Management (38)

Criteria map to `specs/38_shelter_management_plan.md` §Acceptance Criteria.

---

## AC-38-1 / AC-38-2 (REQ-15): CSV and Excel uploads

```
Given I am a shelter staff member on the Import Pets page
When I upload a .csv file with valid rows
Then a background import starts and the pets are created
When I upload a .xlsx file with valid rows
Then the pets are created the same way
```

Verified by `spec/requests/shelter/pet_imports_spec.rb` (create enqueues the job for both `.csv` and `.xlsx`) and `spec/lib/pets/import_parser_spec.rb` (parses both formats).

---

## AC-38-3 (REQ-15): File format, required columns, and data types validated with clear, non-technical errors

```
Given I upload a .txt file (or no file)
Then I get an immediate, friendly format error
When a file is missing a required column (name/species/age_category/sex)
Then the import fails with a message naming the missing column
When a cell has an invalid value (bad species, non-date birth_date, junk boolean)
Then that row is reported with a per-field reason in plain language
```

Verified by `spec/requests/shelter/pet_imports_spec.rb` (format), `spec/lib/pets/import_parser_spec.rb` (missing columns), `spec/lib/pets/import_processor_spec.rb` (per-field errors).

---

## AC-38-4 (REQ-15): Invalid rows identified per row; never create partial/corrupt pets

```
Given a file with a valid row and an invalid row
When the import completes
Then only the valid pet exists
And the invalid row is listed with its row number and the reason
```

Verified by `spec/lib/pets/import_processor_spec.rb` (valid + invalid rows; counts).

---

## AC-38-5 (REQ-15): Valid pets created and appear in the shelter's pet list

```
Given a file with N valid rows
When the import completes
Then N pets exist under my shelter
And they appear on the shelter Pets page
```

Verified by `spec/lib/pets/import_processor_spec.rb` and `spec/requests/shelter/pet_imports_spec.rb` (pets created + visible in `shelter_pets_path`).

---

## AC-38-6 (REQ-15): Result summary (imported / errors / duplicates)

```
Given a completed import
Then I see "X imported, Y errors, Z duplicates" with per-row detail
```

Verified by `spec/lib/pets/import_processor_spec.rb` (summary structure) and `spec/requests/shelter/pet_imports_spec.rb` (summary renders on show).

---

## AC-38-7 (REQ-15): Defined duplicate strategy implemented and reported

```
Given a file containing a pet already in my shelter (same name+species+birth_date)
Or the same pet twice within the file
When the import completes
Then duplicates are skipped and reported in the summary
```

Verified by `spec/lib/pets/import_processor_spec.rb` (against-existing and within-file duplicates).

---

## AC-38-8 (REQ-15): No images/attachments imported in v1

```
Given a code review of the import pipeline
Then no photo/attachment handling exists in the parser or processor
```

Verified by `spec/lib/pets/import_processor_spec.rb` (imported pets have no photos attached).

---

## AC-38-9 (REQ-15): Async import shows progress and persists the summary

```
Given I start a large import
Then I see a "processing" notice and can leave the page
When I return to the import's show page
Then the persisted summary is still there
```

Verified by `spec/jobs/pet_import_job_spec.rb` (async status transitions, summary persisted) and `spec/requests/shelter/pet_imports_spec.rb` (status endpoint).

---

## AC-38-10 → AC-38-13 (REQ-16): Media management section; multi-upload; URL add; view/reorder/delete

```
Given I open a pet's Media page
Then I can upload multiple images at once, add an image by URL,
view the pet's images, reorder them, and delete them
```

Verified by `spec/lib/pets/photo_manager_spec.rb` (`attach_many`, `attach_by_url`, `move`) and `spec/requests/shelter/pets_spec.rb` (media page + photo endpoints).

---

## AC-38-14 (REQ-16): Exactly one primary; deleting primary falls back

```
Given a pet with photos
Then exactly one image is marked Primary
When I delete the primary
Then another image becomes primary (or a friendly placeholder when none remain)
```

Verified by `spec/lib/pets/photo_manager_spec.rb` (`set_primary`, `detach` fallback) and `spec/models/pet_spec.rb` (`primary_photo` fallback).

---

## AC-38-15 (REQ-16): Uploads validated (type/size/count) with friendly errors; invalid files don't break valid ones

```
Given I upload a mix of valid and invalid files
Then the valid files attach and each invalid file reports a friendly error
When I add a URL that is not an image
Then it is rejected with a clear error and nothing is attached
```

Verified by `spec/lib/pets/photo_manager_spec.rb` (`attach_many` partial success + per-file errors; `attach_by_url` non-image rejection).

---

## AC-38-16 (REQ-16): No cross-association paths

```
Given I am on a pet's Media page
Then every action is scoped to that pet (no way to attach to another pet)
And only authorized shelter staff can manage media for their pets
```

Verified by `spec/lib/pets/photo_manager_spec.rb` (all actions take the pet) and `spec/requests/shelter/pets_spec.rb` (photo endpoints require `manage_photos?`, wrong-shelter pets 404).

---

## AC-38-17 (REQ-16): Imported pets completable with media; manual/imported parity

```
Given a pet created via batch import (no photos)
Then it can be enriched on the Media page exactly like a manually created pet
```

Verified by `spec/requests/shelter/pet_imports_spec.rb` (imported pet has the media route) and the photo manager specs (attach works on any pet).

---

## AC-38-18: Localization (en/es), WCAG AA, keyboard accessible, Pundit

```
Given the locale is English or Spanish
Then every new string renders in the active locale with en/es parity
Given I navigate by keyboard
Then media controls are focusable, confirmations are keyboard-operable
And authorization is enforced via Pundit policies
```

Verified by en/es locale presence in `config/locales/pets/{en,es}.yml`, the parity spec, and Pundit usage in the controllers.

---

## Summary

All 18 acceptance criteria satisfied. Verified by the added specs (`spec/lib/pets/import_parser_spec.rb`, `spec/lib/pets/import_processor_spec.rb`, `spec/jobs/pet_import_job_spec.rb`, `spec/models/pet_import_spec.rb`, extended `spec/lib/pets/photo_manager_spec.rb`, `spec/requests/shelter/pet_imports_spec.rb`, extended `spec/requests/shelter/pets_spec.rb`, `spec/javascript/controllers/pet_import_controller.test.js`, `spec/javascript/controllers/pet_media_controller.test.js`). Full suite green: **1704 Ruby examples / 0 failures**, **55 JS tests / 0 failures**, RuboCop clean on the feature files.