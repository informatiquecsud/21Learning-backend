CREATE OR REPLACE FUNCTION random_passwd (int)
    RETURNS text
    AS $$
    SELECT
        array_to_string(ARRAY (
                SELECT
                    substring('ABCDEFGHIJKLMNOPQRSTUVWXYZ' FROM (random() * 26)::int FOR 1)
            FROM generate_series(1, $1)), '')
