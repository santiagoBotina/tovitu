# Storage Organization Plan

## Problem

Active Storage uses flat random 28-char base36 keys for all file blobs. Pet photos,
shelter logos, and other uploaded images are stored without any folder hierarchy,
making bucket navigation difficult and mixing unrelated assets.

## Goal

Organize all uploaded images into a predictable folder structure:

```
bucket/
  $SHELTER_SLUG/
    pets/
      $PET_SLUG/
        <variant-key-1>
        <variant-key-2>
        ...
    logo/
      <key>
    cover/
      <key>
    profile/
      <key>
    documents/
      <key>
```

Where `$SHELTER_SLUG` is the shelter name parameterized and `$PET_SLUG` is the pet name parameterized.

## Approach

Override the blob key at upload time using `ActiveStorage::Blob.create_and_upload!(key: ...)`
inside the existing service objects. No monkey-patching of `ActiveStorage::Blob#key`.

### Files to Create

- `lib/storage_key_generator.rb` — Key generation utility with methods for each attachment type

### Files to Modify

| File | Change |
|------|--------|
| `app/models/shelter.rb` | Add `has_one_attached :cover_image`, `has_one_attached :profile_picture` |
| `app/controllers/shelters_controller.rb` | Permit `:cover_image, :profile_picture` |
| `lib/pets/photo_manager.rb` | Use custom key when attaching photos |
| `lib/pets/create.rb` | Use custom key when attaching photos |
| `app/presenters/shelter_presenter.rb` | Add `cover_url`, `profile_picture_url` methods |
| `app/views/shelters/edit.html.erb` | Add logo, cover, profile image upload fields |
| `app/views/shelters/new.html.erb` | Add logo upload field |
| `app/views/shelters/show.html.erb` | Display cover, profile, logo images |
| `app/views/shelters/index.html.erb` | Display logo in shelter cards |

### What Won't Change

- Blob ID (`photo_order` stores these, unaffected by key change)
- Presenter URL generation (works via `rails_representation_path` regardless of key)
- Existing photo display in pet profiles and shelter profiles (already works)
- Existing tests (no behavior change, only key format changes)

## Key Generation

```
shelter_slug = shelter.name.parameterize
pet_slug     = pet.name.parameterize

Pet photos:   "#{shelter_slug}/pets/#{pet_slug}/#{SecureRandom.base36(28)}"
Shelter logo: "#{shelter_slug}/logo/#{SecureRandom.base36(28)}"
Cover image:  "#{shelter_slug}/cover/#{SecureRandom.base36(28)}"
Profile pic:  "#{shelter_slug}/profile/#{SecureRandom.base36(28)}"
AI document:  "#{shelter_slug}/documents/#{SecureRandom.base36(28)}"
```

## Edge Cases

- **Pet renamed:** Old photos keep old key prefix. This is acceptable — the blob key is immutable once stored.
- **Shelter renamed:** Same as above. Existing files retain old prefix. The prefix is cosmetic for bucket browsing; retrieval uses the full key regardless.
- **Pet created without name initially:** Use `"unnamed"` as fallback in the prefix. In practice, the form requires a name.
- **Special characters in names:** `parameterize` handles this. No risk of invalid S3 key characters.
- **Direct uploads:** Not yet implemented in this codebase. When added, `create_before_direct_upload!(key:)` should be used similarly.

## Migration

No data migration needed. Existing blobs keep their random keys. Only newly uploaded
files will use the structured prefixes.
