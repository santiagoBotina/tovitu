# Plan: Pets

**Domain:** Pets
**Priority:** 3 (core listing feature, needed before adoptions)
**Status:** Draft

---

## User Stories

1. As a **shelter staff member**, I want to **add a pet to our shelter** so that adopters can find them.
2. As a **shelter staff member**, I want to **edit a pet's profile** so that information stays up-to-date.
3. As a **shelter staff member**, I want to **upload photos of a pet** so that adopters can see them.
4. As a **shelter staff member**, I want to **mark a pet as adopted** so that the listing is removed from public view.
5. As a **prospective adopter**, I want to **search/filter available pets** so that I can find a pet matching my preferences.
6. As a **prospective adopter**, I want to **view a pet's detailed profile** so that I can learn about their personality and needs.
7. As a **shelter staff member**, I want to **manage a pet's availability status** so that I can control when adopters can apply.

---

## Description

The Pets domain is the heart of Tovitu's public-facing functionality. Shelters list their available animals with detailed profiles including photos, personality descriptions, medical history, and requirements.

For adopters, the pet directory is the primary discovery interface. They can search by species, breed, age, size, and location. Each pet has a rich profile designed to give a comprehensive picture of the animal, reducing mismatches and failed adoptions.

The pet's "requirements" section is especially important — it lists what the pet needs in a home (e.g., no other pets, fenced yard, experienced owner) which feeds into the AI compatibility analysis in Phase 5.

Photo uploads use Active Storage with direct-to-Cloudflare R2 uploads in production (local disk in dev).

---

## Acceptance Criteria

### AC1: Create Pet Listing
```
Given I am logged in as a shelter staff member
When I navigate to the "Add Pet" page
And I fill in: name, species, breed, age, size, sex, description, personality traits, medical notes, requirements
And I upload at least one photo
Then the pet is created and visible on my shelter's pet listing
And the pet is publicly visible (status: available)
And I am redirected to the pet's profile page

Given I am not logged in
When I attempt to access the "Add Pet" page
Then I am redirected to the login page
```

### AC2: Edit Pet Listing
```
Given I am logged in as a shelter staff member for pet's shelter
When I edit the pet's details
Then the changes are saved
And the public profile updates immediately

Given I am a staff member of a different shelter
When I attempt to edit a pet
Then I receive a 403 Forbidden error
```

### AC3: Photo Management
```
Given I am editing a pet
When I upload a photo
Then the photo is attached via Active Storage
And it appears on the pet's profile
And thumbnails are generated for listing views

Given I am editing a pet
When I upload a photo that exceeds 10MB
Then I see a "file too large" error
And the photo is not saved

Given I am editing a pet
When I upload a non-image file type
Then I see a "unsupported file type" error
And the file is not saved
```

### AC4: Pet Status Management
```
Given a pet is listed as "available"
When a staff member marks the pet as "adopted"
Then the pet is removed from public search results
And a "happily adopted!" banner appears on the pet's profile
And any pending adoption applications are marked as "closed"

Given a pet is listed as "available"
When a staff member marks the pet as "on_hold"
Then the pet is hidden from public search
But the profile remains accessible via direct link with "currently on hold" notice

Given a pet is listed as "available"
When a staff member marks the pet as "not_available" (medical, behavioral)
Then the pet is hidden from public view entirely
```

### AC5: Pet Search & Filtering
```
Given I am a visitor on the pets page
When I search for pets
Then I can filter by:
  - Species (dog, cat, other)
  - Breed
  - Age range (baby, young, adult, senior)
  - Size (small, medium, large, giant)
  - Sex
  - Location (city/state)
  - Requirements (good with kids, good with dogs, good with cats, etc.)
And results are paginated (24 per page)

Given I select multiple filters
When the results are displayed
Then all filters are applied conjunctively (AND)

Given a search returns no results
When I see the results page
Then I see a "no pets match your criteria" message
And I am shown suggestions to broaden my search
```

### AC6: Pet Profile (Public)
```
Given I am viewing a pet's profile
Then I see:
  - Photo gallery (primary photo + thumbnails)
  - Name, species, breed, age, size, sex
  - Description/personality write-up
  - Medical history summary
  - Home requirements
  - Shelter name and location
  - "Apply to Adopt" button (leads to adoption application)

Given a pet has no photos
When I view their profile
Then I see a placeholder image with the species icon
```

### AC7: Bulk Operations
```
Given I am a shelter staff member
When I select multiple pets
Then I can mark them as adopted, on hold, or not available in bulk
```

---

## Business Rules

1. **Required fields** — name, species, sex, and at least one photo are required.
2. **Age validation** — `age` is stored as a string category (baby: <1yr, young: 1-3yr, adult: 3-8yr, senior: 8+yr) and an optional exact birth date.
3. **Photo constraints** — max 10 photos per pet, max 10MB per photo, JPEG/PNG/WebP only.
4. **Photo ordering** — first uploaded photo is primary. Staff can reorder.
5. **Species** — initially "dog" and "cat". "Other" for small animals, birds, etc.
6. **Breed** — free text for MVP (not a controlled vocabulary). Enum/dropdown can be added later.
7. **Availability statuses** — `available`, `on_hold` (hidden from search, accessible via link), `adopted` (archived with banner), `not_available` (hidden entirely), `removed` (soft-delete).
8. **Version history** — log significant changes (status changes, price changes) for audit.
9. **Mature content** — if a pet has medical photos (wounds, surgery), they should be behind a "show medical photos" toggle. Optional for MVP.
10. **Deletion** — pets can be soft-deleted. Hard-delete after 30 days via cleanup job.

