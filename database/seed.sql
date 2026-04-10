INSERT INTO categories (name, ai_label, emergency_enabled, base_price_min, base_price_max)
VALUES
  ('Plumbing', 'plumbing', TRUE, 300, 800),
  ('Electrical', 'electrical', TRUE, 350, 1000),
  ('Carpentry', 'carpentry', FALSE, 400, 1200),
  ('Cleaning', 'cleaning', FALSE, 500, 1500),
  ('Painting', 'painting', FALSE, 800, 5000),
  ('Appliance Repair', 'appliance_repair', FALSE, 500, 2500),
  ('Gas Leakage', 'gas_leakage', TRUE, 500, 1500)
ON CONFLICT (name) DO UPDATE
SET
  ai_label = EXCLUDED.ai_label,
  emergency_enabled = EXCLUDED.emergency_enabled,
  base_price_min = EXCLUDED.base_price_min,
  base_price_max = EXCLUDED.base_price_max;

INSERT INTO pricing_rules (category_id, city, min_price, max_price, emergency_multiplier)
SELECT id, 'Chennai', base_price_min, base_price_max, 1.5
FROM categories
ON CONFLICT DO NOTHING;

