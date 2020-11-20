select
	*
from
	auth_user as u
	left join user_courses as uc on uc.user_id = u.id
	left join courses as c on c.id = uc.course_id
where
	c.course_name = 'doi-2gy07'
	and u.id in (
		select
			u.id
		from
			auth_user as u
			left join user_courses as uc on uc.user_id = u.id
			left join courses as c on c.id = uc.course_id
		where
			c.course_name IN (
				SELECT
					course_name
				from
					courses
				where
					course_name like '%doi-1920%'
			)
	)