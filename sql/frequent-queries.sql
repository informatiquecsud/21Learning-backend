-- déterminer tous les étudiants d'une classe
SELECT
        auth_user.*,
        auth_group.role
FROM
        auth_user
        LEFT JOIN auth_membership ON auth_membership.user_id = auth_user.id
        LEFT JOIN auth_group ON auth_group.id = auth_membership.group_id
WHERE
        ROLE = '1GY5'
        AND auth_user.id NOT IN (
                SELECT
                        auth_user.id
                FROM
                        auth_user
                LEFT JOIN auth_membership ON auth_membership.user_id = auth_user.id
                LEFT JOIN auth_group ON auth_group.id = auth_membership.group_id
        WHERE
                ROLE = 'instructor')
ORDER BY
        username;

-- enregistrer tous les étudiants d'une classe à un cours
UPDATE
        user_courses
SET
        course_id = (
                SELECT
                        courses.id
                FROM
                        courses
                WHERE
                        course_name = 'oxocard101')
WHERE
        user_id IN (
                SELECT
                        auth_user.id
                FROM
                        auth_user
                LEFT JOIN auth_membership ON auth_membership.user_id = auth_user.id
                LEFT JOIN auth_group ON auth_group.id = auth_membership.group_id
        WHERE
                ROLE = '1GY7'
                AND auth_user.id NOT IN (
                        SELECT
                                auth_user.id
                        FROM
                                auth_user
                        LEFT JOIN auth_membership ON auth_membership.user_id = auth_user.id
                        LEFT JOIN auth_group ON auth_group.id = auth_membership.group_id
                WHERE
                        ROLE = 'instructor'))
-- passe tous les étudiants d'une classe dans un autre cours
UPDATE
        auth_user
SET
        course_id = (
                SELECT
                        courses.id
                FROM
                        courses
                WHERE
                        course_name = 'oxocard101'),
        course_name = 'oxocard101'
WHERE
        id IN (
                SELECT
                        auth_user.id
                FROM
                        auth_user
                LEFT JOIN auth_membership ON auth_membership.user_id = auth_user.id
                LEFT JOIN auth_group ON auth_group.id = auth_membership.group_id
        WHERE
                ROLE = '1GY7'
                AND auth_user.id NOT IN (
                        SELECT
                                auth_user.id
                        FROM
                                auth_user
                        LEFT JOIN auth_membership ON auth_membership.user_id = auth_user.id
                        LEFT JOIN auth_group ON auth_group.id = auth_membership.group_id
                WHERE
                        ROLE = 'instructor')
        ORDER BY
                username)
-- désactiver tous les utilisateurs d'une classe
UPDATE
        auth_user
SET
        active = 'F'
WHERE
        auth_user.id IN (
                SELECT
                        auth_user.id
                FROM
                        auth_user
                LEFT JOIN user_courses ON user_courses.user_id = auth_user.id
                LEFT JOIN courses ON courses.id = user_courses.course_id
        WHERE
                courses.course_name LIKE '%1gy11%'
                AND auth_user.id <> 156)
