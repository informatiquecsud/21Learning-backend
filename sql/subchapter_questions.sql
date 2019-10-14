-- affiche les questions d'un sous-chapitre dans l'ordre
SELECT
    name AS "div_id",
    question,
    question_type AS "Donnée"
FROM
    questions
WHERE
    subchapter = 'binaire'
ORDER BY
    "timestamp"
