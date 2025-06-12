
CREATE TABLE IF NOT EXISTS  orders
( id            SERIAL PRIMARY KEY
, product_name  TEXT
, quantity      INTEGER
, order_date    DATE        DEFAULT NOW()
, md5_hash      VARCHAR(32) DEFAULT MD5(NOW()::TEXT)  -- extra
, dt_created    TIMESTAMP   DEFAULT NOW()             -- extra
);

COMMENT ON TABLE orders IS 'Test: Replication table';

COMMENT ON COLUMN orders.id         IS 'Autoincrement.';
COMMENT ON COLUMN orders.order_date IS 'Extra: added DEFAULT NOW().';
COMMENT ON COLUMN orders.md5_hash   IS 'Extra: to test most recent replicated rows.';
COMMENT ON COLUMN orders.dt_created IS 'Extra: to test most recent replicated rows.';

