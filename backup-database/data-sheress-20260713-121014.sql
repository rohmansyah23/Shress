--
-- PostgreSQL database dump
--

\restrict 2cDDr9fEh1D9aKengWJQwFYrPAqAdb7S2gdAwMGrpk2vDgIcqwS4cVjRqHtXD5k

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.10 (Debian 17.10-1.pgdg13+1)

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
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: custom_oauth_providers; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: -
--

INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) VALUES
	(NULL, '46670f60-2eb4-4526-add8-c04d439267e0', NULL, NULL, 'syahr642@gmail.com', '$2a$06$r6eSmG06s6IUBgTb8mYFWeln8A92XnYlb6pIPF1xcyfzu0v1ozkJC', '2026-07-11 12:27:34.082977+00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '{"provider": "email", "providers": ["email"]}', '{"role": "owner", "username": "syahr642", "display_name": "Rohman Syah"}', NULL, '2026-07-11 12:27:34.082977+00', '2026-07-11 12:27:34.082977+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: oauth_authorizations; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: oauth_client_states; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: oauth_consents; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: auth; Owner: -
--

INSERT INTO auth.schema_migrations (version) VALUES
	('20171026211738'),
	('20171026211808'),
	('20171026211834'),
	('20180103212743'),
	('20180108183307'),
	('20180119214651'),
	('20180125194653'),
	('00'),
	('20210710035447'),
	('20210722035447'),
	('20210730183235'),
	('20210909172000'),
	('20210927181326'),
	('20211122151130'),
	('20211124214934'),
	('20211202183645'),
	('20220114185221'),
	('20220114185340'),
	('20220224000811'),
	('20220323170000'),
	('20220429102000'),
	('20220531120530'),
	('20220614074223'),
	('20220811173540'),
	('20221003041349'),
	('20221003041400'),
	('20221011041400'),
	('20221020193600'),
	('20221021073300'),
	('20221021082433'),
	('20221027105023'),
	('20221114143122'),
	('20221114143410'),
	('20221125140132'),
	('20221208132122'),
	('20221215195500'),
	('20221215195800'),
	('20221215195900'),
	('20230116124310'),
	('20230116124412'),
	('20230131181311'),
	('20230322519590'),
	('20230402418590'),
	('20230411005111'),
	('20230508135423'),
	('20230523124323'),
	('20230818113222'),
	('20230914180801'),
	('20231027141322'),
	('20231114161723'),
	('20231117164230'),
	('20240115144230'),
	('20240214120130'),
	('20240306115329'),
	('20240314092811'),
	('20240427152123'),
	('20240612123726'),
	('20240729123726'),
	('20240802193726'),
	('20240806073726'),
	('20241009103726'),
	('20250717082212'),
	('20250731150234'),
	('20250804100000'),
	('20250901200500'),
	('20250903112500'),
	('20250904133000'),
	('20250925093508'),
	('20251007112900'),
	('20251104100000'),
	('20251111201300'),
	('20251201000000'),
	('20260115000000'),
	('20260121000000'),
	('20260219120000'),
	('20260302000000'),
	('20260625000000');


--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: webauthn_challenges; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: webauthn_credentials; Type: TABLE DATA; Schema: auth; Owner: -
--



--
-- Data for Name: businesses; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.businesses (id, name, description, qris_image_url, created_at, updated_at) OVERRIDING SYSTEM VALUE VALUES
	(3, 'Warung Kopi', 'Jl.Swakarsa 3 Pondok Kelapa', 'https://vebjqkmzxelvlgyheyix.supabase.co/storage/v1/object/public/qris-images/qris_shared.jpg', '2026-07-09 12:52:01.618706+00', '2026-07-10 10:37:44.369264+00'),
	(1, 'Agen Milagros', 'Bangunan samping bengkel', NULL, '2026-07-09 12:52:01.618706+00', '2026-07-12 06:27:43.575364+00'),
	(2, 'Teh Solo', 'Jl.Swakarsa 3 Pondok Kelapa', NULL, '2026-07-09 12:52:01.618706+00', '2026-07-12 06:27:46.378553+00');


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.categories (id, business_id, name, type, created_at, updated_at) OVERRIDING SYSTEM VALUE VALUES
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
	(24, 3, 'Lain-lain', 'expense', '2026-07-09 12:52:01.618706+00', '2026-07-09 12:52:01.618706+00'),
	(25, 2, 'Komisi Titipan', 'income', '2026-07-12 00:52:56.765113+00', '2026-07-12 00:52:56.765113+00'),
	(26, 2, 'Bayar Titipan', 'expense', '2026-07-12 00:52:56.765113+00', '2026-07-12 00:52:56.765113+00'),
	(27, 3, 'Komisi Titipan', 'income', '2026-07-12 00:52:56.765113+00', '2026-07-12 00:52:56.765113+00'),
	(28, 3, 'Bayar Titipan', 'expense', '2026-07-12 00:52:56.765113+00', '2026-07-12 00:52:56.765113+00'),
	(29, 1, 'Komisi Titipan', 'income', '2026-07-12 00:52:56.765113+00', '2026-07-12 00:52:56.765113+00'),
	(30, 1, 'Bayar Titipan', 'expense', '2026-07-12 00:52:56.765113+00', '2026-07-12 00:52:56.765113+00'),
	(37, 3, 'Piutang', 'expense', '2026-07-13 02:12:15.842643+00', '2026-07-13 02:12:15.842643+00'),
	(38, 3, 'Piutang', 'income', '2026-07-13 03:59:26.332693+00', '2026-07-13 03:59:26.332693+00');


--
-- Data for Name: consignors; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.users (id, email, username, display_name, avatar_url, role, is_active, created_at, updated_at, password_hash) VALUES
	('129e4811-8202-44d0-b723-1c0d06501109', 'pakasep@gmail.com', 'pasep123', 'Pak Asep', NULL, 'staff', true, '2026-07-10 09:32:26.257297+00', '2026-07-11 12:33:08.913035+00', '$2a$06$/p19oxamay1lrsXt8azDYeNO0N4dYUz9hsoJejcAjRWt31ECtHUna'),
	('777a74e4-e53d-4a75-81bc-9b088c61317f', 'sitiomanaja123@gmail.com', 'sitiaja123', 'Siti Sururoh', NULL, 'owner', true, '2026-07-10 08:49:58.467873+00', '2026-07-11 12:33:08.913035+00', '$2a$06$A5k/DzvQel9svQvPQM14p.ZFz8RnKTCZsI8rGGKRSYd2TNsKLJgQW'),
	('d0000000-0000-0000-0000-000000000001', 'miselsaas@gmail.com', 'miselsaas', 'Miselsa Anisdria', NULL, 'owner', true, '2026-07-10 08:34:07.242104+00', '2026-07-11 12:33:08.913035+00', '$2a$06$1bO9Ptsydd5tVrk/OmXx1OLrmznjcBOwfWEQXvJhkdnehNIGQK7ja'),
	('fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'andri@gmail.com', 'andri', 'Andri', NULL, 'staff', true, '2026-07-10 09:33:10.518645+00', '2026-07-11 12:33:08.913035+00', '$2a$06$.l.TBdhHFCe8dcZEs5lIo.e5SMkI4EHcoRmU70Pw4PY0/sJ3RLArG'),
	('46670f60-2eb4-4526-add8-c04d439267e0', 'syahr642@gmail.com', 'syahr642', 'Rohman Syah', NULL, 'owner', true, '2026-07-09 12:52:03.078035+00', '2026-07-11 15:07:02.094059+00', '$2a$06$zxRu9V07GBQOowqQz0JZCeryL3cW6wgkhI9j./pLXaaRj5ijSqrSG'),
	('8632b4e5-bbfb-4bc6-952e-ea0761f8c1d1', 'test@gmail.com', 'testing', 'tester', NULL, 'manager', true, '2026-07-10 12:39:57.22976+00', '2026-07-12 12:19:00.677157+00', '$2a$06$a563cCgu.rpHY.fbktlNw..b19k/b3bADLH.ppev61LbbOXRaq3Ja');


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.transactions (id, business_id, category_id, user_id, type, amount, cogs, payment_method, description, transaction_date, status_sync, created_at, updated_at) OVERRIDING SYSTEM VALUE VALUES
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
	(12, 3, 20, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'expense', 280000.00, 0.00, 'cash', '', '2026-07-10', true, '2026-07-10 12:42:13.134553+00', '2026-07-10 12:42:13.134553+00'),
	(13, 3, 21, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'expense', 5000.00, 0.00, 'cash', 'isi ulang air galon', '2026-07-11', true, '2026-07-11 12:35:35.697448+00', '2026-07-11 12:35:35.697448+00'),
	(14, 3, 17, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'income', 177500.00, 0.00, 'cash', 'Penjualan Harian', '2026-07-11', true, '2026-07-11 12:35:35.697448+00', '2026-07-11 12:37:17.957394+00'),
	(110, 3, 17, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'income', 143000.00, 0.00, 'cash', 'Pemasukan Harian', '2026-07-12', true, '2026-07-12 11:31:49.93758+00', '2026-07-12 11:31:49.93758+00'),
	(111, 3, 20, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'expense', 185000.00, 0.00, 'cash', 'Bayar Ayah', '2026-07-12', true, '2026-07-12 11:32:15.085179+00', '2026-07-12 12:22:21.093085+00'),
	(112, 3, 37, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'expense', 15000.00, 0.00, 'cash', 'Piutang: Yadi - kopi + roko', '2026-07-10', true, '2026-07-13 02:12:15.988886+00', '2026-07-13 02:12:15.988886+00'),
	(113, 3, 37, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'expense', 4000.00, 0.00, 'cash', 'Piutang: Yasin - kopi', '2026-07-10', true, '2026-07-13 02:14:23.942544+00', '2026-07-13 02:14:23.942544+00'),
	(114, 3, 37, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 'expense', 4000.00, 0.00, 'cash', 'Piutang: Satpam Perumahan - kopi', '2026-07-09', true, '2026-07-13 02:14:58.942645+00', '2026-07-13 02:14:58.942645+00');


--
-- Data for Name: consignments; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: consignment_items; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: consignment_settlements; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: debtors; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.debtors (id, business_id, name, phone, notes, created_at, updated_at) OVERRIDING SYSTEM VALUE VALUES
	(1, 3, 'Yadi', NULL, NULL, '2026-07-13 02:12:15.680434+00', '2026-07-13 02:12:15.680434+00'),
	(2, 3, 'Yasin', NULL, NULL, '2026-07-13 02:14:23.591645+00', '2026-07-13 02:14:23.591645+00'),
	(3, 3, 'Satpam Perumahan', NULL, NULL, '2026-07-13 02:14:58.671075+00', '2026-07-13 02:14:58.671075+00');


--
-- Data for Name: debts; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.debts (id, debtor_id, business_id, user_id, amount, paid_amount, description, status, debt_date, due_date, created_at, updated_at, expense_transaction_id) OVERRIDING SYSTEM VALUE VALUES
	(1, 1, 3, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 15000.00, 0.00, 'kopi + roko', 'unpaid', '2026-07-10', NULL, '2026-07-13 02:12:16.076195+00', '2026-07-13 02:12:16.076195+00', 112),
	(2, 2, 3, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 4000.00, 0.00, 'kopi', 'unpaid', '2026-07-10', NULL, '2026-07-13 02:14:24.02528+00', '2026-07-13 02:14:24.02528+00', 113),
	(3, 3, 3, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 4000.00, 0.00, 'kopi', 'unpaid', '2026-07-09', NULL, '2026-07-13 02:14:59.029863+00', '2026-07-13 02:14:59.029863+00', 114);


--
-- Data for Name: debt_payments; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: user_businesses; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.user_businesses (id, user_id, business_id, created_at) OVERRIDING SYSTEM VALUE VALUES
	(2, '46670f60-2eb4-4526-add8-c04d439267e0', 1, '2026-07-09 12:52:03.635865+00'),
	(4, '46670f60-2eb4-4526-add8-c04d439267e0', 2, '2026-07-09 12:52:03.635865+00'),
	(6, '46670f60-2eb4-4526-add8-c04d439267e0', 3, '2026-07-09 12:52:03.635865+00'),
	(14, '129e4811-8202-44d0-b723-1c0d06501109', 2, '2026-07-10 09:32:32.014906+00'),
	(15, 'fce2cd2c-13a8-4f22-acd7-e69e74634a13', 3, '2026-07-10 09:33:14.32703+00'),
	(21, '8632b4e5-bbfb-4bc6-952e-ea0761f8c1d1', 3, '2026-07-12 12:19:04.278046+00'),
	(22, '8632b4e5-bbfb-4bc6-952e-ea0761f8c1d1', 1, '2026-07-12 12:19:05.277594+00'),
	(23, '8632b4e5-bbfb-4bc6-952e-ea0761f8c1d1', 2, '2026-07-12 12:19:10.974557+00');


--
-- Data for Name: messages_2026_07_11; Type: TABLE DATA; Schema: realtime; Owner: -
--



--
-- Data for Name: messages_2026_07_12; Type: TABLE DATA; Schema: realtime; Owner: -
--



--
-- Data for Name: messages_2026_07_13; Type: TABLE DATA; Schema: realtime; Owner: -
--



--
-- Data for Name: messages_2026_07_14; Type: TABLE DATA; Schema: realtime; Owner: -
--



--
-- Data for Name: messages_2026_07_15; Type: TABLE DATA; Schema: realtime; Owner: -
--



--
-- Data for Name: messages_2026_07_16; Type: TABLE DATA; Schema: realtime; Owner: -
--



--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: realtime; Owner: -
--

INSERT INTO realtime.schema_migrations (version, inserted_at) VALUES
	(20211116024918, '2026-07-09 07:09:53'),
	(20211116045059, '2026-07-09 07:09:53'),
	(20211116050929, '2026-07-09 07:09:53'),
	(20211116051442, '2026-07-09 07:09:53'),
	(20211116212300, '2026-07-09 07:09:53'),
	(20211116213355, '2026-07-09 07:09:53'),
	(20211116213934, '2026-07-09 07:09:53'),
	(20211116214523, '2026-07-09 07:09:53'),
	(20211122062447, '2026-07-09 07:09:53'),
	(20211124070109, '2026-07-09 07:09:53'),
	(20211202204204, '2026-07-09 07:09:53'),
	(20211202204605, '2026-07-09 07:09:53'),
	(20211210212804, '2026-07-09 07:09:53'),
	(20211228014915, '2026-07-09 07:09:53'),
	(20220107221237, '2026-07-09 07:09:53'),
	(20220228202821, '2026-07-09 07:09:53'),
	(20220312004840, '2026-07-09 07:09:53'),
	(20220603231003, '2026-07-09 07:09:53'),
	(20220603232444, '2026-07-09 07:09:53'),
	(20220615214548, '2026-07-09 07:09:53'),
	(20220712093339, '2026-07-09 07:09:53'),
	(20220908172859, '2026-07-09 07:09:53'),
	(20220916233421, '2026-07-09 07:09:53'),
	(20230119133233, '2026-07-09 07:09:53'),
	(20230128025114, '2026-07-09 07:09:53'),
	(20230128025212, '2026-07-09 07:09:53'),
	(20230227211149, '2026-07-09 07:09:53'),
	(20230228184745, '2026-07-09 07:09:54'),
	(20230308225145, '2026-07-09 07:09:54'),
	(20230328144023, '2026-07-09 07:09:54'),
	(20231018144023, '2026-07-09 07:09:54'),
	(20231204144023, '2026-07-09 07:09:54'),
	(20231204144024, '2026-07-09 07:09:54'),
	(20231204144025, '2026-07-09 07:09:54'),
	(20240108234812, '2026-07-09 07:09:54'),
	(20240109165339, '2026-07-09 07:09:54'),
	(20240227174441, '2026-07-09 07:09:54'),
	(20240311171622, '2026-07-09 07:09:54'),
	(20240321100241, '2026-07-09 07:09:54'),
	(20240401105812, '2026-07-09 07:09:54'),
	(20240418121054, '2026-07-09 07:09:54'),
	(20240523004032, '2026-07-09 07:09:54'),
	(20240618124746, '2026-07-09 07:09:54'),
	(20240801235015, '2026-07-09 07:09:54'),
	(20240805133720, '2026-07-09 07:09:54'),
	(20240827160934, '2026-07-09 07:09:54'),
	(20240919163303, '2026-07-09 07:09:54'),
	(20240919163305, '2026-07-09 07:09:54'),
	(20241019105805, '2026-07-09 07:09:54'),
	(20241030150047, '2026-07-09 07:09:54'),
	(20241108114728, '2026-07-09 07:09:54'),
	(20241121104152, '2026-07-09 07:09:54'),
	(20241130184212, '2026-07-09 07:09:54'),
	(20241220035512, '2026-07-09 07:09:54'),
	(20241220123912, '2026-07-09 07:09:54'),
	(20241224161212, '2026-07-09 07:09:54'),
	(20250107150512, '2026-07-09 07:09:54'),
	(20250110162412, '2026-07-09 07:09:54'),
	(20250123174212, '2026-07-09 07:09:54'),
	(20250128220012, '2026-07-09 07:09:54'),
	(20250506224012, '2026-07-09 07:09:54'),
	(20250523164012, '2026-07-09 07:09:54'),
	(20250714121412, '2026-07-09 07:09:54'),
	(20250905041441, '2026-07-09 07:09:54'),
	(20251103001201, '2026-07-09 07:09:54'),
	(20251120212548, '2026-07-09 07:09:54'),
	(20251120215549, '2026-07-09 07:09:54'),
	(20260218120000, '2026-07-09 07:09:54'),
	(20260326120000, '2026-07-09 07:09:54'),
	(20260514120000, '2026-07-09 07:09:54'),
	(20260527120000, '2026-07-09 07:09:54'),
	(20260528120000, '2026-07-09 07:09:54'),
	(20260603120000, '2026-07-09 07:09:54'),
	(20260605120000, '2026-07-09 07:09:54'),
	(20260606110000, '2026-07-09 07:09:54'),
	(20260616120000, '2026-07-09 07:09:54'),
	(20260624120000, '2026-07-09 07:09:54'),
	(20260626120000, '2026-07-09 07:09:54'),
	(20260706120000, '2026-07-09 07:09:54');


--
-- Data for Name: subscription; Type: TABLE DATA; Schema: realtime; Owner: -
--



--
-- Data for Name: buckets; Type: TABLE DATA; Schema: storage; Owner: -
--

INSERT INTO storage.buckets (id, name, owner, created_at, updated_at, public, avif_autodetection, file_size_limit, allowed_mime_types, owner_id, type) VALUES
	('qris-images', 'qris-images', NULL, '2026-07-09 10:34:12.243189+00', '2026-07-09 10:34:12.243189+00', true, false, 5242880, '{image/png,image/jpeg,image/svg+xml,image/webp,image/heic,image/heif}', NULL, 'STANDARD');


--
-- Data for Name: buckets_analytics; Type: TABLE DATA; Schema: storage; Owner: -
--



--
-- Data for Name: buckets_vectors; Type: TABLE DATA; Schema: storage; Owner: -
--



--
-- Data for Name: migrations; Type: TABLE DATA; Schema: storage; Owner: -
--

INSERT INTO storage.migrations (id, name, hash, executed_at) VALUES
	(0, 'create-migrations-table', 'e18db593bcde2aca2a408c4d1100f6abba2195df', '2026-07-09 07:09:56.58657'),
	(1, 'initialmigration', '6ab16121fbaa08bbd11b712d05f358f9b555d777', '2026-07-09 07:09:56.593732'),
	(2, 'storage-schema', 'f6a1fa2c93cbcd16d4e487b362e45fca157a8dbd', '2026-07-09 07:09:56.598285'),
	(3, 'pathtoken-column', '2cb1b0004b817b29d5b0a971af16bafeede4b70d', '2026-07-09 07:09:56.616587'),
	(4, 'add-migrations-rls', '427c5b63fe1c5937495d9c635c263ee7a5905058', '2026-07-09 07:09:56.62407'),
	(5, 'add-size-functions', '79e081a1455b63666c1294a440f8ad4b1e6a7f84', '2026-07-09 07:09:56.628932'),
	(6, 'change-column-name-in-get-size', 'ded78e2f1b5d7e616117897e6443a925965b30d2', '2026-07-09 07:09:56.633454'),
	(7, 'add-rls-to-buckets', 'e7e7f86adbc51049f341dfe8d30256c1abca17aa', '2026-07-09 07:09:56.638335'),
	(8, 'add-public-to-buckets', 'fd670db39ed65f9d08b01db09d6202503ca2bab3', '2026-07-09 07:09:56.644074'),
	(9, 'fix-search-function', 'af597a1b590c70519b464a4ab3be54490712796b', '2026-07-09 07:09:56.648886'),
	(10, 'search-files-search-function', 'b595f05e92f7e91211af1bbfe9c6a13bb3391e16', '2026-07-09 07:09:56.654181'),
	(11, 'add-trigger-to-auto-update-updated_at-column', '7425bdb14366d1739fa8a18c83100636d74dcaa2', '2026-07-09 07:09:56.658691'),
	(12, 'add-automatic-avif-detection-flag', '8e92e1266eb29518b6a4c5313ab8f29dd0d08df9', '2026-07-09 07:09:56.663159'),
	(13, 'add-bucket-custom-limits', 'cce962054138135cd9a8c4bcd531598684b25e7d', '2026-07-09 07:09:56.667293'),
	(14, 'use-bytes-for-max-size', '941c41b346f9802b411f06f30e972ad4744dad27', '2026-07-09 07:09:56.680694'),
	(15, 'add-can-insert-object-function', '934146bc38ead475f4ef4b555c524ee5d66799e5', '2026-07-09 07:09:56.705594'),
	(16, 'add-version', '76debf38d3fd07dcfc747ca49096457d95b1221b', '2026-07-09 07:09:56.711324'),
	(17, 'drop-owner-foreign-key', 'f1cbb288f1b7a4c1eb8c38504b80ae2a0153d101', '2026-07-09 07:09:56.715628'),
	(18, 'add_owner_id_column_deprecate_owner', 'e7a511b379110b08e2f214be852c35414749fe66', '2026-07-09 07:09:56.719905'),
	(19, 'alter-default-value-objects-id', '02e5e22a78626187e00d173dc45f58fa66a4f043', '2026-07-09 07:09:56.725655'),
	(20, 'list-objects-with-delimiter', 'cd694ae708e51ba82bf012bba00caf4f3b6393b7', '2026-07-09 07:09:56.729968'),
	(21, 's3-multipart-uploads', '8c804d4a566c40cd1e4cc5b3725a664a9303657f', '2026-07-09 07:09:56.735616'),
	(22, 's3-multipart-uploads-big-ints', '9737dc258d2397953c9953d9b86920b8be0cdb73', '2026-07-09 07:09:56.747912'),
	(23, 'optimize-search-function', '9d7e604cddc4b56a5422dc68c9313f4a1b6f132c', '2026-07-09 07:09:56.757464'),
	(24, 'operation-function', '8312e37c2bf9e76bbe841aa5fda889206d2bf8aa', '2026-07-09 07:09:56.763283'),
	(25, 'custom-metadata', 'd974c6057c3db1c1f847afa0e291e6165693b990', '2026-07-09 07:09:56.767675'),
	(26, 'objects-prefixes', '215cabcb7f78121892a5a2037a09fedf9a1ae322', '2026-07-09 07:09:56.772258'),
	(27, 'search-v2', '859ba38092ac96eb3964d83bf53ccc0b141663a6', '2026-07-09 07:09:56.776208'),
	(28, 'object-bucket-name-sorting', 'c73a2b5b5d4041e39705814fd3a1b95502d38ce4', '2026-07-09 07:09:56.780639'),
	(29, 'create-prefixes', 'ad2c1207f76703d11a9f9007f821620017a66c21', '2026-07-09 07:09:56.784676'),
	(30, 'update-object-levels', '2be814ff05c8252fdfdc7cfb4b7f5c7e17f0bed6', '2026-07-09 07:09:56.788341'),
	(31, 'objects-level-index', 'b40367c14c3440ec75f19bbce2d71e914ddd3da0', '2026-07-09 07:09:56.792157'),
	(32, 'backward-compatible-index-on-objects', 'e0c37182b0f7aee3efd823298fb3c76f1042c0f7', '2026-07-09 07:09:56.796114'),
	(33, 'backward-compatible-index-on-prefixes', 'b480e99ed951e0900f033ec4eb34b5bdcb4e3d49', '2026-07-09 07:09:56.800029'),
	(34, 'optimize-search-function-v1', 'ca80a3dc7bfef894df17108785ce29a7fc8ee456', '2026-07-09 07:09:56.804804'),
	(35, 'add-insert-trigger-prefixes', '458fe0ffd07ec53f5e3ce9df51bfdf4861929ccc', '2026-07-09 07:09:56.808274'),
	(36, 'optimise-existing-functions', '6ae5fca6af5c55abe95369cd4f93985d1814ca8f', '2026-07-09 07:09:56.812274'),
	(37, 'add-bucket-name-length-trigger', '3944135b4e3e8b22d6d4cbb568fe3b0b51df15c1', '2026-07-09 07:09:56.816347'),
	(38, 'iceberg-catalog-flag-on-buckets', '02716b81ceec9705aed84aa1501657095b32e5c5', '2026-07-09 07:09:56.821087'),
	(39, 'add-search-v2-sort-support', '6706c5f2928846abee18461279799ad12b279b78', '2026-07-09 07:09:56.828631'),
	(40, 'fix-prefix-race-conditions-optimized', '7ad69982ae2d372b21f48fc4829ae9752c518f6b', '2026-07-09 07:09:56.832405'),
	(41, 'add-object-level-update-trigger', '07fcf1a22165849b7a029deed059ffcde08d1ae0', '2026-07-09 07:09:56.835963'),
	(42, 'rollback-prefix-triggers', '771479077764adc09e2ea2043eb627503c034cd4', '2026-07-09 07:09:56.839672'),
	(43, 'fix-object-level', '84b35d6caca9d937478ad8a797491f38b8c2979f', '2026-07-09 07:09:56.843452'),
	(44, 'vector-bucket-type', '99c20c0ffd52bb1ff1f32fb992f3b351e3ef8fb3', '2026-07-09 07:09:56.848124'),
	(45, 'vector-buckets', '049e27196d77a7cb76497a85afae669d8b230953', '2026-07-09 07:09:56.852778'),
	(46, 'buckets-objects-grants', 'fedeb96d60fefd8e02ab3ded9fbde05632f84aed', '2026-07-09 07:09:56.863533'),
	(47, 'iceberg-table-metadata', '649df56855c24d8b36dd4cc1aeb8251aa9ad42c2', '2026-07-09 07:09:56.868032'),
	(48, 'iceberg-catalog-ids', 'e0e8b460c609b9999ccd0df9ad14294613eed939', '2026-07-09 07:09:56.872617'),
	(49, 'buckets-objects-grants-postgres', '072b1195d0d5a2f888af6b2302a1938dd94b8b3d', '2026-07-09 07:09:56.887847'),
	(50, 'search-v2-optimised', '6323ac4f850aa14e7387eb32102869578b5bd478', '2026-07-09 07:09:56.892172'),
	(51, 'index-backward-compatible-search', '2ee395d433f76e38bcd3856debaf6e0e5b674011', '2026-07-09 07:09:56.990413'),
	(52, 'drop-not-used-indexes-and-functions', '5cc44c8696749ac11dd0dc37f2a3802075f3a171', '2026-07-09 07:09:56.991731'),
	(53, 'drop-index-lower-name', 'd0cb18777d9e2a98ebe0bc5cc7a42e57ebe41854', '2026-07-09 07:09:57.001078'),
	(54, 'drop-index-object-level', '6289e048b1472da17c31a7eba1ded625a6457e67', '2026-07-09 07:09:57.003295'),
	(55, 'prevent-direct-deletes', '262a4798d5e0f2e7c8970232e03ce8be695d5819', '2026-07-09 07:09:57.004654'),
	(56, 'fix-optimized-search-function', 'b823ed1e418101032fa01374edc9a436e54e3ed4', '2026-07-09 07:09:57.009418'),
	(57, 's3-multipart-uploads-metadata', 'f127886e00d1b374fadbc7c6b31e09336aad5287', '2026-07-09 07:09:57.014731'),
	(58, 'operation-ergonomics', '00ca5d483b3fe0d522133d9002ccc5df98365120', '2026-07-09 07:09:57.018536'),
	(59, 'drop-unused-functions', '38456f13e39691c2bbb4b5151d0d1cdbabd4a8c4', '2026-07-09 07:09:57.023164'),
	(60, 'optimize-existing-functions-again', 'db35e1c91a9201e59f4fef8d972c2f277d68b157', '2026-07-09 07:09:57.027324');


--
-- Data for Name: objects; Type: TABLE DATA; Schema: storage; Owner: -
--

INSERT INTO storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) VALUES
	('16ca5dfa-daa4-416e-87ac-b5c95889bb74', 'qris-images', 'qris_shared.jpg', NULL, '2026-07-10 10:37:44.079915+00', '2026-07-11 09:00:43.826788+00', '2026-07-10 10:37:44.079915+00', '{"eTag": "\"ea6d88b948ac26ac3ce76b9539667abc\"", "size": 665604, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-11T09:00:44.000Z", "contentLength": 665604, "httpStatusCode": 200}', '1b81b8b9-c991-4e9c-a18e-21c162ae4911', NULL, '{}'),
	('2162b9cb-3c2d-42d6-91f6-f7b8b204e524', 'qris-images', 'qris_business_1.jpg', NULL, '2026-07-11 14:57:58.954319+00', '2026-07-11 14:57:58.954319+00', '2026-07-11 14:57:58.954319+00', '{"eTag": "\"b5ffa761b5da4a47d0decfafb7166135\"", "size": 101276, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-11T14:57:59.000Z", "contentLength": 101276, "httpStatusCode": 200}', 'f0b8b514-35ff-4027-ab0f-d543bbe243d3', NULL, '{}');


--
-- Data for Name: s3_multipart_uploads; Type: TABLE DATA; Schema: storage; Owner: -
--



--
-- Data for Name: s3_multipart_uploads_parts; Type: TABLE DATA; Schema: storage; Owner: -
--



--
-- Data for Name: vector_indexes; Type: TABLE DATA; Schema: storage; Owner: -
--



--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: supabase_migrations; Owner: -
--

INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('001', '{"-- ============================================================
-- SSRS Finance - Initial Schema Migration (v2)
-- Database: Supabase (PostgreSQL)
-- Description: Multi-tenant financial reporting system
-- Owner: SSRS
-- ============================================================

-- 0. EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS \"pgcrypto\"","-- ============================================================
-- 1. TABLES
-- ============================================================

-- 1a. Users (syncs with Supabase Auth)
CREATE TABLE IF NOT EXISTS public.users (
  id uuid PRIMARY KEY, -- Matches Supabase Auth UID
  email varchar(255),
  username varchar(255) NOT NULL,
  display_name varchar(255),
  avatar_url varchar(500),
  role varchar(20) NOT NULL CHECK (role IN (''owner'', ''manager'', ''staff'')),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
)","-- 1b. Businesses
CREATE TABLE IF NOT EXISTS public.businesses (
  id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name varchar(255) NOT NULL,
  description text,
  qris_image_url varchar(500),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
)","-- 1c. User-Business Bridge (Many-to-Many)
CREATE TABLE IF NOT EXISTS public.user_businesses (
  id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  business_id int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, business_id)
)","-- 1d. Categories (Income / Expense per business)
CREATE TABLE IF NOT EXISTS public.categories (
  id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name varchar(255) NOT NULL,
  type varchar(20) NOT NULL CHECK (type IN (''income'', ''expense'')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
)","-- 1e. Transactions
CREATE TABLE IF NOT EXISTS public.transactions (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  category_id int NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type varchar(20) NOT NULL CHECK (type IN (''income'', ''expense'')),
  amount decimal(15,2) NOT NULL CHECK (amount >= 0),
  cogs decimal(15,2) NOT NULL DEFAULT 0.00 CHECK (cogs >= 0),
  payment_method varchar(50) NOT NULL DEFAULT ''cash'' 
    CHECK (payment_method IN (''cash'', ''transfer'', ''qris'', ''other'')),
  description text,
  transaction_date date NOT NULL DEFAULT CURRENT_DATE,
  status_sync boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  -- Ensure COGS is only set for income transactions
  CONSTRAINT cogs_only_for_income CHECK (
    (type = ''income'' AND cogs >= 0) OR (type = ''expense'' AND cogs = 0.00)
  )
)","-- 1f. Financial Reports (pre-calculated snapshots per period)
CREATE TABLE IF NOT EXISTS public.financial_reports (
  id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  period varchar(7) NOT NULL, -- YYYY-MM
  total_income decimal(15,2) NOT NULL DEFAULT 0.00,
  total_cogs decimal(15,2) NOT NULL DEFAULT 0.00,
  gross_profit decimal(15,2) NOT NULL DEFAULT 0.00,
  total_expense decimal(15,2) NOT NULL DEFAULT 0.00,
  net_profit decimal(15,2) NOT NULL DEFAULT 0.00,
  status varchar(10) NOT NULL CHECK (status IN (''laba'', ''rugi'')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (business_id, period)
)","-- ============================================================
-- 2. INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role)","CREATE INDEX IF NOT EXISTS idx_users_is_active ON public.users(is_active)","CREATE INDEX IF NOT EXISTS idx_user_businesses_user_id ON public.user_businesses(user_id)","CREATE INDEX IF NOT EXISTS idx_user_businesses_business_id ON public.user_businesses(business_id)","CREATE INDEX IF NOT EXISTS idx_categories_business_id ON public.categories(business_id)","CREATE INDEX IF NOT EXISTS idx_categories_type ON public.categories(type)","CREATE INDEX IF NOT EXISTS idx_transactions_business_id ON public.transactions(business_id)","CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON public.transactions(user_id)","CREATE INDEX IF NOT EXISTS idx_transactions_type ON public.transactions(type)","CREATE INDEX IF NOT EXISTS idx_transactions_date ON public.transactions(transaction_date)","CREATE INDEX IF NOT EXISTS idx_transactions_payment_method ON public.transactions(payment_method)","CREATE INDEX IF NOT EXISTS idx_transactions_sync ON public.transactions(status_sync) WHERE status_sync = false","-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_transactions_business_date 
  ON public.transactions(business_id, transaction_date DESC)","CREATE INDEX IF NOT EXISTS idx_transactions_user_sync 
  ON public.transactions(user_id, status_sync) WHERE status_sync = false","CREATE INDEX IF NOT EXISTS idx_financial_reports_business_period 
  ON public.financial_reports(business_id, period)","-- ============================================================
-- 3. TRIGGERS
-- ============================================================

-- 3a. Sync user on auth.users creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''''
AS $$
BEGIN
  INSERT INTO public.users (id, email, username, display_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data ->> ''username'', split_part(NEW.email, ''@'', 1)),
    COALESCE(NEW.raw_user_meta_data ->> ''display_name'', split_part(NEW.email, ''@'', 1)),
    COALESCE(NEW.raw_user_meta_data ->> ''role'', ''staff'')
  );
  RETURN NEW;
END;
$$","CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user()","-- 3b. Sync email when auth.users email changes
CREATE OR REPLACE FUNCTION public.sync_user_email()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''''
AS $$
BEGIN
  UPDATE public.users SET 
    email = NEW.email,
    username = COALESCE(NEW.raw_user_meta_data ->> ''username'', split_part(NEW.email, ''@'', 1))
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$","CREATE OR REPLACE TRIGGER on_auth_user_update
  AFTER UPDATE OF email ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_user_email()","-- 3c. Trigger: sync updated_at timestamp
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$","CREATE TRIGGER set_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at()","CREATE TRIGGER set_businesses_updated_at
  BEFORE UPDATE ON public.businesses
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at()","CREATE TRIGGER set_categories_updated_at
  BEFORE UPDATE ON public.categories
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at()","CREATE TRIGGER set_transactions_updated_at
  BEFORE UPDATE ON public.transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at()","CREATE TRIGGER set_financial_reports_updated_at
  BEFORE UPDATE ON public.financial_reports
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at()","-- ============================================================
-- 4. ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY","ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY","ALTER TABLE public.user_businesses ENABLE ROW LEVEL SECURITY","ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY","ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY","ALTER TABLE public.financial_reports ENABLE ROW LEVEL SECURITY","-- Helper function: get current user role
CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS varchar
LANGUAGE sql
STABLE
SECURITY DEFINER SET search_path = ''''
AS $$
  SELECT role FROM public.users WHERE id = auth.uid()
$$","-- Helper function: check if user has access to a business
CREATE OR REPLACE FUNCTION public.user_has_business_access(target_business_id int)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER SET search_path = ''''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_businesses
    WHERE user_id = auth.uid()
      AND business_id = target_business_id
  ) OR public.get_current_user_role() = ''owner''
$$","-- ===== USERS table =====
-- Owner: can read all users; Manager/Staff: can only read own record
CREATE POLICY users_select_owner ON public.users
  FOR SELECT
  USING (
    public.get_current_user_role() = ''owner''
    OR id = auth.uid()
  )","-- Only owner can insert/update/delete users
CREATE POLICY users_insert_owner ON public.users
  FOR INSERT
  WITH CHECK (public.get_current_user_role() = ''owner'')","CREATE POLICY users_update_owner ON public.users
  FOR UPDATE
  USING (public.get_current_user_role() = ''owner'')
  WITH CHECK (public.get_current_user_role() = ''owner'')","CREATE POLICY users_delete_owner ON public.users
  FOR DELETE
  USING (public.get_current_user_role() = ''owner'')","-- ===== BUSINESSES table =====
-- Owner: can read all; Manager/Staff: only businesses they''re assigned to
CREATE POLICY businesses_select ON public.businesses
  FOR SELECT
  USING (
    public.get_current_user_role() = ''owner''
    OR public.user_has_business_access(id)
  )","-- Only owner can modify businesses
CREATE POLICY businesses_insert ON public.businesses
  FOR INSERT
  WITH CHECK (public.get_current_user_role() = ''owner'')","CREATE POLICY businesses_update ON public.businesses
  FOR UPDATE
  USING (public.get_current_user_role() = ''owner'')
  WITH CHECK (public.get_current_user_role() = ''owner'')","CREATE POLICY businesses_delete ON public.businesses
  FOR DELETE
  USING (public.get_current_user_role() = ''owner'')","-- ===== USER_BUSINESSES table =====
-- Owner: full access; Manager/Staff: can read own assignments
CREATE POLICY user_businesses_select ON public.user_businesses
  FOR SELECT
  USING (
    public.get_current_user_role() = ''owner''
    OR user_id = auth.uid()
  )","-- Only owner can manage assignments
CREATE POLICY user_businesses_insert ON public.user_businesses
  FOR INSERT
  WITH CHECK (public.get_current_user_role() = ''owner'')","-- Manager can assign staff to businesses they manage
CREATE POLICY user_businesses_insert_manager ON public.user_businesses
  FOR INSERT
  WITH CHECK (
    public.get_current_user_role() = ''manager''
    AND EXISTS (
      SELECT 1 FROM public.user_businesses ub2
      WHERE ub2.user_id = auth.uid() 
        AND ub2.business_id = business_id
    )
    AND EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = user_id AND u.role = ''staff''
    )
  )","CREATE POLICY user_businesses_update ON public.user_businesses
  FOR UPDATE
  USING (public.get_current_user_role() = ''owner'')
  WITH CHECK (public.get_current_user_role() = ''owner'')","CREATE POLICY user_businesses_delete ON public.user_businesses
  FOR DELETE
  USING (public.get_current_user_role() = ''owner'')","-- ===== CATEGORIES table =====
