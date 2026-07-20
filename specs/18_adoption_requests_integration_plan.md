# Plan: Adoption Requests Integration — Notifications, WhatsApp, Forms & Full Workflow

**Domain:** Adoptions
**Priority:** 1 (unblocks core adoption workflow)
**Status:** Draft
**Date:** 2026-07-20
**Supersedes:** `13_adoptions_plan.md` (extends with notifications, messaging, and enhanced UX)

---

## Overview

The adoption request workflow exists but is **not fully integrated** between shelters and adopters. The critical gaps are:

1. **No in-app notification system** — the bell icon is a static UI element. Users are only notified via email, which means they must leave the platform to know what's happening.
2. **No WhatsApp integration** — despite being a stated WhatsApp-first approach, the `Messaging::*` services all raise `NotImplementedError`.
3. **No rich form filling** — adopters currently submit requests using only their onboarding profile data with no additional context or questionnaire.
4. **No conversation layer** — shelters can't communicate with adopters beyond status changes and decline reasons.
5. **No withdrawal or "request more info" flows** — adopters can't cancel their own requests; shelters can't ask follow-up questions.
6. **Individual publisher flow is basic** — the `My::AdoptionRequests::DecisionsController` exists but has no decline reason collection and minimal UI.

This plan covers **all** of these gaps. It's designed to make the adoption section **useful, integrated, and communication-rich** while keeping the WhatsApp-first principle central.

---

## 1. Guiding Principles

1. **WhatsApp-first, email-second, in-app-always** — Notifications should reach the user where they are. In-app is always delivered. WhatsApp is preferred for shelter/adopter communication. Email is the fallback/confirmation channel.
2. **Notification preferences are per-user** — Each user controls how they get notified (in-app only, email, WhatsApp, or all three).
3. **Conversations live alongside requests** — Every adoption request has an associated conversation/message thread.
4. **Forms are dynamic, not static** — Shelters/individuals can configure what additional information they want from adopters at request time.
5. **Audit trail is non-negotiable** — Every status change, notification, and message is logged.
6. **Privacy-first** — Contact info is only shared when explicitly needed for the adoption to proceed.

---

## 2. Scope & Phasing

### Phase 1 — Foundation (P0, Must Have)
| Feature | Area |
|---------|------|
| In-app notification system (model, service, UI) | Notifications |
| Notification bell with real badge counts | Frontend + Notifications |
| Notification preferences per user | Settings |
| Adopter can withdraw their own request | Adoptions |
| Shelter/individual can "request more info" (status: needs_info) | Adoptions |
| WhatsApp Business API provider implementation | Messaging |
| WhatsApp notification delivery for all status changes | Messaging + Adoptions |
| Enhanced email templates with rich content | Mailers |
| Fillable adoption form with additional questions | Adoptions |

### Phase 2 — Communication (P1, Should Have)
| Feature | Area |
|---------|------|
| Request-scoped conversation/chat | Messaging + Adoptions |
| WhatsApp webhook handling + two-way conversation | Messaging |
| ActionCable real-time updates | Frontend |
| Notification center / history page | Notifications |
| Mark notifications as read / mark all read | Notifications |
| Shelter dashboard rich activity feed | Dashboard |
| Bulk notification read | Notifications |

### Phase 3 — Advanced (P2, Nice to Have)
| Feature | Area |
|---------|------|
| Notification snoozing / quiet hours | Notifications |
| Scheduled WhatsApp message templates | Messaging |
| Adoption request expiry / auto-decline | Adoptions |
| AI-suggested reply drafts for shelters | AI + Messaging |
| Read receipts for notifications | Notifications |
| Multi-language notification content | i18n |

---

## 3. Detailed Specifications

### 3.1 In-App Notification System

#### Model: `Notification`

```ruby
# app/models/notification.rb
class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :notifiable, polymorphic: true  # e.g., AdoptionRequest
  belongs_to :actor, class_name: "User", optional: true  # who triggered it

  enum :kind, {
    request_submitted: "request_submitted",
    request_in_validation: "request_in_validation",
    request_accepted: "request_accepted",
    request_declined: "request_declined",
    request_withdrawn: "request_withdrawn",
    info_requested: "info_requested",
    info_received: "info_received",
    message_received: "message_received",
    pet_status_changed: "pet_status_changed",
    welcome: "welcome"
  }

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
end
```

**Migration (notifications table):**
```ruby
create_table :notifications do |t|
  t.references :recipient, null: false, foreign_key: { to_table: :users }
  t.references :actor, foreign_key: { to_table: :users }
  t.references :notifiable, polymorphic: true, null: false
  t.string :kind, null: false
  t.string :title, null: false        # Short, e.g., "Request Accepted!"
  t.text :body                         # Longer description
  t.jsonb :metadata, default: {}       # Extra data (pet name, shelter name, etc.)
  t.datetime :read_at
  t.datetime :actionable_until         # When the notification expires/becomes stale
  t.string :action_url                 # Deep link to the relevant page
  t.datetime :created_at, null: false
  t.datetime :updated_at, null: false

  t.index [:recipient_id, :read_at, :created_at], name: "idx_notifications_unread"
  t.index [:notifiable_type, :notifiable_id]
end
```

#### Service Objects

**`Notifications::Deliver`** — The central dispatch service. Called by adoption services instead of directly mailing.

```ruby
Notifications::Deliver.call(
  recipient: user,
  actor: current_user,
  kind: :request_accepted,
  notifiable: adoption_request,
  title: I18n.t("notifications.request_accepted.title", pet_name: pet.name),
  body: I18n.t("notifications.request_accepted.body", shelter_name: shelter.name),
  action_url: Rails.application.routes.url_helpers.adoption_request_path(adoption_request, locale: user.locale),
  metadata: { pet_name: pet.name, shelter_name: shelter.name }
)
```

