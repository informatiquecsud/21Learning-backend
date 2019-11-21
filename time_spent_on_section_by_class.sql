SELECT
    sid,
    first_name,
    last_name,
    course_id,
    max("timestamp") - min("timestamp") AS time_spent
FROM
    useinfo_course_user_grades
WHERE
    div_id LIKE '%doi/text-encoding%'
    AND course_id LIKE 'doi%1gy5'
GROUP BY
    sid,
    course_id,
    first_name,
    last_name
HAVING
    max("timestamp") - min("timestamp") > '00:00:00'
ORDER BY
    time_spent ASC;

