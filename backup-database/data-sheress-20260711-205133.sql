SET session_replication_role = replica;

--
-- PostgreSQL database dump
--

-- \restrict uAhH3Wl1FalwFjAF0WKwRsCkjpGDU7imhZRvbQzy1HYeuVOZZwbjyFIrQqIeBJQ

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
	(NULL, '46670f60-2eb4-4526-add8-c04d439267e0', NULL, NULL, 'syahr642@gmail.com', '$2a$06$r6eSmG06s6IUBgTb8mYFWeln8A92XnYlb6pIPF1xcyfzu0v1ozkJC', '2026-07-11 12:27:34.082977+00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"provider": "email", "providers": ["email"]}', '{"role": "owner", "username": "syahr642", "display_name": "Rohman Syah"}', NULL, '2026-07-11 12:27:34.082977+00', '2026-07-11 12:27:34.082977+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



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
	(7, 1, 'Transportasi', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(8, 1, 'Lain-lain', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(9, 2, 'Penjualan Harian', 'income', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(10, 2, 'Penjualan Grosir', 'income', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(11, 2, 'Pendapatan Lain', 'income', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(12, 2, 'Bahan Baku', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(13, 2, 'Operasional', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(15, 2, 'Transportasi', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(16, 2, 'Lain-lain', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(17, 3, 'Penjualan Harian', 'income', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(18, 3, 'Penjualan Grosir', 'income', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(19, 3, 'Pendapatan Lain', 'income', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(20, 3, 'Bahan Baku', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(21, 3, 'Operasional', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(22, 3, 'Gaji Karyawan', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(23, 3, 'Transportasi', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(24, 3, 'Lain-lain', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00');


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."users" ("id", "email", "username", "display_name", "avatar_url", "role", "is_active", "created_at", "updated_at", "password_hash") VALUES
	('46670f60-2eb4-4526-add8-c04d439267e0', 'syahr642@gmail.com', 'syahr642', 'Rohman Syah', NULL, 'owner', true, '2026-07-09 12:52:03.078035+00', '2026-07-11 12:27:34.082977+00', '$2a$06$7CLK.3y1FwclozSQHlrSTe57jDdFjzUcUY6KOPcvtgDakXtJB7wnW'),
	('129e4811-8202-44d0-b723-1c0d06501109', 'pakasep@gmail.com', 'pasep123', 'Pak Asep', NULL, 'staff', true, '2026-07-10 09:32:26.257297+00', '2026-07-11 12:33:08.913035+00', '$2a$06$/p19oxamay1lrsXt8azDYeNO0N4dYUz9hsoJejcAjRWt31ECtHUna'),
	('777a74e4-e53d-4a75-81bc-9b088c61317f', 'sitiomanaja123@gmail.com', 'sitiaja123', 'Siti Sururoh', NULL, 'owner', true, '2026-07-10 08:49:58.467873+00', '2026-07-11 12:33:08.913035+00', '$2a$06$A5k/DzvQel9svQvPQM14p.ZFz8RnKTCZsI8rGGKRSYd2TNsKLJgQW'),
	('8632b4e5-bbfb-4bc6-952e-ea0761f8c1d1', 'test@gmail.com', 'testing', 'tester', NULL, 'manager', true, '2026-07-10 12:39:57.22976+00', '2026-07-11 12:33:08.913035+00', '$2a$06$a563cCgu.rpHY.fbktlNw..b19k/b3bADLH.ppev61LbbOXRaq3Ja'),
	('d0000000-0000-0000-0000-000000000001', 'miselsaas@gmail.com', 'miselsaas', 'Miselsa Anisdria', NULL, 'owner', true, '2026-07-10 08:34:07.242104+00', '2026-07-11 12:33:08.913035+00', '$2a$06$1bO9Ptsydd5tVrk/OmXx1OLrmznjcBOwfWEQXvJhkdnehNIGQK7ja'),
	('fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'andri@gmail.com', 'andri', 'Andri', NULL, 'staff', true, '2026-07-10 09:33:10.518645+00', '2026-07-11 12:33:08.913035+00', '$2a$06$.l.TBdhHFCe8dcZEs5lIo.e5SMkI4EHcoRmU70Pw4PY0/sJ3RLArG');


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."transactions" ("id", "business_id", "category_id", "user_id", "type", "amount", "cogs", "payment_method", "description", "transaction_date", "status_sync", "created_at", "updated_at") OVERRIDING SYSTEM VALUE VALUES
	(95, 3, 17, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'income', 68000.00, 0.00, 'cash', '', '2026-07-05', true, '2026-07-10 12:25:47.877431+00', '2026-07-10 12:25:47.877431+00'),
	(96, 3, 17, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'income', 88000.00, 0.00, 'cash', '', '2026-07-06', true, '2026-07-10 12:26:34.699188+00', '2026-07-10 12:26:34.699188+00'),
	(97, 3, 17, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'income', 196000.00, 0.00, 'cash', '', '2026-07-07', true, '2026-07-10 12:28:52.024729+00', '2026-07-10 12:28:52.024729+00'),
	(98, 3, 17, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'income', 183000.00, 0.00, 'cash', '', '2026-07-08', true, '2026-07-10 12:29:59.555639+00', '2026-07-10 12:29:59.555639+00'),
	(99, 3, 17, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'income', 341000.00, 0.00, 'cash', '', '2026-07-09', true, '2026-07-10 12:30:56.220519+00', '2026-07-10 12:30:56.220519+00'),
	(100, 3, 17, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'income', 174000.00, 0.00, 'cash', '', '2026-07-10', true, '2026-07-10 12:32:18.954938+00', '2026-07-10 12:32:18.954938+00'),
	(101, 3, 20, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'expense', 85000.00, 0.00, 'cash', '', '2026-07-05', true, '2026-07-10 12:34:36.672928+00', '2026-07-10 12:34:36.672928+00'),
	(102, 3, 20, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'expense', 439000.00, 0.00, 'cash', '', '2026-07-06', true, '2026-07-10 12:36:01.324517+00', '2026-07-10 12:36:01.324517+00'),
	(103, 3, 20, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'expense', 55000.00, 0.00, 'cash', '', '2026-07-07', true, '2026-07-10 12:37:14.133197+00', '2026-07-10 12:37:14.133197+00'),
	(104, 3, 20, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'expense', 23000.00, 0.00, 'cash', '', '2026-07-08', true, '2026-07-10 12:39:04.88355+00', '2026-07-10 12:39:04.88355+00'),
	(105, 3, 20, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'expense', 306000.00, 0.00, 'cash', '', '2026-07-09', true, '2026-07-10 12:40:53.315561+00', '2026-07-10 12:40:53.315561+00'),
	(107, 3, 20, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'expense', 280000.00, 0.00, 'cash', '', '2026-07-10', true, '2026-07-10 12:42:13.134553+00', '2026-07-10 12:42:13.134553+00'),
	(109, 3, 21, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'expense', 5000.00, 0.00, 'cash', 'isi ulang air galon', '2026-07-11', true, '2026-07-11 12:35:35.697448+00', '2026-07-11 12:35:35.697448+00'),
	(108, 3, 17, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'income', 177000.00, 0.00, 'cash', 'Penjualan Harian', '2026-07-11', true, '2026-07-11 12:35:35.697448+00', '2026-07-11 12:37:17.957394+00');


--
-- Data for Name: user_businesses; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."user_businesses" ("id", "user_id", "business_id", "created_at") OVERRIDING SYSTEM VALUE VALUES
	(2, '46670f60-2eb4-4526-add8-c04d439267e0', 1, '2026-07-09 12:52:03.635865+00'),
	(4, '46670f60-2eb4-4526-add8-c04d439267e0', 2, '2026-07-09 12:52:03.635865+00'),
	(6, '46670f60-2eb4-4526-add8-c04d439267e0', 3, '2026-07-09 12:52:03.635865+00'),
	(14, '129e4811-8202-44d0-b723-1c0d06501109', 2, '2026-07-10 09:32:32.014906+00'),
	(15, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 3, '2026-07-10 09:33:14.32703+00'),
	(17, '8632b4e5-bbfb-4bc6-952e-ea0761f8c1d1', 3, '2026-07-10 12:40:17.993259+00'),
	(18, '8632b4e5-bbfb-4bc6-952e-ea0761f8c1d1', 2, '2026-07-10 12:40:23.235385+00');


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
	('16ca5dfa-daa4-416e-87ac-b5c95889bb74', 'qris-images', 'qris_shared.jpg', NULL, '2026-07-10 10:37:44.079915+00', '2026-07-11 09:00:43.826788+00', '2026-07-10 10:37:44.079915+00', '{"eTag": "\"ea6d88b948ac26ac3ce76b9539667abc\"", "size": 665604, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-11T09:00:44.000Z", "contentLength": 665604, "httpStatusCode": 200}', '1b81b8b9-c991-4e9c-a18e-21c162ae4911', NULL, '{}');


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

SELECT pg_catalog.setval('"public"."businesses_id_seq"', 4, false);


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"public"."categories_id_seq"', 25, false);


--
-- Name: transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"public"."transactions_id_seq"', 109, true);


--
-- Name: user_businesses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"public"."user_businesses_id_seq"', 19, false);


--
-- PostgreSQL database dump complete
--

-- \unrestrict uAhH3Wl1FalwFjAF0WKwRsCkjpGDU7imhZRvbQzy1HYeuVOZZwbjyFIrQqIeBJQ

RESET ALL;
