ALTER TABLE client ADD COLUMN address TEXT;

ALTER TABLE mechanic ADD CONSTRAINT check_experience CHECK (experience_years >= 0);

ALTER TABLE repair_order ALTER COLUMN status TYPE VARCHAR(100);

ALTER TABLE spare_part ADD COLUMN warranty_months INT DEFAULT 6;