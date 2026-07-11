-- Drop financial_reports table and related functions.
-- The table and functions were defined in 001_initial_schema.sql but never
-- used from the app (no Dart-side RPC calls, stub model/screen removed).

DROP FUNCTION IF EXISTS public.compare_financial_periods(
  int, varchar(7), varchar(7)
);

DROP FUNCTION IF EXISTS public.generate_financial_report_range(
  int, date, date
);

DROP FUNCTION IF EXISTS public.generate_financial_report(
  int, varchar(7)
);

DROP TABLE IF EXISTS public.financial_reports;
