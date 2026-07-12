-- Migrate 'debt' type consignments to 'reseller'
UPDATE consignments SET type = 'reseller' WHERE type = 'debt';