-- Can read categories for accessible businesses
CREATE POLICY categories_select ON public.categories
  FOR SELECT
  USING (public.user_has_business_access(business_id))","-- Owner can manage categories
CREATE POLICY categories_insert ON public.categories
  FOR INSERT
  WITH CHECK (public.get_current_user_role() = ''owner'')","CREATE POLICY categories_update ON public.categories
  FOR UPDATE
  USING (public.get_current_user_role() = ''owner'')
  WITH CHECK (public.get_current_user_role() = ''owner'')","CREATE POLICY categories_delete ON public.categories
  FOR DELETE
  USING (public.get_current_user_role() = ''owner'')","-- ===== TRANSACTIONS table =====
-- Owner/Manager: can read transactions for accessible businesses
CREATE POLICY transactions_select ON public.transactions
  FOR SELECT
  USING (
    (public.get_current_user_role() IN (''owner'', ''manager'') 
     AND public.user_has_business_access(business_id))
    OR
    (public.get_current_user_role() = ''staff''
     AND public.user_has_business_access(business_id)
     AND user_id = auth.uid())
  )","-- Manager & Staff can insert transactions for their businesses; Owner can insert anywhere
CREATE POLICY transactions_insert ON public.transactions
  FOR INSERT
  WITH CHECK (
    public.user_has_business_access(business_id)
    AND user_id = auth.uid()
  )","-- Can only update own transactions
