-- Integrate debt system with transactions:
-- 1. Add expense_transaction_id to debts (for the expense created when debt is recorded)
-- 2. Add income_transaction_id to debt_payments (for the income created when payment is made)
-- 3. Transactions now reference debt_payments (to distinguish debt-related transactions)

ALTER TABLE debts
  ADD COLUMN expense_transaction_id bigint REFERENCES transactions(id) ON DELETE SET NULL;

ALTER TABLE debt_payments
  ADD COLUMN income_transaction_id bigint REFERENCES transactions(id) ON DELETE SET NULL;

-- Grant permissions
GRANT ALL ON debts TO authenticated;
GRANT ALL ON debt_payments TO authenticated;
