SET session_replication_role = replica;

--
-- PostgreSQL database dump
--

-- \restrict BhDKOdMjEfEK0UudVTDdURCDTG0J3GRshJRpzPiRgz3AU9EZhjGOsOtZTrLT9bv

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

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
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: custom_oauth_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."users" ("instance_id", "id", "aud", "role", "email", "encrypted_password", "email_confirmed_at", "invited_at", "confirmation_token", "confirmation_sent_at", "recovery_token", "recovery_sent_at", "email_change_token_new", "email_change", "email_change_sent_at", "last_sign_in_at", "raw_app_meta_data", "raw_user_meta_data", "is_super_admin", "created_at", "updated_at", "phone", "phone_confirmed_at", "phone_change", "phone_change_token", "phone_change_sent_at", "email_change_token_current", "email_change_confirm_status", "banned_until", "reauthentication_token", "reauthentication_sent_at", "is_sso_user", "deleted_at", "is_anonymous") VALUES
	('00000000-0000-0000-0000-000000000000', '2866b6ea-1e11-4dcd-9047-dde0f2721fb4', 'authenticated', 'authenticated', 'staff@ssrs.com', '$2a$10$DlMkiQA85DAd8LJUtX9l3.T4CU.ySLfjFYTPj1pf2YS3U1dAoGLcu', '2026-07-09 12:52:03.402942+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-07-10 06:22:43.46997+00', '{"provider": "email", "providers": ["email"]}', '{"role": "staff", "username": "staff_ssrs", "display_name": "Staff SSRS", "email_verified": true}', NULL, '2026-07-09 12:52:03.400081+00', '2026-07-10 06:22:43.490471+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false),
	('00000000-0000-0000-0000-000000000000', '0b24942d-0684-42cc-accd-294715e91c1b', 'authenticated', 'authenticated', 'test-70792068@ssrs.com', '$2a$10$oDl9kgN0WqoM3q7CQMfPvuhLlFzo/8Cj1Bzopy93zLblpGr5xgL/6', NULL, NULL, '', NULL, '', NULL, '', '', NULL, NULL, '{"provider": "email", "providers": ["email"]}', '{"role": "staff"}', NULL, '2026-07-09 12:24:50.905232+00', '2026-07-09 12:24:50.947475+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false),
	('00000000-0000-0000-0000-000000000000', 'ce1a8458-41b7-4052-9fff-4ba6fcfbb9a6', 'authenticated', 'authenticated', 'manager@ssrs.com', '$2a$10$dqTdUtfo8TVrW4yfxyMST.qvTWyBzdTFX/9sBKHql7ffzaZvaoz7e', '2026-07-09 12:52:03.253845+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-07-10 07:23:26.779544+00', '{"provider": "email", "providers": ["email"]}', '{"role": "manager", "username": "manager_ssrs", "display_name": "Manager SSRS", "email_verified": true}', NULL, '2026-07-09 12:52:03.246284+00', '2026-07-10 07:23:26.78242+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false),
	('00000000-0000-0000-0000-000000000000', '46670f60-2eb4-4526-add8-c04d439267e0', 'authenticated', 'authenticated', 'owner@ssrs.com', '$2a$10$0RfsFt7PzIDaQUrx4kcqC.nesZqrfaU/I94TV1H7LU3zBIGSovbtC', '2026-07-09 12:52:03.108387+00', NULL, '', NULL, '', NULL, '', '', NULL, '2026-07-10 07:23:45.34101+00', '{"provider": "email", "providers": ["email"]}', '{"role": "owner", "username": "owner_ssrs", "display_name": "Owner SSRS", "email_verified": true}', NULL, '2026-07-09 12:52:03.079198+00', '2026-07-10 08:27:32.162026+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."identities" ("provider_id", "user_id", "identity_data", "provider", "last_sign_in_at", "created_at", "updated_at", "id") VALUES
	('0b24942d-0684-42cc-accd-294715e91c1b', '0b24942d-0684-42cc-accd-294715e91c1b', '{"sub": "0b24942d-0684-42cc-accd-294715e91c1b", "email": "test-70792068@ssrs.com", "email_verified": false, "phone_verified": false}', 'email', '2026-07-09 12:24:50.94502+00', '2026-07-09 12:24:50.945087+00', '2026-07-09 12:24:50.945087+00', 'e69940df-db38-4856-8858-99f12bdccd75'),
	('46670f60-2eb4-4526-add8-c04d439267e0', '46670f60-2eb4-4526-add8-c04d439267e0', '{"sub": "46670f60-2eb4-4526-add8-c04d439267e0", "email": "owner@ssrs.com", "email_verified": false, "phone_verified": false}', 'email', '2026-07-09 12:52:03.105024+00', '2026-07-09 12:52:03.105083+00', '2026-07-09 12:52:03.105083+00', 'd77fb3a3-0e49-4c9b-80ba-92dfffca32ef'),
	('ce1a8458-41b7-4052-9fff-4ba6fcfbb9a6', 'ce1a8458-41b7-4052-9fff-4ba6fcfbb9a6', '{"sub": "ce1a8458-41b7-4052-9fff-4ba6fcfbb9a6", "email": "manager@ssrs.com", "email_verified": false, "phone_verified": false}', 'email', '2026-07-09 12:52:03.247803+00', '2026-07-09 12:52:03.247851+00', '2026-07-09 12:52:03.247851+00', '7b9e4c0d-ca56-4d59-b378-86bbd12d3df1'),
	('2866b6ea-1e11-4dcd-9047-dde0f2721fb4', '2866b6ea-1e11-4dcd-9047-dde0f2721fb4', '{"sub": "2866b6ea-1e11-4dcd-9047-dde0f2721fb4", "email": "staff@ssrs.com", "email_verified": false, "phone_verified": false}', 'email', '2026-07-09 12:52:03.40141+00', '2026-07-09 12:52:03.401455+00', '2026-07-09 12:52:03.401455+00', '08b10ef7-f4f8-446b-b82a-c527b44029a6');


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."sessions" ("id", "user_id", "created_at", "updated_at", "factor_id", "aal", "not_after", "refreshed_at", "user_agent", "ip", "tag", "oauth_client_id", "refresh_token_hmac_key", "refresh_token_counter", "scopes") VALUES
	('1cd27127-30f9-4436-a140-83dbe0ad299d', 'ce1a8458-41b7-4052-9fff-4ba6fcfbb9a6', '2026-07-09 12:52:06.343151+00', '2026-07-09 12:52:06.343151+00', NULL, 'aal1', NULL, NULL, NULL, '103.130.18.35', NULL, NULL, NULL, NULL, NULL),
	('ab7404c5-f0b8-4f5f-a989-f8702c3430c7', '2866b6ea-1e11-4dcd-9047-dde0f2721fb4', '2026-07-09 12:52:06.48767+00', '2026-07-09 12:52:06.48767+00', NULL, 'aal1', NULL, NULL, NULL, '103.130.18.35', NULL, NULL, NULL, NULL, NULL),
	('3fa1d0dd-49df-4f3e-9a04-726043e82149', 'ce1a8458-41b7-4052-9fff-4ba6fcfbb9a6', '2026-07-09 19:56:58.728647+00', '2026-07-09 19:56:58.728647+00', NULL, 'aal1', NULL, NULL, 'Dart/3.12 (dart:io)', '103.130.18.35', NULL, NULL, NULL, NULL, NULL),
	('11409f2f-1d1d-4fc0-9bb5-93598f11decf', '46670f60-2eb4-4526-add8-c04d439267e0', '2026-07-09 19:47:01.350421+00', '2026-07-09 20:46:32.969942+00', NULL, 'aal1', NULL, '2026-07-09 20:46:32.969823', 'Dart/3.12 (dart:io)', '103.130.18.35', NULL, NULL, NULL, NULL, NULL),
	('7f709470-3742-4215-ae3a-8905425e878e', '46670f60-2eb4-4526-add8-c04d439267e0', '2026-07-10 04:40:54.277199+00', '2026-07-10 04:40:54.277199+00', NULL, 'aal1', NULL, NULL, 'Dart/3.12 (dart:io)', '103.130.18.129', NULL, NULL, NULL, NULL, NULL),
	('824cb18e-2069-41b5-8fa8-6857ff0acfa2', '46670f60-2eb4-4526-add8-c04d439267e0', '2026-07-10 05:12:32.068309+00', '2026-07-10 05:12:32.068309+00', NULL, 'aal1', NULL, NULL, 'Dart/3.12 (dart:io)', '103.130.18.129', NULL, NULL, NULL, NULL, NULL),
	('e5bbe629-0469-46ef-8943-1f2fda7fc911', '46670f60-2eb4-4526-add8-c04d439267e0', '2026-07-10 07:08:54.92762+00', '2026-07-10 07:08:54.92762+00', NULL, 'aal1', NULL, NULL, 'Dart/3.12 (dart:io)', '103.130.18.129', NULL, NULL, NULL, NULL, NULL),
	('f3df9030-a187-4831-b5fc-4e878aabeb50', '2866b6ea-1e11-4dcd-9047-dde0f2721fb4', '2026-07-09 13:43:51.171853+00', '2026-07-09 13:43:51.171853+00', NULL, 'aal1', NULL, NULL, 'Dart/3.12 (dart:io)', '103.130.18.35', NULL, NULL, NULL, NULL, NULL),
	('a0c83f31-3804-4c19-ba8f-e77d601caa85', 'ce1a8458-41b7-4052-9fff-4ba6fcfbb9a6', '2026-07-10 07:23:23.584882+00', '2026-07-10 07:23:23.584882+00', NULL, 'aal1', NULL, NULL, 'Dart/3.12 (dart:io)', '103.130.18.129', NULL, NULL, NULL, NULL, NULL),
	('0ad249a3-aafa-4da4-a595-4b601622b533', 'ce1a8458-41b7-4052-9fff-4ba6fcfbb9a6', '2026-07-09 14:11:38.053189+00', '2026-07-09 14:11:38.053189+00', NULL, 'aal1', NULL, NULL, 'Dart/3.12 (dart:io)', '103.130.18.35', NULL, NULL, NULL, NULL, NULL),
	('fb43256d-dc82-42c8-8e39-e8df61af6100', 'ce1a8458-41b7-4052-9fff-4ba6fcfbb9a6', '2026-07-10 07:23:25.759287+00', '2026-07-10 07:23:25.759287+00', NULL, 'aal1', NULL, NULL, 'Dart/3.12 (dart:io)', '103.130.18.129', NULL, NULL, NULL, NULL, NULL),
	('a43f0695-d4c1-4dec-a823-34219eb3b8b8', 'ce1a8458-41b7-4052-9fff-4ba6fcfbb9a6', '2026-07-10 07:23:26.779631+00', '2026-07-10 07:23:26.779631+00', NULL, 'aal1', NULL, NULL, 'Dart/3.12 (dart:io)', '103.130.18.129', NULL, NULL, NULL, NULL, NULL),
	('c690d468-211b-4e17-bcaa-785233df3776', '46670f60-2eb4-4526-add8-c04d439267e0', '2026-07-10 07:23:45.341095+00', '2026-07-10 07:23:45.341095+00', NULL, 'aal1', NULL, NULL, 'Dart/3.12 (dart:io)', '103.130.18.129', NULL, NULL, NULL, NULL, NULL),
	('b71f9d34-fadc-4ab6-921c-3b3929ba6525', '46670f60-2eb4-4526-add8-c04d439267e0', '2026-07-10 07:09:56.971462+00', '2026-07-10 08:27:32.174502+00', NULL, 'aal1', NULL, '2026-07-10 08:27:32.174396', 'Dart/3.12 (dart:io)', '103.130.18.129', NULL, NULL, NULL, NULL, NULL),
	('0afe4c01-39bd-4609-a0f9-6389fc853d40', '46670f60-2eb4-4526-add8-c04d439267e0', '2026-07-09 16:09:58.531636+00', '2026-07-09 17:35:48.390753+00', NULL, 'aal1', NULL, '2026-07-09 17:35:48.390652', 'Dart/3.12 (dart:io)', '103.130.18.35', NULL, NULL, NULL, NULL, NULL),
	('f9003d83-4770-4993-927b-6f18efa9611f', '46670f60-2eb4-4526-add8-c04d439267e0', '2026-07-09 17:36:49.698133+00', '2026-07-09 17:36:49.698133+00', NULL, 'aal1', NULL, NULL, 'Dart/3.12 (dart:io)', '103.130.18.35', NULL, NULL, NULL, NULL, NULL),
	('a2cd2aca-9d8f-48d7-8f59-33ac7fcde894', '46670f60-2eb4-4526-add8-c04d439267e0', '2026-07-09 17:53:33.352435+00', '2026-07-09 19:00:44.854389+00', NULL, 'aal1', NULL, '2026-07-09 19:00:44.854278', 'Dart/3.12 (dart:io)', '103.130.18.35', NULL, NULL, NULL, NULL, NULL);


--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."mfa_amr_claims" ("session_id", "created_at", "updated_at", "authentication_method", "id") VALUES
	('3fa1d0dd-49df-4f3e-9a04-726043e82149', '2026-07-09 19:56:58.745886+00', '2026-07-09 19:56:58.745886+00', 'password', 'faee8ee4-b004-49e3-a8d2-7ede59509b4f'),
	('1cd27127-30f9-4436-a140-83dbe0ad299d', '2026-07-09 12:52:06.345604+00', '2026-07-09 12:52:06.345604+00', 'password', '4e2c32b7-9c90-4155-abeb-805c89c52e59'),
	('ab7404c5-f0b8-4f5f-a989-f8702c3430c7', '2026-07-09 12:52:06.490139+00', '2026-07-09 12:52:06.490139+00', 'password', 'dda8ccb8-7d0c-4472-afb4-699014a88acb'),
	('7f709470-3742-4215-ae3a-8905425e878e', '2026-07-10 04:40:54.290278+00', '2026-07-10 04:40:54.290278+00', 'password', '908d424e-fbd9-46ed-b156-000672da8e2d'),
	('824cb18e-2069-41b5-8fa8-6857ff0acfa2', '2026-07-10 05:12:32.110259+00', '2026-07-10 05:12:32.110259+00', 'password', 'bec0e3d9-53ef-4595-a733-6b9fc5b2e3a6'),
	('e5bbe629-0469-46ef-8943-1f2fda7fc911', '2026-07-10 07:08:54.975878+00', '2026-07-10 07:08:54.975878+00', 'password', 'ec456102-4f34-4657-9b83-efda1cfe25b3'),
	('b71f9d34-fadc-4ab6-921c-3b3929ba6525', '2026-07-10 07:09:56.976547+00', '2026-07-10 07:09:56.976547+00', 'password', '386c0bcd-7bc5-4083-8e9b-981c708aecd4'),
	('a0c83f31-3804-4c19-ba8f-e77d601caa85', '2026-07-10 07:23:23.606194+00', '2026-07-10 07:23:23.606194+00', 'password', '3ee15660-5247-4461-a243-1e1a1a338881'),
	('fb43256d-dc82-42c8-8e39-e8df61af6100', '2026-07-10 07:23:25.761881+00', '2026-07-10 07:23:25.761881+00', 'password', 'fffa5960-7ce3-4552-8096-3f73243a7936'),
	('a43f0695-d4c1-4dec-a823-34219eb3b8b8', '2026-07-10 07:23:26.782831+00', '2026-07-10 07:23:26.782831+00', 'password', '031af63a-4489-4784-a97d-490b4d8434f4'),
	('c690d468-211b-4e17-bcaa-785233df3776', '2026-07-10 07:23:45.343571+00', '2026-07-10 07:23:45.343571+00', 'password', '3d8dc519-d7fb-4c80-9fd8-28e70d4da013'),
	('f3df9030-a187-4831-b5fc-4e878aabeb50', '2026-07-09 13:43:51.200597+00', '2026-07-09 13:43:51.200597+00', 'password', '637477af-6f37-452d-87db-0a92ded7c1e3'),
	('0ad249a3-aafa-4da4-a595-4b601622b533', '2026-07-09 14:11:38.063453+00', '2026-07-09 14:11:38.063453+00', 'password', '15e2664c-1ea4-43a3-9fdc-9a1c0ce7ada6'),
	('0afe4c01-39bd-4609-a0f9-6389fc853d40', '2026-07-09 16:09:58.548538+00', '2026-07-09 16:09:58.548538+00', 'password', '24a8ea17-178e-4483-a548-f02d2dd7252e'),
	('f9003d83-4770-4993-927b-6f18efa9611f', '2026-07-09 17:36:49.723853+00', '2026-07-09 17:36:49.723853+00', 'password', '3c747507-a3ed-4a8e-9fa8-26d38f61829e'),
	('a2cd2aca-9d8f-48d7-8f59-33ac7fcde894', '2026-07-09 17:53:33.385388+00', '2026-07-09 17:53:33.385388+00', 'password', 'e7c17079-6063-4783-a1d8-1a329d4e883b'),
	('11409f2f-1d1d-4fc0-9bb5-93598f11decf', '2026-07-09 19:47:01.367389+00', '2026-07-09 19:47:01.367389+00', 'password', 'f6b8e0d4-7c9f-4a63-9b6f-ba2d4e4645f7');


--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_authorizations; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_client_states; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_consents; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."refresh_tokens" ("instance_id", "id", "token", "user_id", "revoked", "created_at", "updated_at", "parent", "session_id") VALUES
	('00000000-0000-0000-0000-000000000000', 5, 'rt3wuyzgzqul', 'ce1a8458-41b7-4052-9fff-4ba6fcfbb9a6', false, '2026-07-09 12:52:06.344242+00', '2026-07-09 12:52:06.344242+00', NULL, '1cd27127-30f9-4436-a140-83dbe0ad299d'),
	('00000000-0000-0000-0000-000000000000', 6, '3wanhww23q6r', '2866b6ea-1e11-4dcd-9047-dde0f2721fb4', false, '2026-07-09 12:52:06.488741+00', '2026-07-09 12:52:06.488741+00', NULL, 'ab7404c5-f0b8-4f5f-a989-f8702c3430c7'),
	('00000000-0000-0000-0000-000000000000', 66, 'wqznegx4aude', 'ce1a8458-41b7-4052-9fff-4ba6fcfbb9a6', false, '2026-07-09 19:56:58.74054+00', '2026-07-09 19:56:58.74054+00', NULL, '3fa1d0dd-49df-4f3e-9a04-726043e82149'),
	('00000000-0000-0000-0000-000000000000', 65, 'icir2cb6awk5', '46670f60-2eb4-4526-add8-c04d439267e0', true, '2026-07-09 19:47:01.363542+00', '2026-07-09 20:46:32.950473+00', NULL, '11409f2f-1d1d-4fc0-9bb5-93598f11decf'),
	('00000000-0000-0000-0000-000000000000', 68, 'nokrwdp2aohi', '46670f60-2eb4-4526-add8-c04d439267e0', false, '2026-07-09 20:46:32.956922+00', '2026-07-09 20:46:32.956922+00', 'icir2cb6awk5', '11409f2f-1d1d-4fc0-9bb5-93598f11decf'),
	('00000000-0000-0000-0000-000000000000', 85, '5qh7xrj3vtjp', '46670f60-2eb4-4526-add8-c04d439267e0', false, '2026-07-10 04:40:54.285645+00', '2026-07-10 04:40:54.285645+00', NULL, '7f709470-3742-4215-ae3a-8905425e878e'),
	('00000000-0000-0000-0000-000000000000', 38, 'v3hhoizzhco7', '2866b6ea-1e11-4dcd-9047-dde0f2721fb4', false, '2026-07-09 13:43:51.193118+00', '2026-07-09 13:43:51.193118+00', NULL, 'f3df9030-a187-4831-b5fc-4e878aabeb50'),
	('00000000-0000-0000-0000-000000000000', 89, 'bkoqwkbagkqy', '46670f60-2eb4-4526-add8-c04d439267e0', false, '2026-07-10 05:12:32.097355+00', '2026-07-10 05:12:32.097355+00', NULL, '824cb18e-2069-41b5-8fa8-6857ff0acfa2'),
	('00000000-0000-0000-0000-000000000000', 43, 'wrgrht4rjik7', 'ce1a8458-41b7-4052-9fff-4ba6fcfbb9a6', false, '2026-07-09 14:11:38.060148+00', '2026-07-09 14:11:38.060148+00', NULL, '0ad249a3-aafa-4da4-a595-4b601622b533'),
	('00000000-0000-0000-0000-000000000000', 95, 'fcgv3jdyyxc2', '46670f60-2eb4-4526-add8-c04d439267e0', false, '2026-07-10 07:08:54.961754+00', '2026-07-10 07:08:54.961754+00', NULL, 'e5bbe629-0469-46ef-8943-1f2fda7fc911'),
	('00000000-0000-0000-0000-000000000000', 100, 'zk2alhiws2nz', 'ce1a8458-41b7-4052-9fff-4ba6fcfbb9a6', false, '2026-07-10 07:23:23.602063+00', '2026-07-10 07:23:23.602063+00', NULL, 'a0c83f31-3804-4c19-ba8f-e77d601caa85'),
	('00000000-0000-0000-0000-000000000000', 101, 'tizmigllmksf', 'ce1a8458-41b7-4052-9fff-4ba6fcfbb9a6', false, '2026-07-10 07:23:25.760556+00', '2026-07-10 07:23:25.760556+00', NULL, 'fb43256d-dc82-42c8-8e39-e8df61af6100'),
	('00000000-0000-0000-0000-000000000000', 102, 'slieqemwkges', 'ce1a8458-41b7-4052-9fff-4ba6fcfbb9a6', false, '2026-07-10 07:23:26.781424+00', '2026-07-10 07:23:26.781424+00', NULL, 'a43f0695-d4c1-4dec-a823-34219eb3b8b8'),
	('00000000-0000-0000-0000-000000000000', 103, 'cfmir7dg5uw2', '46670f60-2eb4-4526-add8-c04d439267e0', false, '2026-07-10 07:23:45.342202+00', '2026-07-10 07:23:45.342202+00', NULL, 'c690d468-211b-4e17-bcaa-785233df3776'),
	('00000000-0000-0000-0000-000000000000', 50, '5cwae66qatyo', '46670f60-2eb4-4526-add8-c04d439267e0', true, '2026-07-09 16:09:58.544384+00', '2026-07-09 17:35:48.35769+00', NULL, '0afe4c01-39bd-4609-a0f9-6389fc853d40'),
	('00000000-0000-0000-0000-000000000000', 55, '6mej7ez76o2s', '46670f60-2eb4-4526-add8-c04d439267e0', false, '2026-07-09 17:35:48.371835+00', '2026-07-09 17:35:48.371835+00', '5cwae66qatyo', '0afe4c01-39bd-4609-a0f9-6389fc853d40'),
	('00000000-0000-0000-0000-000000000000', 56, 'sg7gybkxiexj', '46670f60-2eb4-4526-add8-c04d439267e0', false, '2026-07-09 17:36:49.717453+00', '2026-07-09 17:36:49.717453+00', NULL, 'f9003d83-4770-4993-927b-6f18efa9611f'),
	('00000000-0000-0000-0000-000000000000', 96, 'gw6exfm6zrsb', '46670f60-2eb4-4526-add8-c04d439267e0', true, '2026-07-10 07:09:56.973985+00', '2026-07-10 08:27:32.141863+00', NULL, 'b71f9d34-fadc-4ab6-921c-3b3929ba6525'),
	('00000000-0000-0000-0000-000000000000', 57, 'l4mgc2qwa3y2', '46670f60-2eb4-4526-add8-c04d439267e0', true, '2026-07-09 17:53:33.378535+00', '2026-07-09 19:00:44.825551+00', NULL, 'a2cd2aca-9d8f-48d7-8f59-33ac7fcde894'),
	('00000000-0000-0000-0000-000000000000', 59, '5zr3cr5yvxhr', '46670f60-2eb4-4526-add8-c04d439267e0', false, '2026-07-09 19:00:44.836024+00', '2026-07-09 19:00:44.836024+00', 'l4mgc2qwa3y2', 'a2cd2aca-9d8f-48d7-8f59-33ac7fcde894'),
	('00000000-0000-0000-0000-000000000000', 104, 'xkb6jmfw76im', '46670f60-2eb4-4526-add8-c04d439267e0', false, '2026-07-10 08:27:32.154405+00', '2026-07-10 08:27:32.154405+00', 'gw6exfm6zrsb', 'b71f9d34-fadc-4ab6-921c-3b3929ba6525');


--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: webauthn_challenges; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: webauthn_credentials; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: businesses; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."businesses" ("id", "name", "description", "qris_image_url", "created_at", "updated_at") OVERRIDING SYSTEM VALUE VALUES
	(1, 'Agen Milagros', 'Bangunan samping bengkel', 'https://vebjqkmzxelvlgyheyix.supabase.co/storage/v1/object/public/qris-images/qris_shared.jpg', '2026-07-09 12:52:01.618706+00', '2026-07-10 12:18:05.54516+00'),
	(2, 'Teh Solo', 'Jl.Swakarsa 3 Pondok Kelapa', 'https://vebjqkmzxelvlgyheyix.supabase.co/storage/v1/object/public/qris-images/qris_shared.jpg', '2026-07-09 12:52:01.618706+00', '2026-07-10 10:37:44.453875+00'),
	(3, 'Warung Kopi', 'Jl.Swakarsa 3 Pondok Kelapa', 'https://vebjqkmzxelvlgyheyix.supabase.co/storage/v1/object/public/qris-images/qris_shared.jpg', '2026-07-09 12:52:01.618706+00', '2026-07-10 10:37:44.369264+00');


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."categories" ("id", "business_id", "name", "type", "created_at", "updated_at") OVERRIDING SYSTEM VALUE VALUES
	(1, 1, 'Penjualan Harian', 'income', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(2, 1, 'Penjualan Grosir', 'income', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(3, 1, 'Pendapatan Lain', 'income', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(4, 1, 'Bahan Baku', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(5, 1, 'Operasional', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(6, 1, 'Transportasi', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(7, 1, 'Lain-lain', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(8, 2, 'Penjualan Harian', 'income', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(9, 2, 'Penjualan Grosir', 'income', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(10, 2, 'Pendapatan Lain', 'income', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(11, 2, 'Bahan Baku', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(12, 2, 'Operasional', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(13, 2, 'Transportasi', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(14, 2, 'Lain-lain', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(15, 3, 'Penjualan Harian', 'income', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(16, 3, 'Penjualan Grosir', 'income', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(17, 3, 'Pendapatan Lain', 'income', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(18, 3, 'Bahan Baku', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(19, 3, 'Operasional', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(20, 3, 'Gaji Karyawan', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(21, 3, 'Transportasi', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(22, 3, 'Lain-lain', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00');


--
-- Data for Name: financial_reports; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."users" ("id", "email", "username", "display_name", "avatar_url", "role", "is_active", "created_at", "updated_at", "password_hash") VALUES
	('129e4811-8202-44d0-b723-1c0d06501109', 'pakasep@gmail.com', 'pasep123', 'Pak Asep', NULL, 'staff', true, '2026-07-10 09:32:26.257297+00', '2026-07-10 10:18:21.403609+00', '$2a$06$bUuUoieIP6YytAn0cqwxO.mMOF5siuIxDoLQ1/psrjo.iatYqmqiG'),
	('46670f60-2eb4-4526-add8-c04d439267e0', 'syahr642@gmail.com', 'syahr642', 'Rohman Syah', NULL, 'owner', true, '2026-07-09 12:52:03.078035+00', '2026-07-10 09:08:24.50483+00', '$2a$06$1/vm5I.b0z4e2U0qgRLNw.7Qn11Ie7Pw6qdxvBmTKdytbprD/kLCK'),
	('777a74e4-e53d-4a75-81bc-9b088c61317f', 'sitiomanaja123@gmail.com', 'sitiaja123', 'Siti Sururoh', NULL, 'owner', true, '2026-07-10 08:49:58.467873+00', '2026-07-10 09:08:20.083073+00', '$2a$06$.5JA30ej5lCdhUPNe1fw7Orgig4mcUfDKRz5YHbY53igHlZRJEzLa'),
	('8632b4e5-bbfb-4bc6-952e-ea0761f8c1d1', 'test@gmail.com', 'testing', 'tester', NULL, 'manager', true, '2026-07-10 12:39:57.22976+00', '2026-07-10 12:39:57.494162+00', '$2a$06$hamij2fyP06vJ86oypVIWOMHf1inD1UjDzKKaCnAjL36ud/eS9aEC'),
	('d0000000-0000-0000-0000-000000000001', 'miselsaas@gmail.com', 'miselsaas', 'Miselsa Anisdria', NULL, 'owner', true, '2026-07-10 08:34:07.242104+00', '2026-07-10 09:08:13.356223+00', '$2a$06$j.uVeDQiMQgWFPliyxKnk.cGYA3H91wdXj9URiMWcIooQipz2eU4.'),
	('fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'andri@gmail.com', 'andri', 'Andri', NULL, 'staff', true, '2026-07-10 09:33:10.518645+00', '2026-07-10 09:33:10.640046+00', '$2a$06$v7r.z2hl6.QjXfcMZzi7/.FdF41smzKyyBw/nV9j/W2wpSaEo8xWq');


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."transactions" ("id", "business_id", "category_id", "user_id", "type", "amount", "cogs", "payment_method", "description", "transaction_date", "status_sync", "created_at", "updated_at") OVERRIDING SYSTEM VALUE VALUES
	(1, 3, 17, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'income', 68000.00, 0.00, 'cash', '', '2026-07-05', true, '2026-07-10 12:25:47.877431+00', '2026-07-10 12:25:47.877431+00'),
	(2, 3, 17, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'income', 88000.00, 0.00, 'cash', '', '2026-07-06', true, '2026-07-10 12:26:34.699188+00', '2026-07-10 12:26:34.699188+00'),
	(3, 3, 17, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'income', 196000.00, 0.00, 'cash', '', '2026-07-07', true, '2026-07-10 12:28:52.024729+00', '2026-07-10 12:28:52.024729+00'),
	(4, 3, 17, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'income', 183000.00, 0.00, 'cash', '', '2026-07-08', true, '2026-07-10 12:29:59.555639+00', '2026-07-10 12:29:59.555639+00'),
	(5, 3, 17, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'income', 341000.00, 0.00, 'cash', '', '2026-07-09', true, '2026-07-10 12:30:56.220519+00', '2026-07-10 12:30:56.220519+00'),
	(6, 3, 17, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'income', 174000.00, 0.00, 'cash', '', '2026-07-10', true, '2026-07-10 12:32:18.954938+00', '2026-07-10 12:32:18.954938+00'),
	(7, 3, 20, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'expense', 85000.00, 0.00, 'cash', '', '2026-07-05', true, '2026-07-10 12:34:36.672928+00', '2026-07-10 12:34:36.672928+00'),
	(8, 3, 20, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'expense', 439000.00, 0.00, 'cash', '', '2026-07-06', true, '2026-07-10 12:36:01.324517+00', '2026-07-10 12:36:01.324517+00'),
	(9, 3, 20, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'expense', 55000.00, 0.00, 'cash', '', '2026-07-07', true, '2026-07-10 12:37:14.133197+00', '2026-07-10 12:37:14.133197+00'),
	(10, 3, 20, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'expense', 23000.00, 0.00, 'cash', '', '2026-07-08', true, '2026-07-10 12:39:04.88355+00', '2026-07-10 12:39:04.88355+00'),
	(11, 3, 20, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'expense', 306000.00, 0.00, 'cash', '', '2026-07-09', true, '2026-07-10 12:40:53.315561+00', '2026-07-10 12:40:53.315561+00'),
	(12, 3, 20, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'expense', 280000.00, 0.00, 'cash', '', '2026-07-10', true, '2026-07-10 12:42:13.134553+00', '2026-07-10 12:42:13.134553+00');


--
-- Data for Name: user_businesses; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."user_businesses" ("id", "user_id", "business_id", "created_at") OVERRIDING SYSTEM VALUE VALUES
	(1, '46670f60-2eb4-4526-add8-c04d439267e0', 1, '2026-07-09 12:52:03.635865+00'),
	(2, '46670f60-2eb4-4526-add8-c04d439267e0', 2, '2026-07-09 12:52:03.635865+00'),
	(3, '46670f60-2eb4-4526-add8-c04d439267e0', 3, '2026-07-09 12:52:03.635865+00'),
	(4, '129e4811-8202-44d0-b723-1c0d06501109', 2, '2026-07-10 09:32:32.014906+00'),
	(5, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 3, '2026-07-10 09:33:14.32703+00'),
	(6, '8632b4e5-bbfb-4bc6-952e-ea0761f8c1d1', 3, '2026-07-10 12:40:17.993259+00'),
	(7, '8632b4e5-bbfb-4bc6-952e-ea0761f8c1d1', 2, '2026-07-10 12:40:23.235385+00');


--
-- Data for Name: buckets; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

INSERT INTO "storage"."buckets" ("id", "name", "owner", "created_at", "updated_at", "public", "avif_autodetection", "file_size_limit", "allowed_mime_types", "owner_id", "type") VALUES
	('qris-images', 'qris-images', NULL, '2026-07-09 10:34:12.243189+00', '2026-07-09 10:34:12.243189+00', true, false, 5242880, '{image/png,image/jpeg,image/svg+xml,image/webp,image/heic,image/heif}', NULL, 'STANDARD');


--
-- Data for Name: buckets_analytics; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: buckets_vectors; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: objects; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

INSERT INTO "storage"."objects" ("id", "bucket_id", "name", "owner", "created_at", "updated_at", "last_accessed_at", "metadata", "version", "owner_id", "user_metadata") VALUES
	('16ca5dfa-daa4-416e-87ac-b5c95889bb74', 'qris-images', 'qris_shared.jpg', NULL, '2026-07-10 10:37:44.079915+00', '2026-07-10 10:37:44.079915+00', '2026-07-10 10:37:44.079915+00', '{"eTag": "\"d0ffdbef93a0cacd8fd48a5e1daaf975\"", "size": 97092, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-10T10:37:45.000Z", "contentLength": 97092, "httpStatusCode": 200}', 'd515d287-60df-4096-ae43-c8bc9de64a58', NULL, '{}');


--
-- Data for Name: s3_multipart_uploads; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: s3_multipart_uploads_parts; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: vector_indexes; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: supabase_auth_admin
--

SELECT pg_catalog.setval('"auth"."refresh_tokens_id_seq"', 104, true);


--
-- Name: businesses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"public"."businesses_id_seq"', 3, true);


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"public"."categories_id_seq"', 22, true);


--
-- Name: financial_reports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"public"."financial_reports_id_seq"', 1, false);


--
-- Name: transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"public"."transactions_id_seq"', 12, true);


--
-- Name: user_businesses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"public"."user_businesses_id_seq"', 7, true);


--
-- PostgreSQL database dump complete
--

-- \unrestrict BhDKOdMjEfEK0UudVTDdURCDTG0J3GRshJRpzPiRgz3AU9EZhjGOsOtZTrLT9bv

RESET ALL;
