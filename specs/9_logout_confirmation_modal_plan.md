# Plan: Custom Logout Confirmation Modal

**Domain:** UI, Authentication
**Priority:** 2 (improves existing UX)
**Status:** Draft
**Timestamp:** 2026-06-24

---

## Overview

Replace the native browser `alert()` / `confirm()` dialog used for logout confirmation with a beautiful, accessible, Tailwind-styled modal component. The solution hooks into Turbo's built-in confirmation mechanism so that **all** `data-turbo-confirm` interactions across the app benefit from the same custom modal.

Currently, clicking "Sign out" triggers `window.confirm()` via Turbo's default behavior. This replacement delivers a branded, on-brand experience consistent with Tovitu's design system.

---

## Current State

### Sign-out link (`app/views/shared/_sidebar.html.erb`, line 101-110)

```erb
<%= link_to session_path,
    data: { turbo_method: :delete, turbo_confirm: t("shared.sidebar.sign_out_confirm") },
    class: "#{base_link} text-neutral-500 hover:bg-danger/5 hover:text-danger transition-colors duration-150" do %>
  <!-- SVG icon + "Sign out" label -->
<% end %>
```

- `turbo_confirm` invokes Turbo's default `window.confirm()` dialog
- When confirmed, Turbo sends a DELETE request to `session_path`
- `Authentication::SessionsController#destroy` calls `reset_session` and redirects

### Other `turbo_confirm` usages (will also benefit)

| File | Purpose |
|------|---------|
| `app/views/shelter/pets/show.html.erb` | Delete pet |
| `app/views/shelter/pets/index.html.erb` | Delete pet from table |
| `app/views/shelter/pets/show.html.erb` | Delete pet photo |
| `app/views/shelters/staff/index.html.erb` | Remove staff member |

### How Turbo.confirm works

Turbo's default confirm method is a synchronous `window.confirm()` call. Turbo provides `Turbo.setConfirmMethod(asyncFunction)` to override it. The replacement function receives the confirmation message and the form element (or link element in the case of `link_to`), and **must resolve to `true` or `false`** to proceed or cancel.

---

## Requirements

### Functional

1. When a user clicks "Sign out" (or any element with `data-turbo-confirm`), a branded modal appears instead of the native `confirm()` dialog.
2. The modal displays:
   - A clear confirmation message (from i18n)
   - A "Cancel" button to dismiss and abort the action
   - A "Sign out" / confirm button (styled in `danger` color) to proceed
3. The modal must be dismissible by:
   - Clicking the "Cancel" button
   - Clicking the backdrop/overlay outside the modal
   - Pressing the `Escape` key
4. Upon confirmation, the Turbo DELETE request proceeds as normal.
5. The sign-out action itself (`SessionsController#destroy`) remains unchanged.

### Non-functional / Quality

6. **Accessibility:**
   - Focus is trapped inside the modal when open
   - Focus returns to the triggering element when dismissed
   - `aria-modal="true"`, `role="dialog"`, `aria-labelledby` attributes present
   - Escape key closes the modal
   - Clicking backdrop closes the modal
7. **Animation:** The modal fades in with a backdrop blur; the modal panel scales in gently.
8. **Responsive:** Works on mobile (full-width modal with padding) and desktop (centered modal with max-width).
9. **i18n:** All user-facing modal strings come from `config/locales/*.yml`.
10. **Reusable:** The solution uses `Turbo.setConfirmMethod()` so it works for **all** `turbo_confirm` usages automatically.

---

## Proposed Approach

### Architecture

