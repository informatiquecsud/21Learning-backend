CREATE TABLE auth_group_validity (
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    auth_group_id INTEGER NOT NULL,
    PRIMARY KEY (auth_group_id),
    FOREIGN KEY (auth_group_id) REFERENCES auth_group (id)
);

