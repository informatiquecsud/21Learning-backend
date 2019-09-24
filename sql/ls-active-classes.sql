SELECT
    id,
    ROLE,
    start_date,
    end_date
FROM
    auth_group
    LEFT JOIN auth_group_validity ON auth_group_validity.auth_group_id = auth_group.id
WHERE
    start_date <= CURRENT_DATE
    AND end_date >= CURRENT_DATE