---

## User Flow

### Add Pet Flow
1. Staff logs in → navigates to shelter dashboard → clicks "Add Pet"
2. Staff fills in pet details form (species-specific fields show/hide dynamically)
3. Staff uploads photos (drag-and-drop or file picker, with preview)
4. Staff reviews and submits
5. System validates → creates pet → sets status = "available"
6. Pet appears in public directory immediately
7. Staff is redirected to pet profile with a "share this pet" link

### Search & Discovery Flow
1. Visitor lands on `/pets` (or shelter-specific `/shelters/:id/pets`)
2. Visitor sees default results (recently added, available pets)
3. Visitor applies filters → results update via Turbo (no full page reload)
4. Visitor clicks a pet → sees full profile
5. Visitor clicks "Apply to Adopt" → redirected to adoption application (Phase 4)

---

## Edge Cases & Error States

| Edge Case | Handling |
|-----------|----------|
| Upload fails (network error) | Show error, preserve form data, allow retry |
| Photo exceeds max dimensions | Resize server-side or reject with message |
| Duplicate pet listing | Staff can mark as duplicate; warns about existing similar listings |
| Pet name contains profanity | Basic server-side profanity filter (optional for MVP) |
| Pet has no breed (mixed breed) | Allow "Mixed Breed" as text entry |
| Age is 0 (newborn) | Accept; category = "baby" |
| Photo fails virus scan | Auto-reject upload |
| User navigates away during upload | Next time they edit, show "you have unsaved uploads" (nice-to-have) |
| Pet adopted and brought back (returned) | Staff changes status from "adopted" back to "available"; adoption history preserved |
| Search with special characters | Sanitize input, use ILIKE for text search |

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Pets listed per shelter | > 10 average within first month |
| Pet profile completion rate | > 90% (name + photo + description) |
| Photo uploads per pet | > 3 average |
| Search-to-profile click rate | > 40% |
| Profile-to-application start rate | > 15% |
| Time from listing to adoption application | < 30 days median |

---

## Dependencies / Prerequisites

- Shelters (Phase 2) — pets belong to a shelter
- Authentication (Phase 1) — staff must be logged in to manage pets
- Active Storage — for photo uploads (already configured)
- Image processing gem (mini_magick or image_processing/vips) — for thumbnails

---

## Open Questions / Risks

1. **Breed controlled vocabulary?** Free text is simpler for MVP but creates inconsistent data. Risk: "Pit Bull", "Pitbull", "American Pit Bull Terrier" are the same. Consider a breed list for dogs/cats in Phase 2.
2. **Video uploads?** Not in MVP. Videos are large and expensive to store. Consider YouTube embed instead.
3. **Pedigree / registration papers?** Not in MVP (focus on shelter/rescue pets, not breeders).
4. **Medical records upload?** MVP: text summary only. File upload for vet records can be added later.
5. **QR code generation for pet profiles?** Nice-to-have for shelters to print and display at adoption events.
6. **Geocoding for location sort?** Not in MVP. Search by shelter city is sufficient.
7. **Inappropriate content flagging?** Allow shelters to report inappropriate pet listings. Manual review process for MVP.

---

## Technical Notes

### Models
```
Pet
  - shelter_id (bigint, not null)
  - name (string, not null)
  - species (string, not null) — dog | cat | other
  - breed (string, nullable)
  - age_category (string, not null) — baby | young | adult | senior
  - birth_date (date, nullable)
  - size (string, nullable) — small | medium | large | giant
  - sex (string, not null) — male | female | unknown
  - description (text, nullable)
  - personality_traits (jsonb, default: []) — ["friendly", "energetic", "cuddly", "independent", ...]
  - medical_notes (text, nullable)
  - spayed_neutered (boolean, default: false)
  - vaccinated (boolean, default: false)
  - special_needs (boolean, default: false)
  - good_with_children (boolean, nullable)
  - good_with_dogs (boolean, nullable)
  - good_with_cats (boolean, nullable)
  - requirements (text, nullable) — free text description of home requirements
  - status (string, default: "available") — available | on_hold | adopted | not_available | removed
  - adopted_at (datetime, nullable)
  - discarded_at (datetime, nullable)
```

### Photo Attachment
```
Pet has_many_attached :photos
- Variants: thumb (150x150), medium (400x400), large (1200x1200)
```

### Service Objects
- `Pets::Create` — creates pet with photo attachments
- `Pets::Update` — updates pet details
- `Pets::ChangeStatus` — transitions pet status with validation
- `Pets::Search` — query object for filtering and pagination
- `Pets::BulkUpdate` — bulk status changes
- `Pets::PhotoManager` — handles photo ordering, deletion, primary selection

### Controllers
- `PetsController` — public index/show
- `Shelters::PetsController` — scoped CRUD under shelter namespace
- `Pets::PhotosController` — photo management (nested under pet)

### Routes
```
resources :pets, only: [:index, :show]  # public

namespace :shelter do
  resources :pets do                    # staff CRUD
    resources :photos, only: [:create, :destroy, :update]  # reorder
  end
end
```

### Testing Notes
- Test photo upload with valid/invalid file types
- Test image variant generation
- Test pet search with multiple filter combinations
- Test that pets with different statuses have correct visibility
- Test authorization — staff from shelter A cannot edit shelter B's pets
- Test bulk operations
