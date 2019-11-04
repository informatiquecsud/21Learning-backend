INSERT INTO question_grades (sid, course_name, div_id, useinfo_id)
SELECT
    useinfo.sid,
    useinfo.course_id AS "course_name",
    useinfo.div_id,
    MAX(useinfo.id) AS "useinfo_id"
FROM
    useinfo
    INNER JOIN (
        SELECT
            u.sid,
            u.div_id,
            MAX(u.timestamp) AS timestamp
        FROM
            useinfo AS u
        GROUP BY
            sid,
            div_id) AS max_useinfo ON useinfo.sid = max_useinfo.sid
    AND useinfo.div_id = max_useinfo.div_id
WHERE
    useinfo.div_id LIKE '%exa1A%'
    AND useinfo.course_id LIKE '%1gy5'
GROUP BY
    useinfo.div_id,
    useinfo.sid,
    useinfo.course_id
ORDER BY
    useinfo.div_id,
    useinfo.sid;