This service will:
1. Create the `Notification` record in the database
2. Check the user's notification preferences
3. If `in_app`: create the record (always happens)
4. If `email`: queue `NotificationMailer` delivery
5. If `whatsapp`: queue `Messaging::SendMessage` delivery
6. Broadcast via ActionCable (Phase 2) for real-time UI update

**`Notifications::MarkAsRead`** — Mark one or all notifications as read.

**`Notifications::GetUnreadCount`** — Returns count for badge display.

**`Notifications::Preference`** — Store delivery preferences per user.

```ruby
# app/models/notification_preference.rb (or jsonb on User)
create_table :notification_preferences do |t|
  t.references :user, null: false, foreign_key: true
  t.boolean :in_app, default: true
  t.boolean :email, default: true
  t.boolean :whatsapp, default: false   # opt-in required
  t.string :whatsapp_phone               # verified phone number
  t.datetime :whatsapp_verified_at
  t.jsonb :per_kind_overrides, default: {}  # e.g., { "message_received": { "email": false } }
end
```

**Design Decision:** Notification preferences are stored in a separate model rather than as a jsonb column on User, to keep the User model clean and allow for future expansion (per-kind overrides, quiet hours, etc.).

#### UI Components

**NotificationBell (Stimulus controller):**
- Polls `/notifications/unread_count` (or via Turbo Stream in Phase 2)
- Shows badge with unread count
- Click opens a dropdown with last 5 notifications
- "Mark all as read" action
- "View all" link to `/notifications`

**NotificationCenter page (`/notifications`):**
- Paginated list of all notifications
- Filter by kind (requests, messages, system)
- Group by date (Today, Yesterday, This Week, Older)
- Click navigates to action_url
- Bulk read/mark actions

**Toast notifications for real-time:**
- When a notification arrives while user is on the page (ActionCable Phase 2)
- Show a brief toast with the notification title + deep link

---

### 3.2 WhatsApp Messaging Integration

#### Provider Architecture (refining existing stubs)

The current `lib/messaging/` has the right abstraction but no implementation. We need to:

1. **Create `Messaging::WhatsAppProvider`** — concrete implementation using WhatsApp Business Cloud API
2. **Create `Messaging::Templates`** — notification templates registered with WhatsApp
3. **Create `Messaging::WebhookHandler`** — process incoming WhatsApp messages
4. **Create `Messaging::OptInManager`** — handle opt-in flow and phone verification

#### WhatsApp Business API Setup

```ruby
module Messaging
  class WhatsAppProvider < BaseProvider
    API_VERSION = "v21.0"
    BASE_URL = "https://graph.facebook.com/#{API_VERSION}"

    def initialize(phone_number_id:, access_token:)
      @phone_number_id = phone_number_id
      @access_token = access_token
    end

    def send_message(to:, content:)
      # Handles both template messages (for notifications) and free-form messages (for chat)
      # Uses WhatsApp Cloud API /messages endpoint
    end

    def send_template(to:, template_name:, parameters:)
      # Sends a pre-approved WhatsApp template message
      # Template names: "adoption_request_received", "request_accepted", "request_declined", etc.
    end

    def parse_webhook(payload)
      # Parses the incoming webhook payload
      # Returns a normalized message structure
    end
  end
end
```

#### Templates to Register with WhatsApp Business API

| Template Name | Trigger | Parameters |
|---------------|---------|------------|
| `adoption_request_received` | New request submitted | `{{pet_name}}`, `{{shelter_name}}` |
| `request_in_validation` | Status → in_validation | `{{pet_name}}`, `{{shelter_name}}` |
| `request_accepted` | Status → accepted | `{{pet_name}}`, `{{shelter_name}}` |
| `request_declined` | Status → declined | `{{pet_name}}`, `{{reason}}` |
| `info_requested` | Shelter requests more info | `{{pet_name}}`, `{{shelter_name}}` |
| `request_withdrawn` | Adopter withdraws | `{{pet_name}}`, `{{adopter_name}}` |
| `new_message` | New message in conversation | `{{sender_name}}`, `{{preview}}` |
| `opt_in_confirmation` | User opts into WhatsApp | `{{code}}` |
| `adoption_reminder` | Follow-up after X days | `{{pet_name}}`, `{{shelter_name}}` |

#### Webhook Flow

```
1. WhatsApp sends POST to /webhooks/whatsapp
2. Messaging::WebhookHandler.parse(payload)
3. Identify the user by phone number (look up NotificationPreference)
4. If it's a reply to a notification → route to conversation thread
5. If it's a new conversation → determine intent (support, adoption inquiry, etc.)
6. Respond appropriately
```

#### WhatsApp Opt-In Flow

```
1. User goes to Settings → Notifications → WhatsApp
2. User enters phone number
3. System sends verification code via WhatsApp template
4. User enters code in app
5. Phone is verified → WhatsApp delivery enabled
6. Compliance: Store opt-in timestamp, provide opt-out mechanism
```