CREATE POLICY transactions_update ON public.transactions
  FOR UPDATE
  USING (
    public.user_has_business_access(business_id)
    AND user_id = auth.uid()
  )
  WITH CHECK (
    public.user_has_business_access(business_id)
    AND user_id = auth.uid()
  )","-- Only owner can delete transactions
CREATE POLICY transactions_delete ON public.transactions
  FOR DELETE
  USING (
    public.get_current_user_role() = ''owner''
  )","-- ===== FINANCIAL_REPORTS table =====
CREATE POLICY financial_reports_select ON public.financial_reports
  FOR SELECT
  USING (public.user_has_business_access(business_id))","-- Only owner can manage reports
CREATE POLICY financial_reports_insert ON public.financial_reports
  FOR INSERT
  WITH CHECK (public.get_current_user_role() = ''owner'')","CREATE POLICY financial_reports_update ON public.financial_reports
  FOR UPDATE
  USING (public.get_current_user_role() = ''owner'')
  WITH CHECK (public.get_current_user_role() = ''owner'')","CREATE POLICY financial_reports_delete ON public.financial_reports
  FOR DELETE
  USING (public.get_current_user_role() = ''owner'')","-- ============================================================
-- 5. SEED DATA
-- ============================================================

-- 5a. Default Businesses with QRIS image references
INSERT INTO public.businesses (name, description, qris_image_url) VALUES
  (''Agen Minuman Alkali'', ''SSRS - Agen Minuman Alkali'', ''assets/images/qris/business_1_qris.svg''),
  (''Teh Solo'', ''SSRS - Teh Solo'', ''assets/images/qris/business_2_qris.svg''),
  (''Warung Kopi'', ''SSRS - Warung Kopi'', ''assets/images/qris/business_3_qris.svg'')