Use a **Stimulus controller** (`confirm_modal_controller.js`) that is instantiated once on the page body. On `connect()`, it overrides `Turbo.setConfirmMethod()` with a custom async function. The controller manages a single modal instance (rendered as HTML in the controller's template) — showing/hiding it and resolving/rejecting the promise.

The modal markup is rendered directly by the Stimulus controller (as an HTML template string appended to the body), keeping it framework-free and avoiding extra partials or components.

### Step-by-step Implementation

#### 1. Create `app/javascript/controllers/confirm_modal_controller.js`

A Stimulus controller that:

- On `connect()` — calls `Turbo.setConfirmMethod()` with a custom async function
- The async function returns a Promise that resolves to `true` or `false`
- Builds the modal DOM, appends to body, manages animations
- Handles confirm/cancel/escape/backdrop-click
- Traps focus inside the modal
- Detects destructive actions via CSS class matching

#### 2. Wire it into the application layout

Add `data-controller="confirm-modal"` to the `<body>` tag in `app/views/layouts/application.html.erb`:

```erb
<body class="font-sans bg-neutral-50 text-neutral-800 antialiased min-h-screen"
      data-controller="sidebar confirm-modal">
```

This single controller instance handles **all** `data-turbo-confirm` interactions across the app.

#### 3. Configure default button text via i18n

Add to `app/views/layouts/application.html.erb`:
```erb
<body ...
      data-controller="sidebar confirm-modal"
      data-confirm-modal-confirm-text-value="<%= t('shared.confirm_modal.confirm') %>"
      data-confirm-modal-cancel-text-value="<%= t('shared.confirm_modal.cancel') %>">
```

#### 4. Add i18n strings

**`config/locales/en.yml`**:
```yaml
shared:
  confirm_modal:
    confirm: "Sign out"
    cancel: "Cancel"
```

**`config/locales/es.yml`**:
```yaml
shared:
  confirm_modal:
    confirm: "Cerrar sesión"
    cancel: "Cancelar"
```

#### 5. No changes needed to sidebar

The `turbo_confirm` attribute remains — Turbo routes through the custom method automatically.

#### 6. Verify all existing `turbo_confirm` usages

The custom modal automatically applies to pet deletion, pet photo deletion, and staff removal. Each shows the danger-styled variant.

---

## UI/UX Considerations

### Visual Design

| Element | Styling |
|---------|---------|
| Backdrop | `bg-black/40 backdrop-blur-sm` |
| Panel container | `bg-white rounded-2xl shadow-2xl p-6 max-w-sm w-full` |
| Icon circle | `w-12 h-12 rounded-full bg-danger/10` (danger) or `bg-primary-50` (info) |
| Icon | `w-6 h-6 text-danger` or `text-primary-500` |
| Title (message) | `text-lg font-semibold text-neutral-800 text-center` |
| Subtitle | `text-sm text-neutral-500 text-center` |
| Cancel button | `bg-neutral-100 text-neutral-600 hover:bg-neutral-200` |
| Confirm button | `bg-danger hover:bg-red-600 text-white` (destructive) |

### Animation

- **Enter:** Backdrop fades in (opacity 0 → 1, 200ms ease-out). Panel scales in (scale-95 → scale-100, 200ms ease-out).
- **Exit:** Reverse animation with 200ms, then DOM removal.
- CSS transitions only — no JS animation library needed.

### Accessibility Checklist

- [ ] `role="dialog"` and `aria-modal="true"` on backdrop wrapper
- [ ] `aria-labelledby` pointing to the title element
- [ ] Focus trap: first focusable element (Cancel button) receives focus on open
- [ ] Escape key closes modal
- [ ] Backdrop click closes modal
- [ ] Focus returns to trigger element on dismiss
- [ ] `overflow-hidden` on `<body>` to prevent background scrolling

### Responsive

- Modal panel uses `max-w-sm` with `p-4` body padding — works on mobile and desktop.
- Buttons stack full-width via `flex-1`.

---

## Risks & Unknowns

1. **`Turbo.setConfirmMethod` with `link_to`:** Need to verify class-based danger detection works for anchor tags. The sign-out link has `hover:bg-danger/5 hover:text-danger` classes.
2. **Multiple rapid clicks:** Guard against stacking promises — check if modal already open.
3. **Turbo Drive navigation while modal is open:** Listen for `turbo:before-visit` to auto-dismiss.
4. **Testing:** Async Promise-based confirm is harder to test. System tests need to assert modal presence and click custom buttons.
5. **Longer confirmation messages:** Some existing usages have dynamic messages (e.g., "Are you sure you want to remove %{name}?"). Test gracefully.

---

## Acceptance Criteria

### Must Have

1. [ ] Clicking "Sign out" does **not** trigger native `window.confirm()`.
2. [ ] A styled modal appears with the message from `t("shared.sidebar.sign_out_confirm")`.
3. [ ] "Cancel" button dismisses the modal without signing out.
4. [ ] "Sign out" (confirm) button is styled in red/danger and signs the user out.
5. [ ] Clicking backdrop dismisses the modal without signing out.
6. [ ] Pressing `Escape` dismisses the modal without signing out.
7. [ ] Focus is trapped inside the modal when open.
8. [ ] Focus returns to the "Sign out" link when modal is dismissed.
9. [ ] Sign-out action works exactly as before (DELETE, `reset_session`, redirect).
10. [ ] Modal is animated (fade + scale on enter/exit).

### Should Have

11. [ ] All other `data-turbo-confirm` interactions (pet deletion, staff removal) also use the custom modal.
12. [ ] Destructive actions show the "danger" variant (red icon, red confirm button).
13. [ ] Non-destructive confirmations show a neutral/info variant.

### Nice to Have

14. [ ] Modal auto-closes if user navigates away via Turbo Drive.
15. [ ] System tests exist for the confirm/cancel flow.

---

## File Change Summary

### New Files

| File | Purpose |
|------|---------|
| `app/javascript/controllers/confirm_modal_controller.js` | Stimulus controller — overrides Turbo's confirm, renders modal |

### Modified Files

| File | Change |
|------|--------|
| `app/views/layouts/application.html.erb` | Add `data-controller="confirm-modal"` + i18n data values |
| `config/locales/en.yml` | Add `shared.confirm_modal` keys |
| `config/locales/es.yml` | Add Spanish `shared.confirm_modal` keys |

### Unchanged Files

| File | Reason |
|------|--------|
| `app/views/shared/_sidebar.html.erb` | `turbo_confirm` attribute remains — custom handler intercepts |
| `app/controllers/authentication/sessions_controller.rb` | No business logic changes |
| `config/routes.rb` | No route changes |

---

## Future Considerations

- **Extend to `button_to` with `data-turbo-confirm`:** Already handled since `Turbo.setConfirmMethod` is global.
- **Support for extra confirmation context:** Checkbox ("Don't ask again") or text input ("Type DELETE").
- **ViewComponent extraction:** If the app adopts ViewComponent later, extract the modal markup.