**Important:** WhatsApp Business API requires:
- Business Verification
- Phone number approval
- Template message approval (24-48h per template)
- Opt-in management (cannot message users who haven't opted in)
- 24-hour free-form messaging window (after a user messages you)

#### Messaging Service Objects (updating existing stubs)

**`Messaging::SendMessage`** — Update to:
- Accept `channel:` parameter (:whatsapp, :email, :in_app)
- Dispatch to appropriate provider
- Log delivery in `Notification` record (via metadata)

**`Messaging::StartConversation`** — Implement to:
- Create a conversation record for an adoption request
- Enable two-way messaging between shelter and adopter
- Store messages in a `conversation_messages` table

```ruby
# app/models/conversation.rb
class Conversation < ApplicationRecord
  belongs_to :adoption_request
  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"
  has_many :messages, dependent: :destroy

  scope :unread, ->(user) { where.not(recipient: user).joins(:messages).where(messages: { read_at: nil }) }
end

# app/models/conversation_message.rb
class ConversationMessage < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: "User"

  validates :body, presence: true

  scope :chronological, -> { order(created_at: :asc) }
end
```

---

### 3.3 Enhanced Form Filling

#### Current Problem
The adopter's onboarding profile is used as-is. There's no way for:
- The adopter to add context about why they're interested in THIS specific pet
- The shelter/individual to ask specific questions at request time
- The adopter to update their profile before making a request

#### Solution: Request Form with Optional Additional Questions

**Flow change:**
```
Current:
  Pet Profile → [Request to Adopt] → Confirmation (profile summary) → Submit

New:
  Pet Profile → [Request to Adopt] → Additional Questions Form → Confirmation → Submit
```

**Additional Questions (shown to adopter at request time):**
```yaml
adoptions:
  requests:
    additional_questions:
      interest_reason: "Why are you interested in adopting {{pet_name}}?"
      home_description: "Tell us a bit about your home environment"
      current_pets_details: "Tell us about any pets you currently have"
      something_else: "Anything else you'd like the shelter to know?"
```

These answers are stored as a `jsonb` column on `AdoptionRequest`:
```ruby
add_column :adoption_requests, :additional_answers, :jsonb, default: {}
# Structure:
# {
#   "interest_reason": "I've always wanted a golden retriever...",
#   "home_description": "I live in a house with a fenced yard...",
#   "current_pets_details": "I have a 5-year-old cat...",
#   "something_else": "I work from home so I'll be with the pet all day"
# }
```

**Shelter/Individual Custom Questions (future):**
- Shelters can optionally configure custom questions in their settings
- Questions appear in the adoption request form for their pets
- Stored in `shelter.adoption_policies["custom_questions"]` as an array of `{ key, label, required, type }`
- Type can be: `text`, `textarea`, `select`, `boolean`, `number`

**For MVP:** Use the default questions above. Custom questions are post-MVP.

#### Profile Update Prompt

Before submitting, if the adopter's profile feels stale (older than 30 days), show:
```erb
<div class="bg-yellow-50 border border-yellow-200 rounded-xl p-4 mb-6">
  <p class="text-sm text-yellow-800">
    <%= t(".profile_stale_notice") %>
    <%= link_to t(".edit_profile_link"), edit_profile_path, class: "underline font-medium" %>
  </p>
</div>
```

---

### 3.4 Adopter Withdraw Request

**User Story:**
> As an adopter, I want to withdraw my adoption request so that I can cancel if I've changed my mind or found another pet.

**Implementation:**

- Add `withdrawn` status to `AdoptionRequest` (new terminal status)
- Add `withdrawable?` method: `pending? || in_validation?`
- Service object: `Adoptions::WithdrawRequest`
- Controller: add `withdraw` member action on `AdoptionRequestsController`
- UI: "Withdraw Request" button on request show page (only when withdrawable)
- Confirmation dialog before withdrawal
- Notify shelter/individual of withdrawal

```ruby
class Adoptions::WithdrawRequest < ApplicationService
  def initialize(request:, adopter:)
    @request = request
    @adopter = adopter
  end

  def call
    return Result.failure([ I18n.t("adoptions.requests.errors.cannot_withdraw") ]) unless @request.withdrawable?

    AdoptionRequest.transaction do
      @request.update!(status: :withdrawn)
      @request.record_timeline!(
        from_status: @request.status_was,
        to_status: "withdrawn",
        actor: @adopter,
        metadata: { withdrawn_by: "adopter" }
      )
    end

    # Notify responsible party
    notifications_service.call

    Result.success(@request)
  end
end
```

---

### 3.5 "Request More Info" Flow

**User Story:**
> As a shelter/individual, I want to request additional information from the adopter so that I can make a more informed decision.

**Implementation:**

- Add `needs_info` and `info_provided` statuses to `AdoptionRequest` 
- Status flow: `pending` → `needs_info` → `info_provided` → can go to `in_validation`/`accepted`/`declined`
- Or simpler approach: add a `request_info` action that:
  1. Creates a `ConversationMessage` from shelter to adopter asking for info
  2. Sets status to `in_validation` if it was `pending`
  3. Sends notification with the question
  4. Adopter replies via the conversation thread

**Simpler approach (MVP):** Use the `in_validation` status as the signal that more info may be needed. The shelter sends questions through the conversation (Phase 2). No new statuses needed.

```ruby
class Adoptions::RequestMoreInfo < ApplicationService
  def initialize(request:, actor:, question:)
    @request = request
    @actor = actor
    @question = question
  end

  def call
    # Set to in_validation if pending
    # Create a message/notification with the question
    # Notify adopter
  end
end
```

**For MVP:** Skip the `needs_info` status and use `in_validation` + conversation messages instead. Add a dedicated "Request More Info" action that's distinct from status changes only if data shows shelters actually use it.

---

### 3.6 Enhanced Email Templates

Upgrade the existing `AdoptionMailer` templates to include:
- Pet photo
- Status with visual badge
- Clear next steps
- Shelter contact info
- WhatsApp opt-in link (if not yet opted in)
- Deep link to the request on the platform

**Template structure:**
```
┌──────────────────────────────────────┐
│  🐾 Tovitu                           │
│                                      │
│  Your Request Has Been Accepted! 🎉  │
│                                      │
│  ┌────────────────────────────┐      │
│  │ [Pet Photo]  Bella         │      │
│  │              Labrador Ret. │      │
│  │              Happy Paws    │      │
│  └────────────────────────────┘      │
│                                      │
│  Hi Maria,                           │
│                                      │
│  Great news! Your request to adopt   │
│  Bella has been accepted by Happy    │
│  Paws Rescue! 🐕                     │
│                                      │
│  Next steps:                         │
│  1. Happy Paws will contact you      │
│     within 48 hours                  │
│  2. You may need to schedule a       │
│     meet-and-greet                   │
│  3. Get your home ready!            │
│                                      │
│  View Request Details →              │
│                                      │
│  ───────────────────────────────     │
│  Want faster updates? Get           │
│  notifications on WhatsApp →        │
│                                      │
│  Thanks for using Tovitu!            │
└──────────────────────────────────────┘
```

---

### 3.7 Individual Publisher Flow Enhancements

**Current gaps:**
- `My::AdoptionRequests::DecisionsController` has no decline reason collection
- No timeline display in `My::AdoptionRequestsController#show`
- Simple UI with minimal information

**Fixes:**
1. Add decline reasons to `My::AdoptionRequests::DecisionsController` (same pattern as shelter)
2. Add timeline events to `My::AdoptionRequestsController#show`
3. Add profile summary display
4. Reuse shared partials from `adoption_requests/` and `shelter/adoption_requests/`
5. Add `notify_publisher` call in the decisions controller (already referenced but cross-check)

---

### 3.8 Status Lifecycle (Updated)

```
                     ┌─────────────────┐
                     │    pending      │  (initial state on submission)
                     └────────┬────────┘
                              │
               ┌──────────────┼──────────────┬──────────────────┐
               │              │              │                  │
               ▼              ▼              ▼                  ▼
      ┌────────────────┐ ┌──────────┐ ┌──────────┐    ┌──────────────┐
      │  in_validation │ │ accepted │ │ declined │    │  withdrawn   │
      └────────────────┘ └──────────┘ └──────────┘    └──────────────┘
               │              │                            (NEW)
               │              │ (pet → on_hold)
               │              │
               └──────┬───────┘
                      │
                      ▼
               ┌──────────┐
               │ declined │
               └──────────┘

New: withdrawn — adopter cancels their own request (only from pending or in_validation)
```

---

## 4. Information Architecture (New/Modified Models)

### New Tables

```sql
-- Notifications
CREATE TABLE notifications (
  id BIGSERIAL PRIMARY KEY,
  recipient_id BIGINT NOT NULL REFERENCES users(id),
  actor_id BIGINT REFERENCES users(id),
  notifiable_type VARCHAR NOT NULL,
  notifiable_id BIGINT NOT NULL,
  kind VARCHAR NOT NULL,
  title VARCHAR NOT NULL,
  body TEXT,
  metadata JSONB DEFAULT '{}',
  read_at TIMESTAMP,
  actionable_until TIMESTAMP,
  action_url VARCHAR,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
CREATE INDEX idx_notifications_unread ON notifications(recipient_id, read_at, created_at DESC);
CREATE INDEX idx_notifications_polymorphic ON notifications(notifiable_type, notifiable_id);

-- Notification Preferences
CREATE TABLE notification_preferences (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  in_app BOOLEAN DEFAULT TRUE,
  email BOOLEAN DEFAULT TRUE,
  whatsapp BOOLEAN DEFAULT FALSE,
  whatsapp_phone VARCHAR,
  whatsapp_verified_at TIMESTAMP,
  per_kind_overrides JSONB DEFAULT '{}',
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
CREATE UNIQUE INDEX idx_notification_preferences_user ON notification_preferences(user_id);

-- Conversations
CREATE TABLE conversations (
  id BIGSERIAL PRIMARY KEY,
  adoption_request_id BIGINT NOT NULL REFERENCES adoption_requests(id),
  shelter_id BIGINT REFERENCES shelters(id),
  adopter_id BIGINT NOT NULL REFERENCES users(id),
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
CREATE INDEX idx_conversations_adoption_request ON conversations(adoption_request_id);

-- Conversation Messages
CREATE TABLE conversation_messages (
  id BIGSERIAL PRIMARY KEY,
  conversation_id BIGINT NOT NULL REFERENCES conversations(id),
  sender_id BIGINT NOT NULL REFERENCES users(id),
  body TEXT NOT NULL,
  message_type VARCHAR DEFAULT 'text',  -- text, image, system
  metadata JSONB DEFAULT '{}',
  read_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
CREATE INDEX idx_messages_conversation ON conversation_messages(conversation_id, created_at);
```

### Modified Tables

```sql
-- Add to adoption_requests
ALTER TABLE adoption_requests ADD COLUMN additional_answers JSONB DEFAULT '{}';
ALTER TABLE adoption_requests ADD COLUMN withdrawn_at TIMESTAMP;

-- Add status 'withdrawn' to the enum check constraint (handled via Rails enum, but DB constraint may need update)
-- The current statuses: pending, in_validation, accepted, declined
-- New: withdrawn
```

---

## 5. Service Objects (New & Modified)

### New Service Objects

| Service | Purpose |
|---------|---------|
| `Notifications::Deliver` | Central notification dispatch (creates record + routes to channels) |
| `Notifications::MarkAsRead` | Mark notification(s) as read |
| `Notifications::GetUnreadCount` | Query unread count for badge |
| `Adoptions::WithdrawRequest` | Adopter withdraws their request |
| `Messaging::WhatsAppProvider` | Concrete WhatsApp Business API provider |
| `Messaging::WebhookHandler` | Process incoming WhatsApp webhooks |
| `Messaging::OptInManager` | Handle WhatsApp opt-in/verification |
| `Messaging::Templates` | WhatsApp message template registry |
| `Messaging::SendConversationMessage` | Send a message in a conversation thread |
| `Settings::SaveNotificationPreferences` | Save user notification preferences |

### Modified Service Objects

| Service | Changes |
|---------|---------|
| `Adoptions::SubmitRequest` | Add `additional_answers` to creation params. Call `Notifications::Deliver` instead of directly mailing. |
| `Adoptions::ProcessRequest` | Call `Notifications::Deliver` instead of directly mailing. |
| `Adoptions::DeclineRequest` | Call `Notifications::Deliver` instead of directly mailing. |
| `Adoptions::NotifyAdopter` | **DEPRECATED** — replaced by `Notifications::Deliver` |
| `Adoptions::NotifyShelter` | **DEPRECATED** — replaced by `Notifications::Deliver` |
| `Adoptions::NotifyPublisher` | **DEPRECATED** — replaced by `Notifications::Deliver` |
| `Messaging::SendMessage` | Implement properly with configurable provider |
| `Messaging::ReceiveWebhook` | Implement webhook parsing |
| `Messaging::StartConversation` | Implement conversation creation |

---

## 6. Controllers (New & Modified)

### New Controllers

| Controller | Purpose |
|------------|---------|
| `NotificationsController` | Index, show, mark_as_read, mark_all_read, unread_count |
| `NotificationPreferencesController` | Edit, update user's notification preferences |
| `Webhooks::WhatsappController` | Receive WhatsApp webhooks (no CSRF, IP whitelist) |
| `ConversationsController` | Index, show (for a given adoption request) |
| `Conversations::MessagesController` | Create, index for a conversation |

### Modified Controllers

| Controller | Changes |
|------------|---------|
| `AdoptionRequestsController` | Add `withdraw` member action. Update `create` to accept `additional_answers` params. |
| `Shelter::AdoptionRequests::DecisionsController` | Add "request more info" action. |
| `My::AdoptionRequests::DecisionsController` | Add decline reasons (same as shelter flow). Add timeline display. |
| `DashboardController` | Add notification counts to dashboard data. |

---

## 7. Routes (Additions)

```ruby
# Notifications
resources :notifications, only: [:index, :show] do
  collection do
    patch :mark_all_read
    get :unread_count
  end
  member do
    patch :mark_read
  end
end

resource :notification_preferences, only: [:edit, :update]

# Conversation (nested under adoption_requests)
resources :adoption_requests do
  member do
    patch :withdraw
  end
  resource :conversation, only: [:show] do
    resources :messages, only: [:index, :create], controller: "conversations/messages"
  end
end

# Also for shelter scope
namespace :shelter do
  resources :adoption_requests do
    member do
      patch :request_info
    end
    resource :conversation, only: [:show] do
      resources :messages, only: [:index, :create]
    end
  end
end

# Also for individual publisher scope
namespace :my do
  resources :adoption_requests do
    member do
      patch :request_info
    end
    resource :conversation, only: [:show]
  end
end

# WhatsApp webhook (outside locale scope, no CSRF)
namespace :webhooks do
  resource :whatsapp, only: [:create], controller: "whatsapp"
  get "webhooks/whatsapp" => "webhooks/whatsapp#verify" # Webhook verification challenge
end
```

---

## 8. UX Flows

### Flow 1: Adopter Submits Request with Additional Info

```
1. Adopter views pet profile
2. Clicks "Request to Adopt"
3. Onboarding check → if incomplete, redirect to onboarding
4. Shows new **Additional Questions** form:
   ┌───────────────────────────────────────────────┐
   │ Tell us more about your interest              │
   │                                               │
   │ Why are you interested in adopting Bella?     │
   │ ┌───────────────────────────────────────────┐ │
   │ │ I've always wanted a labrador...          │  │
   │ └───────────────────────────────────────────┘ │
   │                                               │
   │ Tell us about your home environment           │
   │ ┌───────────────────────────────────────────┐ │
   │ │ I live in a house with a fenced yard...   │  │
   │ └───────────────────────────────────────────┘ │
   │                                               │
   │ Anything else?                                │
   │ ┌───────────────────────────────────────────┐ │
   │ │ I work from home...                       │  │
   │ └───────────────────────────────────────────┘ │
   │                                               │
   │ [Back]  [Continue to Review]                  │
   └───────────────────────────────────────────────┘

5. Review page (same as current):
   - Pet info + shelter
   - Profile summary
   - Additional answers summary
   - [Submit Request]

6. System creates request + additional_answers stored
7. Notification sent to shelter (in-app + email + WhatsApp if opted in)
8. Adopter redirected to request detail page
9. In-app notification created for both parties
```

### Flow 2: Notifications

```
1. Any status change / action occurs
2. Notifications::Deliver.call is invoked
3. For each channel enabled in user's preferences:
   a. In-app: Notification record created, Turbo Stream updates bell badge
   b. Email: NotificationMailer queued with rich template
   c. WhatsApp: Messaging::SendMessage queued with appropriate template
4. When user opens app:
   - Bell shows unread count
   - Dropdown shows last 5 notifications
   - Click navigates to action_url
   - Notification automatically marked as read when the page loads (or after a delay)
```

### Flow 3: WhatsApp Opt-In

```
1. User goes to Settings → Notifications → WhatsApp
2. Sees: "Get real-time updates on WhatsApp"
3. Enters phone number + clicks "Verify"
4. System sends verification code via WhatsApp template
5. User receives: "Your Tovitu verification code is: 48291"
6. User enters code in app
7. Phone verified → toggle on
8. Future notifications delivered via WhatsApp
```

### Flow 4: Conversation Between Shelter and Adopter

```
1. Shelter views an adoption request in "in_validation" status
2. Shelter clicks "Send Message" instead of using status actions
3. Composer opens inline:
   ┌───────────────────────────────────────────────┐
   │ Conversation with Maria G.     (3 messages)   │
   │                                               │
   │ ┌───────────────────────────────────────────┐ │
   │ │ 🏠 Happy Paws: Hi Maria! Could you tell   │ │
   │ │ us more about your experience with large  │ │
   │ │ breed dogs?                               │ │
   │ │ 10:32 AM                                  │ │
   │ ├───────────────────────────────────────────┤ │
   │ │ 👤 Maria G.: Yes! I grew up with labs...  │ │
   │ │ 10:45 AM                                  │ │
   │ └───────────────────────────────────────────┘ │
   │                                               │
   │ ┌───────────────────────────────────────────┐ │
   │ │ Type your message...           [Send] ▶   │ │
   │ └───────────────────────────────────────────┘ │
   └───────────────────────────────────────────────┘

4. When a message is sent:
   - Recipient gets notification (in-app + email + WhatsApp)
   - WhatsApp message goes as a free-form message (within 24h window)
   - If outside 24h, fall back to template message or email
```

---

## 9. Notification Touchpoints (Complete Matrix)

| Trigger | In-App | Email | WhatsApp |
|---------|--------|-------|----------|
| **Request Submitted (to adopter)** | ✅ Confirmation | ✅ Rich email | ✅ If opted in |
| **Request Submitted (to shelter)** | ✅ New request alert | ✅ New request notification | ✅ If opted in |
| **Status → In Validation (to adopter)** | ✅ "Under review" | ✅ Status update | ✅ If opted in |
| **Status → Accepted (to adopter)** | ✅ Congratulations | ✅ Rich email with next steps | ✅ If opted in |
| **Status → Declined (to adopter)** | ✅ With reasons | ✅ With reasons | ✅ If opted in |
| **Status → Withdrawn (to shelter)** | ✅ Adopter withdrew | ✅ Notification | ✅ If opted in |
| **New Message (to recipient)** | ✅ New message | ✅ Digest or immediate | ✅ Free-form msg |
| **Info Requested (to adopter)** | ✅ Question from shelter | ✅ Question | ✅ If opted in |
| **Pet Status Changed** | ✅ If relevant to user | ✅ | ✅ If opted in |
| **Welcome/Onboarding Complete** | ✅ Welcome | ✅ Welcome email | — |

---

## 10. Migration Plan

### Phase 1 Migrations (in order)

1. **Create notifications table** (`20260720_create_notifications.rb`)
2. **Create notification_preferences table** (`20260720_create_notification_preferences.rb`)
3. **Add additional_answers and withdrawn_at to adoption_requests** (`20260720_add_adoption_request_fields.rb`)
4. **Create conversations table** (`20260720_create_conversations.rb`)
5. **Create conversation_messages table** (`20260720_create_conversation_messages.rb`)
6. **Create webhook_events table** (optional, for webhook logging) (`20260720_create_webhook_events.rb`)

### Data Migration
- Create `NotificationPreference` records for all existing users with defaults (in_app: true, email: true, whatsapp: false)
- Backfill notification read_at for existing data (none to backfill since no system existed)

---

## 11. i18n Additions

### New Locale Files

**`config/locales/notifications/en.yml`** — All notification-related strings:
```yaml
en:
  notifications:
    kinds:
      request_submitted: "Request Submitted"
      request_accepted: "Request Accepted"
      # ...
    titles:
      request_submitted: "Request submitted for %{pet_name}"
      request_accepted: "Your request was accepted! 🎉"
      # ...
    bodies:
      request_submitted: "Your request to adopt %{pet_name} has been sent to %{shelter_name}"
      request_accepted: "Congratulations! Your request to adopt %{pet_name} has been accepted by %{shelter_name}"
      # ...
    preferences:
      title: "Notification Settings"
      in_app_label: "In-app notifications"
      email_label: "Email notifications"
      whatsapp_label: "WhatsApp notifications"
      whatsapp_phone: "Phone number for WhatsApp"
      verify: "Verify"
      verified: "✓ Verified"
      # ...
    index:
      title: "Notifications"
      empty: "No notifications yet"
      mark_all_read: "Mark all as read"
      # ...
  notification_preferences:
    edit:
      title: "Notification Preferences"
    # ...
```

**`config/locales/conversations/en.yml`** — Messaging strings:
```yaml
en:
  conversations:
    title: "Conversation"
    placeholder: "Type your message..."
    send: "Send"
    no_messages: "No messages yet"
    sent_at: "Sent %{time}"
    read: "Read"
    # ...
```

### Updates to Existing Locales

- `config/locales/adoptions/en.yml` — Add strings for:
  - Withdraw action
  - Withdrawn status
  - Additional questions labels
  - Profile stale notice
  - Info request action

---

## 12. WhatsApp Template Registration Checklist

Before WhatsApp integration can go live:

- [ ] Facebook Business Account created
- [ ] WhatsApp Business Account (WABA) approved
- [ ] Phone number registered and approved
- [ ] Templates submitted for approval (8 templates, allow 24-48h per template)
- [ ] Webhook URL configured in WhatsApp Business Dashboard
- [ ] Webhook verification token configured
- [ ] `WHATSAPP_PHONE_NUMBER_ID` env var set
- [ ] `WHATSAPP_ACCESS_TOKEN` env var set (long-lived, with appropriate permissions)
- [ ] `WHATSAPP_WEBHOOK_VERIFY_TOKEN` env var set
- [ ] `WHATSAPP_BUSINESS_ACCOUNT_ID` env var set

**For development/staging:** Use WhatsApp Cloud API test mode or a Meta developer app with `waba-messaging` scope. Use the Meta Graph API Explorer to generate short-lived tokens.

**Environment Variables:**
```
WHATSAPP_PHONE_NUMBER_ID=123456789
WHATSAPP_ACCESS_TOKEN=EAAx...
WHATSAPP_WEBHOOK_VERIFY_TOKEN=tovitu_verify_2026
WHATSAPP_BUSINESS_ACCOUNT_ID=987654321
```

---

## 13. Security & Compliance

### WhatsApp-Specific
- **Opt-in required** — Cannot message users without explicit opt-in (Meta policy, also legal requirement)
- **Opt-out mechanism** — Every WhatsApp message must include "Reply STOP to unsubscribe" or similar
- **Data retention** — Message content stored securely, accessible only to conversation participants
- **Phone number privacy** — Phone numbers not exposed in the UI; only used internally for delivery
- **Template compliance** — All templates must comply with WhatsApp's commerce policy
- **24-hour messaging window** — Free-form messages only within 24h of user's last message; templates for proactive outreach

### General
- **Authorization** — Pundit policies for all new controllers (notifications, conversations)
- **Notifications scope** — Users can only see their own notifications (`policy_scope`)
- **Conversations scope** — Only participants can see conversation messages
- **Rate limiting** — WhatsApp message sending rate limited (per phone number, ~80/24h for template, lower for free-form)
- **Webhook IP whitelist** — Verify incoming webhooks from Meta's IP range
- **Webhook signature verification** — Validate X-Hub-Signature-256 header

---

## 14. Testing Strategy

### Models
- `Notification` — validations, scopes (unread, recent), polymorphic association
- `NotificationPreference` — defaults, per-kind overrides, whatsapp_phone format validation
- `Conversation` — creation with adoption request, participant validation
- `ConversationMessage` — body presence, read_at tracking
- `AdoptionRequest` — new status `withdrawn`, `withdrawable?` logic, additional_answers

### Service Objects
- `Notifications::Deliver` — creates notification record, queues channel deliveries
- `Adoptions::WithdrawRequest` — happy path (pending → withdrawn), edge cases (already accepted, already declined)
- `Messaging::WhatsAppProvider` — send_message success/failure, template sending, webhook parsing
- `Messaging::WebhookHandler` — message parsing, user lookup by phone, routing

### Request Specs
- `GET /notifications` — pagination, scoping, authorization
- `POST /adoption_requests/:id/withdraw` — authorization (only adopter), status transitions
- `POST /webhooks/whatsapp` — webhook verification, message processing (skip CSRF)
- `POST /notifications/:id/mark_read` — ownership check
- `GET /notification_preferences/edit` + `PATCH /notification_preferences` — update preferences

### Feature/System Specs
- WhatsApp opt-in flow
- Notification bell badge count
- Mark all read
- Request withdrawal with notification to shelter

---

## 15. Implementation Order

### Sprint 1: Foundation (7-10 days)

| Day | Tasks |
|-----|-------|
| 1-2 | Create `Notification` + `NotificationPreference` models + migrations |
| 2-3 | Create `Notifications::Deliver` service object (in-app + email channels) |
| 3-4 | Update adoption services (`SubmitRequest`, `ProcessRequest`, `DeclineRequest`) to use `Notifications::Deliver` instead of direct mailing |
| 4-5 | Create `NotificationsController` (index, show, mark_read, mark_all_read, unread_count) |
| 5-6 | Create notification bell Stimulus controller with polling + dropdown UI |
| 6-7 | Add `withdrawn` status to `AdoptionRequest` + `Adoptions::WithdrawRequest` + controller action |
| 7 | Add `additional_answers` column + form fields to request flow |
| 8-10 | Implement `Messaging::WhatsAppProvider` + `Messaging::SendMessage` update |

### Sprint 2: Communication (5-7 days)

| Day | Tasks |
|-----|-------|
| 1-2 | Create `Conversation` + `ConversationMessage` models + migrations |
| 2-3 | Create conversation UI (message composer, message list) |
| 3-4 | Implement `Messaging::WebhookHandler` for incoming WhatsApp messages |
| 4-5 | Wire conversations to trigger notifications |
| 5-6 | Add notification preferences UI (Settings → Notifications) |
| 6-7 | ActionCable broadcasting for real-time notification updates |

### Sprint 3: Polish (3-5 days)

| Day | Tasks |
|-----|-------|
| 1 | Enhanced email templates (AdoptionMailer) |
| 2 | Individual publisher flow improvements (decline reasons, timeline) |
| 3-4 | Dashboard activity feed integration |
| 4-5 | Testing, edge cases, i18n review, documentation |

---

## 16. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| WhatsApp template approval delays (24-48h per template) | High — blocks WhatsApp delivery | Submit templates at Sprint 1 start. Use email + in-app as fallback. Mock WhatsApp in dev. |
| WhatsApp 24-hour messaging window limit | Medium — conversation flow breaks | Implement template-based fallback for messages outside the window |
| Meta API changes/deprecations | Medium — provider breaks | Abstract behind `BaseProvider`. Monitor Meta changelog. |
| User notification fatigue | Medium — users disable notifications | Respect per-kind overrides. Don't over-notify. Bundle multiple updates. |
| Phone number privacy concerns | Medium — users hesitant to provide | Store only with opt-in. Explain why needed. Never expose publicly. |
| Opt-in compliance complexity | Medium — legal risk | Store opt-in timestamp and source. Provide clear opt-out. Consult legal. |
| Performance — notification polling | Low — unnecessary requests | Use Turbo Streams (ActionCable) in Phase 2. Poll every 30s initially. |
| Race conditions in status transitions | Low — data inconsistency | Use database transaction locks. First action wins. |

---

## 17. Key Architecture Decisions

1. **Notifications are records, not ephemeral** — Storing notifications in the DB enables history, "mark all read", and audit trail.
2. **Channel delivery is async** — Email and WhatsApp delivery is via background jobs. In-app is synchronous (DB write + optional broadcast).
3. **Conversations are scoped to adoption requests** — Not a general chat system. Each conversation belongs to exactly one adoption request.
4. **WhatsApp is a channel, not a platform** — The adoption workflow lives in-app. WhatsApp is a notification delivery channel plus a reply mechanism.
5. **Existing notify services are deprecated** — `Adoptions::NotifyAdopter`, `NotifyShelter`, `NotifyPublisher` will be replaced by `Notifications::Deliver`. Keep them for backward compatibility during transition, then remove.
6. **Additional answers are optional** — The form is shown but all fields are optional. Shelters can request more info if needed.
7. **Withdrawal is irreversible** — No undo for withdrawal. The adopter can submit a new request if they change their mind (since it's not declined).

---

## 18. Success Metrics

| Metric | Target | How to Measure |
|--------|--------|----------------|
| In-app notification delivery rate | > 99% | Notifications delivered ÷ notifications created |
| WhatsApp opt-in rate | > 40% of active users | Users with whatsapp: true ÷ total users |
| WhatsApp delivery success rate | > 95% | Messages sent without error ÷ total WhatsApp sends |
| Notification read rate (within 24h) | > 60% | Notifications read at ≤ 24h ÷ total notifications |
| Request withdrawal usage | < 10% of requests | Withdrawn requests ÷ total requests (indicator of good matching) |
| Additional answers fill rate | > 70% | Requests with additional_answers present ÷ total requests |
| Average time from request to shelter action | < 24 hours (was 48h) | Timestamp diff (with notifications improving response time) |
| User satisfaction with notifications (survey) | > 4/5 | In-app survey after 3 interactions |

---

## 19. Open Questions

1. **WhatsApp pricing model?** Meta charges per conversation (24h window). Need to track costs vs. value. Should we absorb or pass on costs?
2. **Template localization?** WhatsApp templates need to be registered per language. Do we register EN + ES templates from the start?
3. **Conversation vs. existing request detail page?** Should the conversation be embedded in the request detail page or separate? Decision: Embedded in Phase 2 (tab/accordion), separate page in Phase 3.
4. **Notification retention?** How long to keep notification records? Auto-delete after 90 days? Archive to separate table?
5. **Shelter WhatsApp number?** Does each shelter use their own WhatsApp Business number or a central Tovitu number? Decision: Central Tovitu number initially (simpler), shelter forwarding later.
6. **Media messages?** Allow photo sharing in conversations? Not in MVP, but plan for it in the message_type column.
7. **Rate limiting per user?** How many WhatsApp messages per day per user? Meta limits apply. We should add our own limits.

---

## 20. Sunset Plan for Legacy AdoptionApplication

The legacy `AdoptionApplication` model (7-status, anonymous, token-based) should be formally deprecated. New functionality uses `AdoptionRequest` exclusively.

Steps:
1. Remove "Apply to Adopt" CTA from pet profiles (it should point to the new `AdoptionRequestsController#new` flow)
2. Archive legacy applications page for shelters (keep data but remove from nav)
3. Mark legacy model as `deprecated` in code comments
4. Remove legacy routes in a future cleanup PR

---

## Appendix A: File Checklist (Phase 1)

### New Files
```
□ db/migrate/20260720_create_notifications.rb
□ db/migrate/20260720_create_notification_preferences.rb
□ db/migrate/20260720_add_adoption_request_fields.rb
□ app/models/notification.rb
□ app/models/notification_preference.rb
□ lib/notifications/deliver.rb
□ lib/notifications/mark_as_read.rb
□ lib/notifications/get_unread_count.rb
□ app/controllers/notifications_controller.rb
□ app/views/notifications/index.html.erb
□ app/views/notifications/_dropdown.html.erb
□ app/views/notifications/_notification.html.erb
□ app/javascript/controllers/notification_bell_controller.js
□ app/policies/notification_policy.rb
□ app/policies/notification_preference_policy.rb
□ config/locales/notifications/en.yml
□ config/locales/notifications/es.yml
□ lib/adoptions/withdraw_request.rb
□ app/views/adoption_requests/_additional_questions.html.erb
□ lib/messaging/whatsapp_provider.rb
□ lib/messaging/webhook_handler.rb
□ lib/messaging/templates.rb
□ lib/messaging/opt_in_manager.rb
□ app/controllers/webhooks/whatsapp_controller.rb
```

### Modified Files
```
□ lib/adoptions/submit_request.rb (add additional_answers, use Notifications::Deliver)
□ lib/adoptions/process_request.rb (use Notifications::Deliver)
□ lib/adoptions/decline_request.rb (use Notifications::Deliver)
□ app/controllers/adoption_requests_controller.rb (add withdraw, additional_answers)
□ app/views/adoption_requests/new.html.erb (add additional_questions partial)
□ app/views/adoption_requests/show.html.erb (add withdraw button)
□ app/views/shared/_navbar.html.erb (wire notification bell)
□ app/controllers/dashboard_controller.rb (add notification count)
□ app/models/adoption_request.rb (add withdrawn status, withdrawable?)
□ config/routes.rb (add new routes)
□ config/locales/adoptions/en.yml (new strings)
```
