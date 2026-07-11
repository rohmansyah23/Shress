


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;




ALTER SCHEMA "public" OWNER TO "postgres";


CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."create_public_user"("p_email" "text", "p_username" "text", "p_role" "text", "p_password" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
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
    extensions.crypt(p_password, extensions.gen_salt('bf'))
  );
  RETURN v_user_id;
END;
$$;


ALTER FUNCTION "public"."create_public_user"("p_email" "text", "p_username" "text", "p_role" "text", "p_password" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_current_user_role"() RETURNS character varying
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$ SELECT role FROM public.users WHERE id = auth.uid() $$;


ALTER FUNCTION "public"."get_current_user_role"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$ BEGIN
      INSERT INTO public.users (id, email, username, display_name, role)
      VALUES (NEW.id, NEW.email,
        COALESCE(NEW.raw_user_meta_data ->> 'username', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data ->> 'display_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data ->> 'role', 'staff'))
      ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email, username = EXCLUDED.username,
        display_name = EXCLUDED.display_name, role = EXCLUDED.role, updated_at = now();
      RETURN NEW;
    END; $$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$ BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_user_email"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$ BEGIN
      UPDATE public.users SET email = NEW.email,
        username = COALESCE(NEW.raw_user_meta_data ->> 'username', split_part(NEW.email, '@', 1))
      WHERE id = NEW.id; RETURN NEW;
    END; $$;


ALTER FUNCTION "public"."sync_user_email"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_public_user_password"("p_user_id" "uuid", "p_new_password" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  UPDATE public.users
  SET password_hash = extensions.crypt(p_new_password, extensions.gen_salt('bf')),
      updated_at = now()
  WHERE id = p_user_id;
END;
$$;


ALTER FUNCTION "public"."update_public_user_password"("p_user_id" "uuid", "p_new_password" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."user_has_business_access"("target_business_id" integer) RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$ SELECT EXISTS (SELECT 1 FROM public.user_businesses WHERE user_id = auth.uid() AND business_id = target_business_id)
      OR public.get_current_user_role() = 'owner' $$;


ALTER FUNCTION "public"."user_has_business_access"("target_business_id" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."verify_public_password"("p_identifier" "text", "p_password" "text") RETURNS "uuid"
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'public', 'extensions'
    AS $$
  SELECT id FROM public.users
  WHERE (email = p_identifier OR username = p_identifier)
    AND password_hash IS NOT NULL
    AND crypt(p_password, password_hash) = password_hash
  LIMIT 1;
$$;


ALTER FUNCTION "public"."verify_public_password"("p_identifier" "text", "p_password" "text") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."businesses" (
    "id" integer NOT NULL,
    "name" character varying(255) NOT NULL,
    "description" "text",
    "qris_image_url" character varying(500),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."businesses" OWNER TO "postgres";


ALTER TABLE "public"."businesses" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."businesses_id_seq"
    START WITH 4
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."categories" (
    "id" integer NOT NULL,
    "business_id" integer NOT NULL,
    "name" character varying(255) NOT NULL,
    "type" character varying(20) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "categories_type_check" CHECK ((("type")::"text" = ANY (ARRAY[('income'::character varying)::"text", ('expense'::character varying)::"text"])))
);


ALTER TABLE "public"."categories" OWNER TO "postgres";


ALTER TABLE "public"."categories" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."categories_id_seq"
    START WITH 25
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."transactions" (
    "id" bigint NOT NULL,
    "business_id" integer NOT NULL,
    "category_id" integer NOT NULL,
    "user_id" "uuid" NOT NULL,
    "type" character varying(20) NOT NULL,
    "amount" numeric(15,2) NOT NULL,
    "cogs" numeric(15,2) DEFAULT 0.00 NOT NULL,
    "payment_method" character varying(50) DEFAULT 'cash'::character varying NOT NULL,
    "description" "text",
    "transaction_date" "date" DEFAULT CURRENT_DATE NOT NULL,
    "status_sync" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "cogs_only_for_income" CHECK ((((("type")::"text" = 'income'::"text") AND ("cogs" >= (0)::numeric)) OR ((("type")::"text" = 'expense'::"text") AND ("cogs" = 0.00)))),
    CONSTRAINT "transactions_amount_check" CHECK (("amount" >= (0)::numeric)),
    CONSTRAINT "transactions_cogs_check" CHECK (("cogs" >= (0)::numeric)),
    CONSTRAINT "transactions_payment_method_check" CHECK ((("payment_method")::"text" = ANY (ARRAY[('cash'::character varying)::"text", ('transfer'::character varying)::"text", ('qris'::character varying)::"text", ('other'::character varying)::"text"]))),
    CONSTRAINT "transactions_type_check" CHECK ((("type")::"text" = ANY (ARRAY[('income'::character varying)::"text", ('expense'::character varying)::"text"])))
);


ALTER TABLE "public"."transactions" OWNER TO "postgres";


ALTER TABLE "public"."transactions" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."transactions_id_seq"
    START WITH 108
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."user_businesses" (
    "id" integer NOT NULL,
    "user_id" "uuid" NOT NULL,
    "business_id" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_businesses" OWNER TO "postgres";


ALTER TABLE "public"."user_businesses" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."user_businesses_id_seq"
    START WITH 19
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "uuid" NOT NULL,
    "email" character varying(255),
    "username" character varying(255) NOT NULL,
    "display_name" character varying(255),
    "avatar_url" character varying(500),
    "role" character varying(20) NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "password_hash" character varying(200),
    CONSTRAINT "users_role_check" CHECK ((("role")::"text" = ANY (ARRAY[('owner'::character varying)::"text", ('manager'::character varying)::"text", ('staff'::character varying)::"text"])))
);


ALTER TABLE "public"."users" OWNER TO "postgres";


ALTER TABLE ONLY "public"."businesses"
    ADD CONSTRAINT "businesses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."transactions"
    ADD CONSTRAINT "transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_businesses"
    ADD CONSTRAINT "user_businesses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_businesses"
    ADD CONSTRAINT "user_businesses_user_id_business_id_key" UNIQUE ("user_id", "business_id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_categories_business_id" ON "public"."categories" USING "btree" ("business_id");



CREATE INDEX "idx_categories_type" ON "public"."categories" USING "btree" ("type");



CREATE INDEX "idx_transactions_business_date" ON "public"."transactions" USING "btree" ("business_id", "transaction_date" DESC);



CREATE INDEX "idx_transactions_business_id" ON "public"."transactions" USING "btree" ("business_id");



CREATE INDEX "idx_transactions_date" ON "public"."transactions" USING "btree" ("transaction_date");



CREATE INDEX "idx_transactions_payment_method" ON "public"."transactions" USING "btree" ("payment_method");



CREATE INDEX "idx_transactions_sync" ON "public"."transactions" USING "btree" ("status_sync") WHERE ("status_sync" = false);



CREATE INDEX "idx_transactions_type" ON "public"."transactions" USING "btree" ("type");



CREATE INDEX "idx_transactions_user_id" ON "public"."transactions" USING "btree" ("user_id");



CREATE INDEX "idx_transactions_user_sync" ON "public"."transactions" USING "btree" ("user_id", "status_sync") WHERE ("status_sync" = false);



CREATE INDEX "idx_user_businesses_business_id" ON "public"."user_businesses" USING "btree" ("business_id");



CREATE INDEX "idx_user_businesses_user_id" ON "public"."user_businesses" USING "btree" ("user_id");



CREATE INDEX "idx_users_is_active" ON "public"."users" USING "btree" ("is_active");



CREATE INDEX "idx_users_role" ON "public"."users" USING "btree" ("role");



CREATE INDEX "idx_users_username" ON "public"."users" USING "btree" ("username");



CREATE OR REPLACE TRIGGER "set_businesses_updated_at" BEFORE UPDATE ON "public"."businesses" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "set_categories_updated_at" BEFORE UPDATE ON "public"."categories" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "set_transactions_updated_at" BEFORE UPDATE ON "public"."transactions" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "set_users_updated_at" BEFORE UPDATE ON "public"."users" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."transactions"
    ADD CONSTRAINT "transactions_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."transactions"
    ADD CONSTRAINT "transactions_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."transactions"
    ADD CONSTRAINT "transactions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_businesses"
    ADD CONSTRAINT "user_businesses_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_businesses"
    ADD CONSTRAINT "user_businesses_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



CREATE POLICY "anon_all" ON "public"."businesses" USING (true) WITH CHECK (true);



CREATE POLICY "anon_all" ON "public"."categories" USING (true) WITH CHECK (true);



CREATE POLICY "anon_all" ON "public"."transactions" USING (true) WITH CHECK (true);



CREATE POLICY "anon_all" ON "public"."user_businesses" USING (true) WITH CHECK (true);



CREATE POLICY "anon_all" ON "public"."users" USING (true) WITH CHECK (true);



ALTER TABLE "public"."businesses" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."transactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_businesses" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


REVOKE USAGE ON SCHEMA "public" FROM PUBLIC;
GRANT ALL ON SCHEMA "public" TO "anon";
GRANT ALL ON SCHEMA "public" TO "authenticated";
GRANT ALL ON SCHEMA "public" TO "service_role";






















































































































































GRANT ALL ON FUNCTION "public"."create_public_user"("p_email" "text", "p_username" "text", "p_role" "text", "p_password" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_public_user"("p_email" "text", "p_username" "text", "p_role" "text", "p_password" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_public_user"("p_email" "text", "p_username" "text", "p_role" "text", "p_password" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_current_user_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_current_user_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_current_user_role"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_user_email"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_user_email"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_user_email"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_public_user_password"("p_user_id" "uuid", "p_new_password" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."update_public_user_password"("p_user_id" "uuid", "p_new_password" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_public_user_password"("p_user_id" "uuid", "p_new_password" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."user_has_business_access"("target_business_id" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."user_has_business_access"("target_business_id" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."user_has_business_access"("target_business_id" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."verify_public_password"("p_identifier" "text", "p_password" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."verify_public_password"("p_identifier" "text", "p_password" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."verify_public_password"("p_identifier" "text", "p_password" "text") TO "service_role";


















GRANT ALL ON TABLE "public"."businesses" TO "anon";
GRANT ALL ON TABLE "public"."businesses" TO "authenticated";
GRANT ALL ON TABLE "public"."businesses" TO "service_role";



GRANT ALL ON SEQUENCE "public"."businesses_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."businesses_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."businesses_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."categories" TO "anon";
GRANT ALL ON TABLE "public"."categories" TO "authenticated";
GRANT ALL ON TABLE "public"."categories" TO "service_role";



GRANT ALL ON SEQUENCE "public"."categories_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."categories_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."categories_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."transactions" TO "anon";
GRANT ALL ON TABLE "public"."transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."transactions" TO "service_role";



GRANT ALL ON SEQUENCE "public"."transactions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."transactions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."transactions_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."user_businesses" TO "anon";
GRANT ALL ON TABLE "public"."user_businesses" TO "authenticated";
GRANT ALL ON TABLE "public"."user_businesses" TO "service_role";



GRANT ALL ON SEQUENCE "public"."user_businesses_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."user_businesses_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."user_businesses_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";


