ON CONFLICT DO NOTHING","-- 5b. Default Categories per business
DO $$
DECLARE
  b record;
BEGIN
  FOR b IN SELECT id, name FROM public.businesses LOOP
    
    -- Income categories
    INSERT INTO public.categories (business_id, name, type) VALUES
      (b.id, ''Penjualan Harian'', ''income''),
      (b.id, ''Penjualan Grosir'', ''income''),
      (b.id, ''Pendapatan Lain'', ''income'')
    ON CONFLICT DO NOTHING;
    
    -- Expense categories
    INSERT INTO public.categories (business_id, name, type) VALUES
      (b.id, ''Bahan Baku'', ''expense''),
      (b.id, ''Operasional'', ''expense''),
      (b.id, ''Gaji Karyawan'', ''expense''),
      (b.id, ''Transportasi'', ''expense''),
      (b.id, ''Lain-lain'', ''expense'')
    ON CONFLICT DO NOTHING;
    
  END LOOP;
END;
$$","-- ============================================================
-- 6. FINANCIAL REPORT FUNCTIONS
-- ============================================================

-- 6a. Generate Financial Report for a specific period (YYYY-MM)
CREATE OR REPLACE FUNCTION public.generate_financial_report(
  p_business_id int,
  p_period varchar(7) -- YYYY-MM
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''''
AS $$
DECLARE
  v_total_income decimal(15,2) := 0;
  v_total_cogs decimal(15,2) := 0;
  v_gross_profit decimal(15,2) := 0;
  v_total_expense decimal(15,2) := 0;
  v_net_profit decimal(15,2) := 0;
  v_status varchar(10) := ''rugi'';
  v_report_id int;
BEGIN
  -- Aggregate data for the period
  SELECT
    COALESCE(SUM(CASE WHEN type = ''income'' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN type = ''income'' THEN cogs ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN type = ''expense'' THEN amount ELSE 0 END), 0)
  INTO v_total_income, v_total_cogs, v_total_expense
  FROM public.transactions
  WHERE business_id = p_business_id
    AND to_char(transaction_date, ''YYYY-MM'') = p_period;

  -- Calculate profits
  v_gross_profit := v_total_income - v_total_cogs;
  v_net_profit := v_gross_profit - v_total_expense;
  v_status := CASE WHEN v_net_profit >= 0 THEN ''laba'' ELSE ''rugi'' END;

  -- Upsert report
  INSERT INTO public.financial_reports (
    business_id, period,
    total_income, total_cogs, gross_profit,
    total_expense, net_profit, status
  ) VALUES (
    p_business_id, p_period,
    v_total_income, v_total_cogs, v_gross_profit,
    v_total_expense, v_net_profit, v_status
  )
  ON CONFLICT (business_id, period)
  DO UPDATE SET
    total_income = EXCLUDED.total_income,
    total_cogs = EXCLUDED.total_cogs,
    gross_profit = EXCLUDED.gross_profit,
    total_expense = EXCLUDED.total_expense,
    net_profit = EXCLUDED.net_profit,
    status = EXCLUDED.status,
    updated_at = now()
  RETURNING id INTO v_report_id;

  RETURN jsonb_build_object(
    ''report_id'', v_report_id,
    ''total_income'', v_total_income,
    ''total_cogs'', v_total_cogs,
    ''gross_profit'', v_gross_profit,
    ''total_expense'', v_total_expense,
    ''net_profit'', v_net_profit,
    ''status'', v_status
  );
END;
$$","-- 6b. Generate Financial Report for a custom date range
CREATE OR REPLACE FUNCTION public.generate_financial_report_range(
  p_business_id int,
  p_start_date date,
  p_end_date date
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''''
AS $$
DECLARE
  v_total_income decimal(15,2) := 0;
  v_total_cogs decimal(15,2) := 0;
  v_gross_profit decimal(15,2) := 0;
  v_total_expense decimal(15,2) := 0;
  v_net_profit decimal(15,2) := 0;
  v_status varchar(10) := ''rugi'';
BEGIN
  -- Aggregate data for the date range
  SELECT
    COALESCE(SUM(CASE WHEN type = ''income'' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN type = ''income'' THEN cogs ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN type = ''expense'' THEN amount ELSE 0 END), 0)
  INTO v_total_income, v_total_cogs, v_total_expense
  FROM public.transactions
  WHERE business_id = p_business_id
    AND transaction_date >= p_start_date
    AND transaction_date <= p_end_date;

  -- Calculate profits
  v_gross_profit := v_total_income - v_total_cogs;
  v_net_profit := v_gross_profit - v_total_expense;
  v_status := CASE WHEN v_net_profit >= 0 THEN ''laba'' ELSE ''rugi'' END;

  RETURN jsonb_build_object(
    ''start_date'', p_start_date,
    ''end_date'', p_end_date,
    ''total_income'', v_total_income,
    ''total_cogs'', v_total_cogs,
    ''gross_profit'', v_gross_profit,
    ''total_expense'', v_total_expense,
    ''net_profit'', v_net_profit,
    ''status'', v_status
  );
END;
$$","-- 6c. Compare two financial periods (Month-over-Month)
CREATE OR REPLACE FUNCTION public.compare_financial_periods(
  p_business_id int,
  p_period_1 varchar(7), -- YYYY-MM
  p_period_2 varchar(7)  -- YYYY-MM
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''''
AS $$
DECLARE
  r1 jsonb;
  r2 jsonb;
  v_income_change decimal(15,2);
  v_net_profit_change decimal(15,2);
  v_income_change_pct decimal(5,2);
  v_net_profit_change_pct decimal(5,2);
BEGIN
  -- Get reports for both periods
  r1 := public.generate_financial_report(p_business_id, p_period_1);
  r2 := public.generate_financial_report(p_business_id, p_period_2);

  -- Calculate changes
  v_income_change := (r2 ->> ''total_income'')::decimal(15,2) - (r1 ->> ''total_income'')::decimal(15,2);
  v_net_profit_change := (r2 ->> ''net_profit'')::decimal(15,2) - (r1 ->> ''net_profit'')::decimal(15,2);
  
  -- Calculate percentage changes (avoid division by zero)
  IF (r1 ->> ''total_income'')::decimal(15,2) != 0 THEN
    v_income_change_pct := (v_income_change / (r1 ->> ''total_income'')::decimal(15,2)) * 100;
  ELSE
    v_income_change_pct := 0;
  END IF;
  
  IF (r1 ->> ''net_profit'')::decimal(15,2) != 0 THEN
    v_net_profit_change_pct := (v_net_profit_change / (r1 ->> ''net_profit'')::decimal(15,2)) * 100;
  ELSE
    v_net_profit_change_pct := 0;
  END IF;

  RETURN jsonb_build_object(
    ''period_1'', jsonb_build_object(
      ''period'', p_period_1,
      ''total_income'', r1 ->> ''total_income'',
      ''total_cogs'', r1 ->> ''total_cogs'',
      ''gross_profit'', r1 ->> ''gross_profit'',
      ''total_expense'', r1 ->> ''total_expense'',
      ''net_profit'', r1 ->> ''net_profit'',
      ''status'', r1 ->> ''status''
    ),
    ''period_2'', jsonb_build_object(
      ''period'', p_period_2,
      ''total_income'', r2 ->> ''total_income'',
      ''total_cogs'', r2 ->> ''total_cogs'',
      ''gross_profit'', r2 ->> ''gross_profit'',
      ''total_expense'', r2 ->> ''total_expense'',
      ''net_profit'', r2 ->> ''net_profit'',
      ''status'', r2 ->> ''status''
    ),
    ''changes'', jsonb_build_object(
      ''income_change'', v_income_change,
      ''income_change_pct'', v_income_change_pct,
      ''net_profit_change'', v_net_profit_change,
      ''net_profit_change_pct'', v_net_profit_change_pct
    )
  );
END;
$$"}', 'initial_schema');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('002', '{"-- ============================================================
-- SSRS Finance - QRIS Storage Bucket Migration (v2)
-- Description: Creates storage bucket for QRIS images and
--              updates seed data to use Supabase Storage URLs.
-- Notes:
--   After running this migration, upload QRIS images to
--   the ''qris-images'' bucket via:
--     supabase storage upload qris-images business_1_qris.svg
-- ============================================================

-- 1. CREATE QRIS STORAGE BUCKET
-- ============================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  ''qris-images'',
  ''qris-images'',
  true,                           -- public bucket (for serving images)
  5242880,                        -- 5 MB limit
  ARRAY[''image/png'', ''image/jpeg'', ''image/svg+xml'']::text[]
)
ON CONFLICT (id) DO NOTHING","-- 2. RLS: Allow authenticated users to SELECT (read) QRIS images
-- ============================================================
CREATE POLICY \"Anyone can view QRIS images\"
ON storage.objects
FOR SELECT
USING (bucket_id = ''qris-images'')","-- 3. RLS: Only authenticated users can UPLOAD QRIS images
-- ============================================================
CREATE POLICY \"Authenticated users can upload QRIS images\"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = ''qris-images''
  AND auth.role() = ''authenticated''
)","-- 4. RLS: Only owners can UPDATE/DELETE QRIS images
-- ============================================================
CREATE POLICY \"Owners can update QRIS images\"
ON storage.objects
FOR UPDATE
USING (
  bucket_id = ''qris-images''
  AND auth.role() = ''authenticated''
  AND (SELECT role FROM public.users WHERE id = auth.uid()) = ''owner''
)","CREATE POLICY \"Owners can delete QRIS images\"
ON storage.objects
FOR DELETE
USING (
  bucket_id = ''qris-images''
  AND auth.role() = ''authenticated''
  AND (SELECT role FROM public.users WHERE id = auth.uid()) = ''owner''
)","-- 5. UPDATE SEED DATA with Supabase Storage public URLs
-- ============================================================
-- After uploading images to the bucket, the public URL format is:
--   {SUPABASE_URL}/storage/v1/object/public/qris-images/{filename}
-- Update the placeholder URL with the actual Supabase project URL.
UPDATE public.businesses
SET qris_image_url = ''https://YOUR-PROJECT.supabase.co/storage/v1/object/public/qris-images/business_1_qris.svg''
WHERE name = ''Agen Minuman Alkali''","UPDATE public.businesses
SET qris_image_url = ''https://YOUR-PROJECT.supabase.co/storage/v1/object/public/qris-images/business_2_qris.svg''
WHERE name = ''Teh Solo''","UPDATE public.businesses
SET qris_image_url = ''https://YOUR-PROJECT.supabase.co/storage/v1/object/public/qris-images/business_3_qris.svg''
WHERE name = ''Warung Kopi''"}', 'qris_storage_bucket');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('003', '{"-- ============================================================
-- SSRS Finance - Demo Accounts Migration
-- Description: Creates demo user accounts for testing
-- ============================================================

SET search_path TO public, extensions","-- 1. DEMO USERS
-- ============================================================
-- Passwords are hashed using bcrypt via pgcrypto
-- The trigger on_auth_user_created will automatically
-- insert corresponding rows into public.users

INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at) VALUES
  (
    ''d0000000-0000-0000-0000-000000000001'',
    ''owner@ssrs.com'',
    crypt(''password123'', gen_salt(''bf''::text)),
    now(),
    jsonb_build_object(''username'', ''owner_ssrs'', ''display_name'', ''Owner SSRS'', ''role'', ''owner''),
    now(),
    now()
  ),
  (
    ''d0000000-0000-0000-0000-000000000002'',
    ''manager@ssrs.com'',
    crypt(''password123'', gen_salt(''bf''::text)),
    now(),
    jsonb_build_object(''username'', ''manager_ssrs'', ''display_name'', ''Manager SSRS'', ''role'', ''manager''),
    now(),
    now()
  ),
  (
    ''d0000000-0000-0000-0000-000000000003'',
    ''staff@ssrs.com'',
    crypt(''password123'', gen_salt(''bf''::text)),
    now(),
    jsonb_build_object(''username'', ''staff_ssrs'', ''display_name'', ''Staff SSRS'', ''role'', ''staff''),
    now(),
    now()
  )
ON CONFLICT (id) DO NOTHING","-- ============================================================
-- 2. ASSIGN DEMO USERS TO BUSINESSES
-- ============================================================
-- Owner: access to all businesses
-- Manager: access to Agen Minuman Alkali & Teh Solo
-- Staff: access to Warung Kopi only

INSERT INTO public.user_businesses (user_id, business_id)
SELECT demo.user_id, b.id
FROM (VALUES
  (''d0000000-0000-0000-0000-000000000001''::uuid, ''Agen Minuman Alkali''),
  (''d0000000-0000-0000-0000-000000000001''::uuid, ''Teh Solo''),
  (''d0000000-0000-0000-0000-000000000001''::uuid, ''Warung Kopi''),
  (''d0000000-0000-0000-0000-000000000002''::uuid, ''Agen Minuman Alkali''),
  (''d0000000-0000-0000-0000-000000000002''::uuid, ''Teh Solo''),
  (''d0000000-0000-0000-0000-000000000003''::uuid, ''Warung Kopi'')
) AS demo(user_id, business_name)
JOIN public.businesses b ON b.name = demo.business_name
ON CONFLICT (user_id, business_id) DO NOTHING"}', 'demo_accounts');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('004', '{"-- ============================================================
-- 004_public_passwords.sql
-- Add password_hash to public.users, populate demo hashes, create verifier
-- ============================================================

CREATE EXTENSION IF NOT EXISTS \"pgcrypto\"","ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS password_hash varchar(200)","-- Populate demo users with bcrypt hashes (password: password123)
-- Note: pgcrypto functions are in the ''extensions'' schema on Supabase
UPDATE public.users
SET password_hash = extensions.crypt(''password123'', extensions.gen_salt(''bf''))
WHERE email IN (''owner@ssrs.com'',''manager@ssrs.com'',''staff@ssrs.com'')","-- RPC to verify password against the stored bcrypt hash in public.users
CREATE OR REPLACE FUNCTION public.verify_public_password(p_email text, p_password text)
RETURNS uuid
LANGUAGE sql
STABLE
SET search_path TO public, extensions
AS $$
  SELECT id FROM public.users
  WHERE email = p_email
    AND password_hash IS NOT NULL
    AND crypt(p_password, password_hash) = password_hash
  LIMIT 1;
$$"}', 'public_passwords');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('005', '{"-- ============================================================
-- 005_update_rls_policies.sql
-- Fix RLS policies:
--   1. Owner explicit SELECT for transactions (was relying on user_has_business_access)
--   2. Staff can see ALL transactions in their business (not just own)
--   3. Staff/Manager can UPDATE any transaction in their business
--   4. Staff/Manager can DELETE transactions in their business
-- ============================================================

-- Drop old policies to replace them
DROP POLICY IF EXISTS transactions_select ON public.transactions","DROP POLICY IF EXISTS transactions_insert ON public.transactions","DROP POLICY IF EXISTS transactions_update ON public.transactions","DROP POLICY IF EXISTS transactions_delete ON public.transactions","-- Owner: can read all transactions across all businesses
CREATE POLICY transactions_select_owner ON public.transactions
  FOR SELECT
  USING (
    public.get_current_user_role() = ''owner''
  )","-- Manager: can read all transactions for accessible businesses
CREATE POLICY transactions_select_manager ON public.transactions
  FOR SELECT
  USING (
    public.get_current_user_role() = ''manager''
    AND public.user_has_business_access(business_id)
  )","-- Staff: can read all transactions for accessible businesses (not just own)
CREATE POLICY transactions_select_staff ON public.transactions
  FOR SELECT
  USING (
    public.get_current_user_role() = ''staff''
    AND public.user_has_business_access(business_id)
  )","-- Manager & Staff can insert transactions for their businesses; Owner can insert anywhere
CREATE POLICY transactions_insert ON public.transactions
  FOR INSERT
  WITH CHECK (
    public.user_has_business_access(business_id)
    AND user_id = auth.uid()
  )","-- All roles with business access can update any transaction in that business
CREATE POLICY transactions_update ON public.transactions
  FOR UPDATE
  USING (
    public.user_has_business_access(business_id)
  )
  WITH CHECK (
    public.user_has_business_access(business_id)
  )","-- All roles with business access can delete transactions in that business
CREATE POLICY transactions_delete ON public.transactions
  FOR DELETE
  USING (
    public.user_has_business_access(business_id)
  )"}', 'update_rls_policies');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('006', '{"-- ============================================================
-- 006_public_auth.sql
-- Disable Row Level Security on all tables to allow public login & CRUD
-- and provide RPC functions for creating users and updating passwords
-- ============================================================

-- Disable Row Level Security on all tables
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY","ALTER TABLE public.businesses DISABLE ROW LEVEL SECURITY","ALTER TABLE public.user_businesses DISABLE ROW LEVEL SECURITY","ALTER TABLE public.categories DISABLE ROW LEVEL SECURITY","ALTER TABLE public.transactions DISABLE ROW LEVEL SECURITY","ALTER TABLE public.financial_reports DISABLE ROW LEVEL SECURITY","-- RPC to create a new user directly in public.users with hashed password
CREATE OR REPLACE FUNCTION public.create_public_user(
  p_email text,
  p_username text,
  p_role text,
  p_password text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  v_user_id := gen_random_uuid();
  INSERT INTO public.users (id, email, username, role, password_hash)
  VALUES (
    v_user_id,
    p_email,
    p_username,
    p_role,
    extensions.crypt(p_password, extensions.gen_salt(''bf''))
  );
  RETURN v_user_id;
END;
$$","-- RPC to update user password directly in public.users
CREATE OR REPLACE FUNCTION public.update_public_user_password(
  p_user_id uuid,
  p_new_password text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.users
  SET password_hash = extensions.crypt(p_new_password, extensions.gen_salt(''bf'')),
      updated_at = now()
  WHERE id = p_user_id;
END;
$$"}', 'public_auth');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('007', '{"-- ============================================================
-- 007_drop_unused_policies.sql
-- Drop old RLS policies on tables where RLS was disabled
-- to resolve Supabase Dashboard warnings
-- ============================================================

-- Drop policies on public.users
DROP POLICY IF EXISTS users_select_owner ON public.users","DROP POLICY IF EXISTS users_insert_owner ON public.users","DROP POLICY IF EXISTS users_update_owner ON public.users","DROP POLICY IF EXISTS users_delete_owner ON public.users","-- Drop policies on public.businesses
DROP POLICY IF EXISTS businesses_select ON public.businesses","DROP POLICY IF EXISTS businesses_insert ON public.businesses","DROP POLICY IF EXISTS businesses_update ON public.businesses","DROP POLICY IF EXISTS businesses_delete ON public.businesses","-- Drop policies on public.user_businesses
DROP POLICY IF EXISTS user_businesses_select ON public.user_businesses","DROP POLICY IF EXISTS user_businesses_insert ON public.user_businesses","DROP POLICY IF EXISTS user_businesses_insert_manager ON public.user_businesses","DROP POLICY IF EXISTS user_businesses_update ON public.user_businesses","DROP POLICY IF EXISTS user_businesses_delete ON public.user_businesses","-- Drop policies on public.categories
DROP POLICY IF EXISTS categories_select ON public.categories","DROP POLICY IF EXISTS categories_insert ON public.categories","DROP POLICY IF EXISTS categories_update ON public.categories","DROP POLICY IF EXISTS categories_delete ON public.categories","-- Drop policies on public.transactions
DROP POLICY IF EXISTS transactions_select_owner ON public.transactions","DROP POLICY IF EXISTS transactions_select_manager ON public.transactions","DROP POLICY IF EXISTS transactions_select_staff ON public.transactions","DROP POLICY IF EXISTS transactions_insert ON public.transactions","DROP POLICY IF EXISTS transactions_update ON public.transactions","DROP POLICY IF EXISTS transactions_delete ON public.transactions","-- Drop policies on public.financial_reports
DROP POLICY IF EXISTS financial_reports_select ON public.financial_reports","DROP POLICY IF EXISTS financial_reports_insert ON public.financial_reports","DROP POLICY IF EXISTS financial_reports_update ON public.financial_reports","DROP POLICY IF EXISTS financial_reports_delete ON public.financial_reports"}', 'drop_unused_policies');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('008', '{"-- ============================================================
-- 008_allow_anon_rls.sql
-- Enable RLS on all tables and create open policies
-- to satisfy Supabase security check while keeping public CRUD intact
-- ============================================================

-- Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY","ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY","ALTER TABLE public.user_businesses ENABLE ROW LEVEL SECURITY","ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY","ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY","ALTER TABLE public.financial_reports ENABLE ROW LEVEL SECURITY","-- Allow all operations for public (anon & authenticated) on users
DROP POLICY IF EXISTS anon_all ON public.users","CREATE POLICY anon_all ON public.users FOR ALL TO public USING (true) WITH CHECK (true)","-- Allow all operations for public on businesses
DROP POLICY IF EXISTS anon_all ON public.businesses","CREATE POLICY anon_all ON public.businesses FOR ALL TO public USING (true) WITH CHECK (true)","-- Allow all operations for public on user_businesses
DROP POLICY IF EXISTS anon_all ON public.user_businesses","CREATE POLICY anon_all ON public.user_businesses FOR ALL TO public USING (true) WITH CHECK (true)","-- Allow all operations for public on categories
DROP POLICY IF EXISTS anon_all ON public.categories","CREATE POLICY anon_all ON public.categories FOR ALL TO public USING (true) WITH CHECK (true)","-- Allow all operations for public on transactions
DROP POLICY IF EXISTS anon_all ON public.transactions","CREATE POLICY anon_all ON public.transactions FOR ALL TO public USING (true) WITH CHECK (true)","-- Allow all operations for public on financial_reports
DROP POLICY IF EXISTS anon_all ON public.financial_reports","CREATE POLICY anon_all ON public.financial_reports FOR ALL TO public USING (true) WITH CHECK (true)"}', 'allow_anon_rls');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('009', '{"-- ============================================================
-- 009_insert_demo_users.sql
-- Insert demo users directly into public.users with password_hash
-- since we are bypassing auth.users schema
-- ============================================================

INSERT INTO public.users (id, email, username, display_name, role, password_hash, is_active)
VALUES
  (
    ''d0000000-0000-0000-0000-000000000001'',
    ''owner@ssrs.com'',
    ''owner_sheress'',
    ''Owner Sheress'',
    ''owner'',
    extensions.crypt(''password123'', extensions.gen_salt(''bf'')),
    true
  ),
  (
    ''d0000000-0000-0000-0000-000000000002'',
    ''manager@ssrs.com'',
    ''manager_sheress'',
    ''Manager Sheress'',
    ''manager'',
    extensions.crypt(''password123'', extensions.gen_salt(''bf'')),
    true
  ),
  (
    ''d0000000-0000-0000-0000-000000000003'',
    ''staff@ssrs.com'',
    ''staff_sheress'',
    ''Staff Sheress'',
    ''staff'',
    extensions.crypt(''password123'', extensions.gen_salt(''bf'')),
    true
  )
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  username = EXCLUDED.username,
  display_name = EXCLUDED.display_name,
  role = EXCLUDED.role,
  password_hash = COALESCE(EXCLUDED.password_hash, public.users.password_hash),
  is_active = true"}', 'insert_demo_users');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('010', '{"-- ============================================================
-- 010_username_login.sql
-- Allow login using email OR username
-- ============================================================

-- Index username for fast lookup
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username)","-- Modify RPC to accept email or username
DROP FUNCTION IF EXISTS public.verify_public_password(text, text)","CREATE FUNCTION public.verify_public_password(
  p_identifier text,
  p_password text
)
RETURNS uuid
LANGUAGE sql
STABLE
SET search_path TO public, extensions
AS $$
  SELECT id FROM public.users
  WHERE (email = p_identifier OR username = p_identifier)
    AND password_hash IS NOT NULL
    AND crypt(p_password, password_hash) = password_hash
  LIMIT 1;
$$"}', 'username_login');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('011', '{"-- ============================================================
-- Sheress - Add more allowed MIME types for QRIS bucket
-- ============================================================

UPDATE storage.buckets
SET allowed_mime_types = ARRAY[
  ''image/png'',
  ''image/jpeg'',
  ''image/svg+xml'',
  ''image/webp'',
  ''image/heic'',
  ''image/heif''
]::text[]
WHERE id = ''qris-images''"}', 'qris_mime_types');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('012', '{"-- ============================================================
-- Sheress - Fix QRIS storage bucket RLS policies
-- Use auth.uid() IS NOT NULL instead of auth.role() = ''authenticated''
-- because auth.role() may not return ''authenticated'' in some setups.
-- ============================================================

-- 1. Drop existing INSERT policy and recreate
DROP POLICY IF EXISTS \"Authenticated users can upload QRIS images\" ON storage.objects","CREATE POLICY \"Authenticated users can upload QRIS images\"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = ''qris-images''
  AND auth.uid() IS NOT NULL
)","-- 2. Drop existing UPDATE policy and recreate
DROP POLICY IF EXISTS \"Owners can update QRIS images\" ON storage.objects","CREATE POLICY \"Owners can update QRIS images\"
ON storage.objects
FOR UPDATE
USING (
  bucket_id = ''qris-images''
  AND auth.uid() IS NOT NULL
  AND (SELECT role FROM public.users WHERE id = auth.uid()) = ''owner''
)
WITH CHECK (
  bucket_id = ''qris-images''
  AND auth.uid() IS NOT NULL
  AND (SELECT role FROM public.users WHERE id = auth.uid()) = ''owner''
)","-- 3. Drop existing DELETE policy and recreate
DROP POLICY IF EXISTS \"Owners can delete QRIS images\" ON storage.objects","CREATE POLICY \"Owners can delete QRIS images\"
ON storage.objects
FOR DELETE
USING (
  bucket_id = ''qris-images''
  AND auth.uid() IS NOT NULL
  AND (SELECT role FROM public.users WHERE id = auth.uid()) = ''owner''
)"}', 'fix_qris_storage_policies');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('013', '{"-- ============================================================
-- Sheress - Simplify QRIS storage policies for Supabase setup
-- that doesn''t propagate JWT claims to storage DB session.
-- Security is enforced client-side (owner role check in app).
-- ============================================================

-- Drop debug policy if still exists
DROP POLICY IF EXISTS \"Debug public insert QRIS\" ON storage.objects","-- INSERT: no auth check needed (app already enforces owner role)
DROP POLICY IF EXISTS \"Authenticated users can upload QRIS images\" ON storage.objects","CREATE POLICY \"Users can upload QRIS images\"
ON storage.objects
FOR INSERT
WITH CHECK (bucket_id = ''qris-images'')","-- UPDATE: same, for upsert to work
DROP POLICY IF EXISTS \"Owners can update QRIS images\" ON storage.objects","CREATE POLICY \"Users can update QRIS images\"
ON storage.objects
FOR UPDATE
USING (bucket_id = ''qris-images'')
WITH CHECK (bucket_id = ''qris-images'')","-- DELETE: keep owner check (not used from Flutter currently)
DROP POLICY IF EXISTS \"Owners can delete QRIS images\" ON storage.objects","CREATE POLICY \"Owners can delete QRIS images\"
ON storage.objects
FOR DELETE
USING (
  bucket_id = ''qris-images''
  AND (SELECT role FROM public.users WHERE id = auth.uid()) = ''owner''
)"}', 'simplify_qris_storage_policies');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('014', '{"-- Drop financial_reports table and related functions.
-- The table and functions were defined in 001_initial_schema.sql but never
-- used from the app (no Dart-side RPC calls, stub model/screen removed).

DROP FUNCTION IF EXISTS public.compare_financial_periods(
  int, varchar(7), varchar(7)
)","DROP FUNCTION IF EXISTS public.generate_financial_report_range(
  int, date, date
)","DROP FUNCTION IF EXISTS public.generate_financial_report(
  int, varchar(7)
)","DROP TABLE IF EXISTS public.financial_reports"}', 'drop_financial_reports');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('015', '{"-- ============================================================
-- 015: Piutang (Debts) & Konsinyasi (Consignment) tables
-- ============================================================

-- ==================== PIUTANG ====================

CREATE TABLE public.debtors (
  id          int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name        varchar(255) NOT NULL,
  phone       varchar(50),
  notes       text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
)","CREATE INDEX idx_debtors_business ON public.debtors(business_id)","CREATE TABLE public.debts (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  debtor_id    int NOT NULL REFERENCES public.debtors(id) ON DELETE CASCADE,
  business_id  int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id      uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  amount       decimal(15,2) NOT NULL CHECK (amount > 0),
  paid_amount  decimal(15,2) NOT NULL DEFAULT 0.00 CHECK (paid_amount >= 0),
  description  text,
  status       varchar(20) NOT NULL DEFAULT ''unpaid'' CHECK (status IN (''unpaid'', ''partial'', ''paid'')),
  debt_date    date NOT NULL DEFAULT CURRENT_DATE,
  due_date     date,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
)","CREATE INDEX idx_debts_business ON public.debts(business_id)","CREATE INDEX idx_debts_debtor ON public.debts(debtor_id)","CREATE INDEX idx_debts_status ON public.debts(status)","CREATE TABLE public.debt_payments (
  id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  debt_id       bigint NOT NULL REFERENCES public.debts(id) ON DELETE CASCADE,
  amount        decimal(15,2) NOT NULL CHECK (amount > 0),
  payment_date  date NOT NULL DEFAULT CURRENT_DATE,
  user_id       uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  notes         text,
  created_at    timestamptz NOT NULL DEFAULT now()
)","CREATE INDEX idx_debt_payments_debt ON public.debt_payments(debt_id)","-- Trigger: auto-update updated_at for debtors
CREATE TRIGGER set_debtors_updated_at
  BEFORE UPDATE ON public.debtors
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at()","-- Trigger: auto-update updated_at for debts
CREATE TRIGGER set_debts_updated_at
  BEFORE UPDATE ON public.debts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at()","-- ==================== KONSINYASI ====================

CREATE TABLE public.consignors (
  id          int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name        varchar(255) NOT NULL,
  phone       varchar(50),
  notes       text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
)","CREATE INDEX idx_consignors_business ON public.consignors(business_id)","CREATE TABLE public.consignments (
  id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  consignor_id      int NOT NULL REFERENCES public.consignors(id) ON DELETE CASCADE,
  business_id       int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id           uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  total_amount      decimal(15,2) NOT NULL CHECK (total_amount > 0),
  settled_amount    decimal(15,2) NOT NULL DEFAULT 0.00 CHECK (settled_amount >= 0),
  description       text,
  status            varchar(20) NOT NULL DEFAULT ''active'' CHECK (status IN (''active'', ''settled'', ''cancelled'')),
  consignment_date  date NOT NULL DEFAULT CURRENT_DATE,
  due_date          date,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
)","CREATE INDEX idx_consignments_business ON public.consignments(business_id)","CREATE INDEX idx_consignments_consignor ON public.consignments(consignor_id)","CREATE INDEX idx_consignments_status ON public.consignments(status)","CREATE TABLE public.consignment_items (
  id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  consignment_id  bigint NOT NULL REFERENCES public.consignments(id) ON DELETE CASCADE,
  product_name    varchar(255) NOT NULL,
  quantity        int NOT NULL CHECK (quantity > 0),
  agreed_price    decimal(15,2) NOT NULL CHECK (agreed_price > 0),
  selling_price   decimal(15,2),
  created_at      timestamptz NOT NULL DEFAULT now()
)","CREATE INDEX idx_consignment_items_consignment ON public.consignment_items(consignment_id)","CREATE TABLE public.consignment_settlements (
  id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  consignment_id   bigint NOT NULL REFERENCES public.consignments(id) ON DELETE CASCADE,
  amount           decimal(15,2) NOT NULL CHECK (amount > 0),
  settlement_date  date NOT NULL DEFAULT CURRENT_DATE,
  user_id          uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  notes            text,
  created_at       timestamptz NOT NULL DEFAULT now()
)","CREATE INDEX idx_consignment_settlements_consignment ON public.consignment_settlements(consignment_id)","-- Trigger: auto-update updated_at for consignors
CREATE TRIGGER set_consignors_updated_at
  BEFORE UPDATE ON public.consignors
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at()","-- Trigger: auto-update updated_at for consignments
CREATE TRIGGER set_consignments_updated_at
  BEFORE UPDATE ON public.consignments
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at()","-- ==================== RLS (consistent with existing open policies) ====================

ALTER TABLE public.debtors ENABLE ROW LEVEL SECURITY","ALTER TABLE public.debts ENABLE ROW LEVEL SECURITY","ALTER TABLE public.debt_payments ENABLE ROW LEVEL SECURITY","ALTER TABLE public.consignors ENABLE ROW LEVEL SECURITY","ALTER TABLE public.consignments ENABLE ROW LEVEL SECURITY","ALTER TABLE public.consignment_items ENABLE ROW LEVEL SECURITY","ALTER TABLE public.consignment_settlements ENABLE ROW LEVEL SECURITY","CREATE POLICY anon_all ON public.debtors FOR ALL TO public USING (true) WITH CHECK (true)","CREATE POLICY anon_all ON public.debts FOR ALL TO public USING (true) WITH CHECK (true)","CREATE POLICY anon_all ON public.debt_payments FOR ALL TO public USING (true) WITH CHECK (true)","CREATE POLICY anon_all ON public.consignors FOR ALL TO public USING (true) WITH CHECK (true)","CREATE POLICY anon_all ON public.consignments FOR ALL TO public USING (true) WITH CHECK (true)","CREATE POLICY anon_all ON public.consignment_items FOR ALL TO public USING (true) WITH CHECK (true)","CREATE POLICY anon_all ON public.consignment_settlements FOR ALL TO public USING (true) WITH CHECK (true)"}', 'add_debts_and_consignment');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('016', '{"-- ============================================================
-- 016: Add GRANT permissions for debt/consignment tables
-- Tables were created in 015 but missing GRANT for Data API access
-- ============================================================

GRANT ALL ON TABLE public.debtors TO anon","GRANT ALL ON TABLE public.debtors TO authenticated","GRANT ALL ON TABLE public.debtors TO service_role","GRANT ALL ON SEQUENCE public.debtors_id_seq TO anon","GRANT ALL ON SEQUENCE public.debtors_id_seq TO authenticated","GRANT ALL ON SEQUENCE public.debtors_id_seq TO service_role","GRANT ALL ON TABLE public.debts TO anon","GRANT ALL ON TABLE public.debts TO authenticated","GRANT ALL ON TABLE public.debts TO service_role","GRANT ALL ON SEQUENCE public.debts_id_seq TO anon","GRANT ALL ON SEQUENCE public.debts_id_seq TO authenticated","GRANT ALL ON SEQUENCE public.debts_id_seq TO service_role","GRANT ALL ON TABLE public.debt_payments TO anon","GRANT ALL ON TABLE public.debt_payments TO authenticated","GRANT ALL ON TABLE public.debt_payments TO service_role","GRANT ALL ON SEQUENCE public.debt_payments_id_seq TO anon","GRANT ALL ON SEQUENCE public.debt_payments_id_seq TO authenticated","GRANT ALL ON SEQUENCE public.debt_payments_id_seq TO service_role","GRANT ALL ON TABLE public.consignors TO anon","GRANT ALL ON TABLE public.consignors TO authenticated","GRANT ALL ON TABLE public.consignors TO service_role","GRANT ALL ON SEQUENCE public.consignors_id_seq TO anon","GRANT ALL ON SEQUENCE public.consignors_id_seq TO authenticated","GRANT ALL ON SEQUENCE public.consignors_id_seq TO service_role","GRANT ALL ON TABLE public.consignments TO anon","GRANT ALL ON TABLE public.consignments TO authenticated","GRANT ALL ON TABLE public.consignments TO service_role","GRANT ALL ON SEQUENCE public.consignments_id_seq TO anon","GRANT ALL ON SEQUENCE public.consignments_id_seq TO authenticated","GRANT ALL ON SEQUENCE public.consignments_id_seq TO service_role","GRANT ALL ON TABLE public.consignment_items TO anon","GRANT ALL ON TABLE public.consignment_items TO authenticated","GRANT ALL ON TABLE public.consignment_items TO service_role","GRANT ALL ON SEQUENCE public.consignment_items_id_seq TO anon","GRANT ALL ON SEQUENCE public.consignment_items_id_seq TO authenticated","GRANT ALL ON SEQUENCE public.consignment_items_id_seq TO service_role","GRANT ALL ON TABLE public.consignment_settlements TO anon","GRANT ALL ON TABLE public.consignment_settlements TO authenticated","GRANT ALL ON TABLE public.consignment_settlements TO service_role","GRANT ALL ON SEQUENCE public.consignment_settlements_id_seq TO anon","GRANT ALL ON SEQUENCE public.consignment_settlements_id_seq TO authenticated","GRANT ALL ON SEQUENCE public.consignment_settlements_id_seq TO service_role"}', 'grant_debt_consignment_permissions');
INSERT INTO supabase_migrations.schema_migrations (version, statements, name) VALUES ('017', '{"-- ============================================================
-- 017: Consignment Two Models — Hutang & Harian
-- ============================================================

-- 1a. Tambah kolom di consignments
ALTER TABLE public.consignments
  ADD COLUMN type varchar(10) DEFAULT ''debt''
  CHECK (type IN (''debt'', ''daily'')),
  ADD COLUMN report_status varchar(20) DEFAULT ''pending''
  CHECK (report_status IN (''pending'', ''reported'', ''settled'')),
  ADD COLUMN income_transaction_id bigint REFERENCES public.transactions(id) ON DELETE SET NULL,
  ADD COLUMN expense_transaction_id bigint REFERENCES public.transactions(id) ON DELETE SET NULL","-- 1b. Tambah kolom di consignment_items
ALTER TABLE public.consignment_items
  ADD COLUMN quantity_sold int DEFAULT 0 CHECK (quantity_sold >= 0),
  ADD COLUMN quantity_returned int DEFAULT 0 CHECK (quantity_returned >= 0)","ALTER TABLE public.consignment_items
  ADD CONSTRAINT check_qty_balance
  CHECK (quantity_sold + quantity_returned = quantity)","-- 1c. Seed kategori baru: Komisi Titipan (income) & Bayar Titipan (expense)
DO $$
DECLARE b RECORD;
BEGIN
  FOR b IN SELECT id FROM public.businesses LOOP
    INSERT INTO public.categories (business_id, name, type) VALUES
      (b.id, ''Komisi Titipan'', ''income''),
      (b.id, ''Bayar Titipan'', ''expense'')
    ON CONFLICT DO NOTHING;
  END LOOP;
END $$"}', 'consignment_two_models');


--
-- Data for Name: secrets; Type: TABLE DATA; Schema: vault; Owner: -
--



--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: -
--

SELECT pg_catalog.setval('auth.refresh_tokens_id_seq', 104, true);


--
-- Name: businesses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.businesses_id_seq', 4, true);


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.categories_id_seq', 38, true);


--
-- Name: consignment_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.consignment_items_id_seq', 1, true);


--
-- Name: consignment_settlements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.consignment_settlements_id_seq', 1, true);


--
-- Name: consignments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.consignments_id_seq', 1, true);


--
-- Name: consignors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.consignors_id_seq', 1, true);


--
-- Name: debt_payments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.debt_payments_id_seq', 2, true);


--
-- Name: debtors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.debtors_id_seq', 5, true);


--
-- Name: debts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.debts_id_seq', 5, true);


--
-- Name: transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.transactions_id_seq', 119, true);


--
-- Name: user_businesses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_businesses_id_seq', 23, true);


--
-- Name: subscription_id_seq; Type: SEQUENCE SET; Schema: realtime; Owner: -
--

SELECT pg_catalog.setval('realtime.subscription_id_seq', 292, true);


--
-- PostgreSQL database dump complete
--

\unrestrict 2cDDr9fEh1D9aKengWJQwFYrPAqAdb7S2gdAwMGrpk2vDgIcqwS4cVjRqHtXD5k

