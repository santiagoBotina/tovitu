SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: adopter_insights; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.adopter_insights (
    id bigint NOT NULL,
    adopter_id bigint NOT NULL,
    data jsonb DEFAULT '{}'::jsonb,
    version integer DEFAULT 0 NOT NULL,
    signal_fingerprint character varying,
    generated_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: adopter_insights_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.adopter_insights_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: adopter_insights_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.adopter_insights_id_seq OWNED BY public.adopter_insights.id;


--
-- Name: adoption_applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.adoption_applications (
    id bigint NOT NULL,
    pet_id bigint NOT NULL,
    shelter_id bigint NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    applicant_name character varying NOT NULL,
    applicant_email character varying NOT NULL,
    applicant_phone character varying,
    applicant_address text,
    housing_type character varying,
    current_pets text,
    pet_experience text,
    questionnaire_answers jsonb DEFAULT '{}'::jsonb,
    notes text,
    rejection_reason character varying,
    token character varying NOT NULL,
    reviewed_by_id bigint,
    completed_at timestamp(6) without time zone,
    withdrawn_at timestamp(6) without time zone,
    hold_expires_at timestamp(6) without time zone,
    discarded_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: adoption_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.adoption_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: adoption_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.adoption_applications_id_seq OWNED BY public.adoption_applications.id;


--
-- Name: adoption_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.adoption_notes (
    id bigint NOT NULL,
    adoption_application_id bigint NOT NULL,
    user_id bigint NOT NULL,
    content text NOT NULL,
    pinned boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: adoption_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.adoption_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: adoption_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.adoption_notes_id_seq OWNED BY public.adoption_notes.id;


--
-- Name: adoption_request_timeline_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.adoption_request_timeline_events (
    id bigint NOT NULL,
    adoption_request_id bigint NOT NULL,
    from_status character varying,
    to_status character varying NOT NULL,
    actor_id bigint,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: adoption_request_timeline_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.adoption_request_timeline_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: adoption_request_timeline_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.adoption_request_timeline_events_id_seq OWNED BY public.adoption_request_timeline_events.id;


--
-- Name: adoption_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.adoption_requests (
    id bigint NOT NULL,
    pet_id bigint NOT NULL,
    adopter_id bigint NOT NULL,
    shelter_id bigint,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    decline_reasons jsonb,
    reviewed_by_id bigint,
    reviewed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    additional_answers jsonb DEFAULT '{}'::jsonb,
    withdrawn_at timestamp(6) without time zone,
    pet_fit_data jsonb DEFAULT '{}'::jsonb,
    pet_fit_generated_at timestamp(6) without time zone,
    pet_fit_version integer DEFAULT 0 NOT NULL,
    pet_fit_fingerprint character varying,
    pet_fit_signal_fingerprint character varying
);


--
-- Name: adoption_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.adoption_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: adoption_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.adoption_requests_id_seq OWNED BY public.adoption_requests.id;


--
-- Name: adoption_timeline_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.adoption_timeline_events (
    id bigint NOT NULL,
    adoption_application_id bigint NOT NULL,
    event_type character varying NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: adoption_timeline_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.adoption_timeline_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: adoption_timeline_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.adoption_timeline_events_id_seq OWNED BY public.adoption_timeline_events.id;


--
-- Name: ai_document_chunks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_document_chunks (
    id bigint NOT NULL,
    ai_document_id bigint NOT NULL,
    content text NOT NULL,
    chunk_index integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    embedding public.vector(1536)
);


--
-- Name: ai_document_chunks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ai_document_chunks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ai_document_chunks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ai_document_chunks_id_seq OWNED BY public.ai_document_chunks.id;


--
-- Name: ai_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_documents (
    id bigint NOT NULL,
    shelter_id bigint NOT NULL,
    title character varying NOT NULL,
    content text NOT NULL,
    source_type character varying NOT NULL,
    status character varying DEFAULT 'processing'::character varying NOT NULL,
    error_message text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ai_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ai_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ai_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ai_documents_id_seq OWNED BY public.ai_documents.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: email_verification_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_verification_tokens (
    id bigint NOT NULL,
    consumed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    token character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: email_verification_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.email_verification_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_verification_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.email_verification_tokens_id_seq OWNED BY public.email_verification_tokens.id;


--
-- Name: individual_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.individual_profiles (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    weekend_activity jsonb DEFAULT '[]'::jsonb,
    activity_level character varying,
    ideal_companion character varying,
    pet_experience character varying,
    adoption_goals jsonb DEFAULT '[]'::jsonb,
    daily_time_available character varying,
    personality character varying,
    adoption_priority character varying,
    onboarding_step integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: individual_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.individual_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: individual_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.individual_profiles_id_seq OWNED BY public.individual_profiles.id;


--
-- Name: invitations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invitations (
    id bigint NOT NULL,
    email character varying NOT NULL,
    token character varying NOT NULL,
    shelter_id bigint NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    accepted_at timestamp(6) without time zone,
    created_by_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: invitations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.invitations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invitations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.invitations_id_seq OWNED BY public.invitations.id;


--
-- Name: login_attempts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.login_attempts (
    id bigint NOT NULL,
    attempted_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    email character varying NOT NULL,
    ip_address character varying NOT NULL,
    success boolean NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_agent character varying
);


--
-- Name: login_attempts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.login_attempts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: login_attempts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.login_attempts_id_seq OWNED BY public.login_attempts.id;


--
-- Name: notification_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_preferences (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    in_app boolean DEFAULT true NOT NULL,
    email boolean DEFAULT true NOT NULL,
    whatsapp boolean DEFAULT false NOT NULL,
    whatsapp_phone character varying,
    whatsapp_verified_at timestamp(6) without time zone,
    per_kind_overrides jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: notification_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notification_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notification_preferences_id_seq OWNED BY public.notification_preferences.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id bigint NOT NULL,
    recipient_id bigint NOT NULL,
    actor_id bigint,
    notifiable_type character varying NOT NULL,
    notifiable_id bigint NOT NULL,
    kind character varying NOT NULL,
    title character varying NOT NULL,
    body text,
    metadata jsonb DEFAULT '{}'::jsonb,
    read_at timestamp(6) without time zone,
    actionable_until timestamp(6) without time zone,
    action_url character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: password_reset_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.password_reset_tokens (
    id bigint NOT NULL,
    consumed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    token character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: password_reset_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.password_reset_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: password_reset_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.password_reset_tokens_id_seq OWNED BY public.password_reset_tokens.id;


--
-- Name: pets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pets (
    id bigint NOT NULL,
    shelter_id bigint,
    name character varying NOT NULL,
    species character varying NOT NULL,
    breed character varying,
    age_category character varying NOT NULL,
    birth_date date,
    size character varying,
    sex character varying NOT NULL,
    description text,
    personality_traits jsonb DEFAULT '[]'::jsonb,
    medical_notes text,
    spayed_neutered boolean DEFAULT false,
    vaccinated boolean DEFAULT false,
    special_needs boolean DEFAULT false,
    good_with_children boolean,
    good_with_dogs boolean,
    good_with_cats boolean,
    requirements text,
    status character varying DEFAULT 'available'::character varying NOT NULL,
    adopted_at timestamp(6) without time zone,
    discarded_at timestamp(6) without time zone,
    photo_order jsonb DEFAULT '[]'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    life_preview_data jsonb,
    life_preview_generated_at timestamp(6) without time zone,
    life_preview_version integer DEFAULT 0,
    personality_spec text,
    adopter_tips text,
    publisher_id bigint
);


--
-- Name: pets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pets_id_seq OWNED BY public.pets.id;


--
-- Name: saved_pets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.saved_pets (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    pet_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: saved_pets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.saved_pets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: saved_pets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.saved_pets_id_seq OWNED BY public.saved_pets.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: shelter_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shelter_profiles (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    shelter_id bigint,
    organization_type character varying,
    pet_count_range character varying,
    adoption_involvement character varying,
    approval_priorities jsonb DEFAULT '[]'::jsonb,
    communication_channels jsonb DEFAULT '[]'::jsonb,
    biggest_challenges jsonb DEFAULT '[]'::jsonb,
    approval_philosophy character varying,
    onboarding_step integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: shelter_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shelter_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shelter_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shelter_profiles_id_seq OWNED BY public.shelter_profiles.id;


--
-- Name: shelters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shelters (
    id bigint NOT NULL,
    name character varying NOT NULL,
    street character varying NOT NULL,
    city character varying NOT NULL,
    state character varying NOT NULL,
    zip character varying NOT NULL,
    phone character varying NOT NULL,
    website character varying,
    description text,
    species_served jsonb DEFAULT '["dog"]'::jsonb NOT NULL,
    hours character varying,
    status character varying DEFAULT 'active'::character varying NOT NULL,
    discarded_at timestamp(6) without time zone,
    adoption_policies jsonb DEFAULT '{}'::jsonb NOT NULL,
    onboarding_completed boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    ai_features_enabled boolean DEFAULT true,
    checklist_dismissed_at timestamp(6) without time zone
);


--
-- Name: shelters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shelters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shelters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shelters_id_seq OWNED BY public.shelters.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    discarded_at timestamp(6) without time zone,
    email character varying NOT NULL,
    name character varying NOT NULL,
    password_digest character varying NOT NULL,
    role character varying DEFAULT 'individual'::character varying NOT NULL,
    shelter_id bigint,
    updated_at timestamp(6) without time zone NOT NULL,
    verified_at timestamp(6) without time zone,
    onboarding_completed_at timestamp(6) without time zone,
    onboarding_step integer DEFAULT 0 NOT NULL,
    locale character varying,
    CONSTRAINT valid_role CHECK (((role)::text = ANY (ARRAY[('individual'::character varying)::text, ('shelter_admin'::character varying)::text, ('shelter_staff'::character varying)::text, ('admin'::character varying)::text, ('staff'::character varying)::text])))
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: adopter_insights id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adopter_insights ALTER COLUMN id SET DEFAULT nextval('public.adopter_insights_id_seq'::regclass);


--
-- Name: adoption_applications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption_applications ALTER COLUMN id SET DEFAULT nextval('public.adoption_applications_id_seq'::regclass);


--
-- Name: adoption_notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption_notes ALTER COLUMN id SET DEFAULT nextval('public.adoption_notes_id_seq'::regclass);


--
-- Name: adoption_request_timeline_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption_request_timeline_events ALTER COLUMN id SET DEFAULT nextval('public.adoption_request_timeline_events_id_seq'::regclass);


--
-- Name: adoption_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption_requests ALTER COLUMN id SET DEFAULT nextval('public.adoption_requests_id_seq'::regclass);


--
-- Name: adoption_timeline_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption_timeline_events ALTER COLUMN id SET DEFAULT nextval('public.adoption_timeline_events_id_seq'::regclass);


--
-- Name: ai_document_chunks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_document_chunks ALTER COLUMN id SET DEFAULT nextval('public.ai_document_chunks_id_seq'::regclass);


--
-- Name: ai_documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_documents ALTER COLUMN id SET DEFAULT nextval('public.ai_documents_id_seq'::regclass);


--
-- Name: email_verification_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_verification_tokens ALTER COLUMN id SET DEFAULT nextval('public.email_verification_tokens_id_seq'::regclass);


--
-- Name: individual_profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.individual_profiles ALTER COLUMN id SET DEFAULT nextval('public.individual_profiles_id_seq'::regclass);


--
-- Name: invitations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations ALTER COLUMN id SET DEFAULT nextval('public.invitations_id_seq'::regclass);


--
-- Name: login_attempts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_attempts ALTER COLUMN id SET DEFAULT nextval('public.login_attempts_id_seq'::regclass);


--
-- Name: notification_preferences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_preferences ALTER COLUMN id SET DEFAULT nextval('public.notification_preferences_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: password_reset_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens ALTER COLUMN id SET DEFAULT nextval('public.password_reset_tokens_id_seq'::regclass);


--
-- Name: pets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pets ALTER COLUMN id SET DEFAULT nextval('public.pets_id_seq'::regclass);


--
-- Name: saved_pets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_pets ALTER COLUMN id SET DEFAULT nextval('public.saved_pets_id_seq'::regclass);


--
-- Name: shelter_profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shelter_profiles ALTER COLUMN id SET DEFAULT nextval('public.shelter_profiles_id_seq'::regclass);


--
-- Name: shelters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shelters ALTER COLUMN id SET DEFAULT nextval('public.shelters_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: adopter_insights adopter_insights_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adopter_insights
    ADD CONSTRAINT adopter_insights_pkey PRIMARY KEY (id);


--
-- Name: adoption_applications adoption_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption_applications
    ADD CONSTRAINT adoption_applications_pkey PRIMARY KEY (id);


--
-- Name: adoption_notes adoption_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption_notes
    ADD CONSTRAINT adoption_notes_pkey PRIMARY KEY (id);


--
-- Name: adoption_request_timeline_events adoption_request_timeline_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption_request_timeline_events
    ADD CONSTRAINT adoption_request_timeline_events_pkey PRIMARY KEY (id);


--
-- Name: adoption_requests adoption_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption_requests
    ADD CONSTRAINT adoption_requests_pkey PRIMARY KEY (id);


--
-- Name: adoption_timeline_events adoption_timeline_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption_timeline_events
    ADD CONSTRAINT adoption_timeline_events_pkey PRIMARY KEY (id);


--
-- Name: ai_document_chunks ai_document_chunks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_document_chunks
    ADD CONSTRAINT ai_document_chunks_pkey PRIMARY KEY (id);


--
-- Name: ai_documents ai_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_documents
    ADD CONSTRAINT ai_documents_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: email_verification_tokens email_verification_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_verification_tokens
    ADD CONSTRAINT email_verification_tokens_pkey PRIMARY KEY (id);


--
-- Name: individual_profiles individual_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.individual_profiles
    ADD CONSTRAINT individual_profiles_pkey PRIMARY KEY (id);


--
-- Name: invitations invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_pkey PRIMARY KEY (id);


--
-- Name: login_attempts login_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_attempts
    ADD CONSTRAINT login_attempts_pkey PRIMARY KEY (id);


--
-- Name: notification_preferences notification_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT notification_preferences_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: password_reset_tokens password_reset_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (id);


--
-- Name: pets pets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pets
    ADD CONSTRAINT pets_pkey PRIMARY KEY (id);


--
-- Name: saved_pets saved_pets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_pets
    ADD CONSTRAINT saved_pets_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: shelter_profiles shelter_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shelter_profiles
    ADD CONSTRAINT shelter_profiles_pkey PRIMARY KEY (id);


--
-- Name: shelters shelters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shelters
    ADD CONSTRAINT shelters_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_adoption_requests_active_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_adoption_requests_active_unique ON public.adoption_requests USING btree (adopter_id, pet_id) WHERE ((status)::text <> 'declined'::text);


--
-- Name: idx_applications_on_pet_and_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_applications_on_pet_and_email ON public.adoption_applications USING btree (pet_id, applicant_email);


--
-- Name: idx_applications_on_shelter_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_applications_on_shelter_and_status ON public.adoption_applications USING btree (shelter_id, status);


--
-- Name: idx_notes_on_application_and_pinned; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notes_on_application_and_pinned ON public.adoption_notes USING btree (adoption_application_id, pinned) WHERE (pinned = true);


--
-- Name: idx_notification_preferences_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_notification_preferences_user ON public.notification_preferences USING btree (user_id);


--
-- Name: idx_notifications_unread; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_unread ON public.notifications USING btree (recipient_id, read_at, created_at);


--
-- Name: idx_timeline_on_application_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_timeline_on_application_and_date ON public.adoption_timeline_events USING btree (adoption_application_id, created_at);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_adopter_insights_on_adopter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_adopter_insights_on_adopter_id ON public.adopter_insights USING btree (adopter_id);


--
-- Name: index_adoption_applications_on_discarded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_adoption_applications_on_discarded_at ON public.adoption_applications USING btree (discarded_at);


--
-- Name: index_adoption_applications_on_pet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_adoption_applications_on_pet_id ON public.adoption_applications USING btree (pet_id);


--
-- Name: index_adoption_applications_on_reviewed_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_adoption_applications_on_reviewed_by_id ON public.adoption_applications USING btree (reviewed_by_id);


--
-- Name: index_adoption_applications_on_shelter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_adoption_applications_on_shelter_id ON public.adoption_applications USING btree (shelter_id);


--
-- Name: index_adoption_applications_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_adoption_applications_on_status ON public.adoption_applications USING btree (status);


--
-- Name: index_adoption_applications_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_adoption_applications_on_token ON public.adoption_applications USING btree (token);


--
-- Name: index_adoption_notes_on_adoption_application_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_adoption_notes_on_adoption_application_id ON public.adoption_notes USING btree (adoption_application_id);


--
-- Name: index_adoption_notes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_adoption_notes_on_user_id ON public.adoption_notes USING btree (user_id);


--
-- Name: index_adoption_request_timeline_events_on_actor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_adoption_request_timeline_events_on_actor_id ON public.adoption_request_timeline_events USING btree (actor_id);


--
-- Name: index_adoption_request_timeline_events_on_adoption_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_adoption_request_timeline_events_on_adoption_request_id ON public.adoption_request_timeline_events USING btree (adoption_request_id);


--
-- Name: index_adoption_requests_on_adopter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_adoption_requests_on_adopter_id ON public.adoption_requests USING btree (adopter_id);


--
-- Name: index_adoption_requests_on_pet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_adoption_requests_on_pet_id ON public.adoption_requests USING btree (pet_id);


--
-- Name: index_adoption_requests_on_reviewed_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_adoption_requests_on_reviewed_by_id ON public.adoption_requests USING btree (reviewed_by_id);


--
-- Name: index_adoption_requests_on_shelter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_adoption_requests_on_shelter_id ON public.adoption_requests USING btree (shelter_id);


--
-- Name: index_adoption_requests_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_adoption_requests_on_status ON public.adoption_requests USING btree (status);


--
-- Name: index_adoption_timeline_events_on_adoption_application_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_adoption_timeline_events_on_adoption_application_id ON public.adoption_timeline_events USING btree (adoption_application_id);


--
-- Name: index_adoption_timeline_events_on_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_adoption_timeline_events_on_event_type ON public.adoption_timeline_events USING btree (event_type);


--
-- Name: index_ai_document_chunks_on_ai_document_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ai_document_chunks_on_ai_document_id ON public.ai_document_chunks USING btree (ai_document_id);


--
-- Name: index_ai_document_chunks_on_ai_document_id_and_chunk_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ai_document_chunks_on_ai_document_id_and_chunk_index ON public.ai_document_chunks USING btree (ai_document_id, chunk_index);


--
-- Name: index_ai_documents_on_shelter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ai_documents_on_shelter_id ON public.ai_documents USING btree (shelter_id);


--
-- Name: index_ai_documents_on_shelter_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ai_documents_on_shelter_id_and_status ON public.ai_documents USING btree (shelter_id, status);


--
-- Name: index_email_verification_tokens_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_verification_tokens_on_token ON public.email_verification_tokens USING btree (token);


--
-- Name: index_email_verification_tokens_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_verification_tokens_on_user_id ON public.email_verification_tokens USING btree (user_id);


--
-- Name: index_individual_profiles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_individual_profiles_on_user_id ON public.individual_profiles USING btree (user_id);


--
-- Name: index_invitations_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invitations_on_created_by_id ON public.invitations USING btree (created_by_id);


--
-- Name: index_invitations_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invitations_on_email ON public.invitations USING btree (email);


--
-- Name: index_invitations_on_shelter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invitations_on_shelter_id ON public.invitations USING btree (shelter_id);


--
-- Name: index_invitations_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_invitations_on_token ON public.invitations USING btree (token);


--
-- Name: index_login_attempts_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_login_attempts_on_email ON public.login_attempts USING btree (email);


--
-- Name: index_login_attempts_on_email_and_attempted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_login_attempts_on_email_and_attempted_at ON public.login_attempts USING btree (email, attempted_at);


--
-- Name: index_notification_preferences_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notification_preferences_on_user_id ON public.notification_preferences USING btree (user_id);


--
-- Name: index_notifications_on_actor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_actor_id ON public.notifications USING btree (actor_id);


--
-- Name: index_notifications_on_notifiable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_notifiable ON public.notifications USING btree (notifiable_type, notifiable_id);


--
-- Name: index_notifications_on_notifiable_type_and_notifiable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_notifiable_type_and_notifiable_id ON public.notifications USING btree (notifiable_type, notifiable_id);


--
-- Name: index_notifications_on_recipient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_recipient_id ON public.notifications USING btree (recipient_id);


--
-- Name: index_password_reset_tokens_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_password_reset_tokens_on_token ON public.password_reset_tokens USING btree (token);


--
-- Name: index_password_reset_tokens_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_password_reset_tokens_on_user_id ON public.password_reset_tokens USING btree (user_id);


--
-- Name: index_pets_on_age_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pets_on_age_category ON public.pets USING btree (age_category);


--
-- Name: index_pets_on_discarded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pets_on_discarded_at ON public.pets USING btree (discarded_at);


--
-- Name: index_pets_on_publisher_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pets_on_publisher_id ON public.pets USING btree (publisher_id);


--
-- Name: index_pets_on_sex; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pets_on_sex ON public.pets USING btree (sex);


--
-- Name: index_pets_on_shelter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pets_on_shelter_id ON public.pets USING btree (shelter_id);


--
-- Name: index_pets_on_size; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pets_on_size ON public.pets USING btree (size);


--
-- Name: index_pets_on_species; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pets_on_species ON public.pets USING btree (species);


--
-- Name: index_pets_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pets_on_status ON public.pets USING btree (status);


--
-- Name: index_saved_pets_on_pet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_saved_pets_on_pet_id ON public.saved_pets USING btree (pet_id);


--
-- Name: index_saved_pets_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_saved_pets_on_user_id ON public.saved_pets USING btree (user_id);


--
-- Name: index_saved_pets_on_user_id_and_pet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_saved_pets_on_user_id_and_pet_id ON public.saved_pets USING btree (user_id, pet_id);


--
-- Name: index_shelter_profiles_on_shelter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shelter_profiles_on_shelter_id ON public.shelter_profiles USING btree (shelter_id);


--
-- Name: index_shelter_profiles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shelter_profiles_on_user_id ON public.shelter_profiles USING btree (user_id);


--
-- Name: index_shelters_on_city; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shelters_on_city ON public.shelters USING btree (city);


--
-- Name: index_shelters_on_discarded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shelters_on_discarded_at ON public.shelters USING btree (discarded_at);


--
-- Name: index_shelters_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shelters_on_name ON public.shelters USING btree (name);


--
-- Name: index_shelters_on_species_served; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shelters_on_species_served ON public.shelters USING gin (species_served);


--
-- Name: index_shelters_on_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shelters_on_state ON public.shelters USING btree (state);


--
-- Name: index_shelters_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shelters_on_status ON public.shelters USING btree (status);


--
-- Name: index_users_on_discarded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_discarded_at ON public.users USING btree (discarded_at);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_shelter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_shelter_id ON public.users USING btree (shelter_id);


--
-- Name: notifications fk_rails_06a39bb8cc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_rails_06a39bb8cc FOREIGN KEY (actor_id) REFERENCES public.users(id);


--
-- Name: saved_pets fk_rails_0a28c104eb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_pets
    ADD CONSTRAINT fk_rails_0a28c104eb FOREIGN KEY (pet_id) REFERENCES public.pets(id);


--
-- Name: ai_documents fk_rails_19c3aeada1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_documents
    ADD CONSTRAINT fk_rails_19c3aeada1 FOREIGN KEY (shelter_id) REFERENCES public.shelters(id);


--
-- Name: password_reset_tokens fk_rails_1dfd31e72f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT fk_rails_1dfd31e72f FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: invitations fk_rails_1e69da856c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT fk_rails_1e69da856c FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: adoption_request_timeline_events fk_rails_1f09f19158; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption_request_timeline_events
    ADD CONSTRAINT fk_rails_1f09f19158 FOREIGN KEY (actor_id) REFERENCES public.users(id);


--
-- Name: adoption_notes fk_rails_2342c927c8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption_notes
    ADD CONSTRAINT fk_rails_2342c927c8 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: pets fk_rails_2976c2db1b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pets
    ADD CONSTRAINT fk_rails_2976c2db1b FOREIGN KEY (publisher_id) REFERENCES public.users(id);


--
-- Name: adoption_applications fk_rails_32b55b905c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption_applications
    ADD CONSTRAINT fk_rails_32b55b905c FOREIGN KEY (pet_id) REFERENCES public.pets(id);


--
-- Name: adoption_requests fk_rails_33a38f182a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption_requests
    ADD CONSTRAINT fk_rails_33a38f182a FOREIGN KEY (shelter_id) REFERENCES public.shelters(id);


--
-- Name: email_verification_tokens fk_rails_37a6b0cc74; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_verification_tokens
    ADD CONSTRAINT fk_rails_37a6b0cc74 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: shelter_profiles fk_rails_3f5c725229; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shelter_profiles
    ADD CONSTRAINT fk_rails_3f5c725229 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: notifications fk_rails_4aea6afa11; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_rails_4aea6afa11 FOREIGN KEY (recipient_id) REFERENCES public.users(id);


--
-- Name: users fk_rails_542555d3fe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_542555d3fe FOREIGN KEY (shelter_id) REFERENCES public.shelters(id);


--
-- Name: adoption_requests fk_rails_63b246b5b6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption_requests
    ADD CONSTRAINT fk_rails_63b246b5b6 FOREIGN KEY (pet_id) REFERENCES public.pets(id);


--
-- Name: adoption_request_timeline_events fk_rails_649dee7fbd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption_request_timeline_events
    ADD CONSTRAINT fk_rails_649dee7fbd FOREIGN KEY (adoption_request_id) REFERENCES public.adoption_requests(id);


--
-- Name: ai_document_chunks fk_rails_68e1c912ad; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_document_chunks
    ADD CONSTRAINT fk_rails_68e1c912ad FOREIGN KEY (ai_document_id) REFERENCES public.ai_documents(id);


--
-- Name: individual_profiles fk_rails_7a1d0aca47; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.individual_profiles
    ADD CONSTRAINT fk_rails_7a1d0aca47 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: shelter_profiles fk_rails_7f439233f7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shelter_profiles
    ADD CONSTRAINT fk_rails_7f439233f7 FOREIGN KEY (shelter_id) REFERENCES public.shelters(id);


--
-- Name: pets fk_rails_92fb5d7a05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pets
    ADD CONSTRAINT fk_rails_92fb5d7a05 FOREIGN KEY (shelter_id) REFERENCES public.shelters(id);


--
-- Name: notification_preferences fk_rails_9503aade25; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT fk_rails_9503aade25 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: adoption_timeline_events fk_rails_955f5ec722; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption_timeline_events
    ADD CONSTRAINT fk_rails_955f5ec722 FOREIGN KEY (adoption_application_id) REFERENCES public.adoption_applications(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: adoption_notes fk_rails_a3824c9e1b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption_notes
    ADD CONSTRAINT fk_rails_a3824c9e1b FOREIGN KEY (adoption_application_id) REFERENCES public.adoption_applications(id);


--
-- Name: adoption_requests fk_rails_c3429fd4f6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption_requests
    ADD CONSTRAINT fk_rails_c3429fd4f6 FOREIGN KEY (reviewed_by_id) REFERENCES public.users(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: adopter_insights fk_rails_ce403e6d7c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adopter_insights
    ADD CONSTRAINT fk_rails_ce403e6d7c FOREIGN KEY (adopter_id) REFERENCES public.users(id);


--
-- Name: adoption_applications fk_rails_d7b317add5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption_applications
    ADD CONSTRAINT fk_rails_d7b317add5 FOREIGN KEY (reviewed_by_id) REFERENCES public.users(id);


--
-- Name: adoption_requests fk_rails_d9eb300c0d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption_requests
    ADD CONSTRAINT fk_rails_d9eb300c0d FOREIGN KEY (adopter_id) REFERENCES public.users(id);


--
-- Name: saved_pets fk_rails_dffcaaf9cc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_pets
    ADD CONSTRAINT fk_rails_dffcaaf9cc FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: invitations fk_rails_e95ddf7ddd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT fk_rails_e95ddf7ddd FOREIGN KEY (shelter_id) REFERENCES public.shelters(id);


--
-- Name: adoption_applications fk_rails_f662c751ad; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adoption_applications
    ADD CONSTRAINT fk_rails_f662c751ad FOREIGN KEY (shelter_id) REFERENCES public.shelters(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260806020000'),
('20260806010002'),
('20260806010001'),
('20260806010000'),
('20260806000001'),
('20260720163141'),
('20260720163140'),
('20260720163139'),
('20260720163138'),
('20260720163137'),
('20260720163131'),
('20260630000001'),
('20260629030136'),
('20260625003506'),
('20260624000001'),
('20260617000003'),
('20260617000002'),
('20260617000001'),
('20260616000003'),
('20260616000002'),
('20260616000001'),
('20260615150851'),
('20260615110048'),
('20260615000008'),
('20260615000007'),
('20260615000006'),
('20260615000005'),
('20260615000004'),
('20260615000003'),
('20260615000002'),
('20260615000001');

