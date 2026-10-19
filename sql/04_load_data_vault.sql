-- Загрузка Data Vault из 3NF-модели (имитация загрузки из источника)
-- Выполнять после 01, 02, 03. record_source = 'sched_3nf'.
SET search_path TO sched_dv;

-- ---- Хабы ----
INSERT INTO hub_faculty (faculty_hk, faculty_code, record_source)
SELECT hk(short_name), short_name, 'sched_3nf' FROM sched_3nf.faculty;

INSERT INTO hub_department (department_hk, department_code, record_source)
SELECT hk(d.name), d.name, 'sched_3nf' FROM sched_3nf.department d;

INSERT INTO hub_teacher (teacher_hk, teacher_code, record_source)
SELECT hk(email), email, 'sched_3nf' FROM sched_3nf.teacher;

INSERT INTO hub_program (program_hk, program_code, record_source)
SELECT hk(code), code, 'sched_3nf' FROM sched_3nf.study_program;

INSERT INTO hub_group (group_hk, group_name, record_source)
SELECT hk(name), name, 'sched_3nf' FROM sched_3nf.student_group;

INSERT INTO hub_discipline (discipline_hk, discipline_code, record_source)
SELECT hk(name), name, 'sched_3nf' FROM sched_3nf.discipline;

INSERT INTO hub_room (room_hk, room_code, record_source)
SELECT hk(b.name, r.number), b.name || '-' || r.number, 'sched_3nf'
FROM sched_3nf.room r JOIN sched_3nf.building b USING (building_id);

INSERT INTO hub_semester (semester_hk, semester_code, record_source)
SELECT hk(year_start::text, term_number::text), year_start || '-' || term_number, 'sched_3nf'
FROM sched_3nf.semester;

INSERT INTO hub_time_slot (time_slot_hk, slot_code, record_source)
SELECT hk(slot_id::text), slot_id::text, 'sched_3nf' FROM sched_3nf.time_slot;

INSERT INTO hub_lesson_type (lesson_type_hk, lesson_type_code, record_source)
SELECT hk(name), name, 'sched_3nf' FROM sched_3nf.lesson_type;

-- ---- Сателлиты хабов ----
INSERT INTO sat_faculty (faculty_hk, record_source, hash_diff, name, short_name)
SELECT hk(short_name), 'sched_3nf', hk(name, short_name), name, short_name FROM sched_3nf.faculty;

INSERT INTO sat_department (department_hk, record_source, hash_diff, name)
SELECT hk(name), 'sched_3nf', hk(name), name FROM sched_3nf.department;

INSERT INTO sat_teacher (teacher_hk, record_source, hash_diff, last_name, first_name, middle_name, academic_position, email)
SELECT hk(t.email), 'sched_3nf', hk(t.last_name, t.first_name, coalesce(t.middle_name,''), p.title),
       t.last_name, t.first_name, t.middle_name, p.title, t.email
FROM sched_3nf.teacher t JOIN sched_3nf.academic_position p USING (position_id);

INSERT INTO sat_program (program_hk, record_source, hash_diff, name, duration_year)
SELECT hk(code), 'sched_3nf', hk(name, duration_year::text), name, duration_year FROM sched_3nf.study_program;

INSERT INTO sat_group (group_hk, record_source, hash_diff, admission_year, students_count)
SELECT hk(name), 'sched_3nf', hk(admission_year::text, students_count::text), admission_year, students_count
FROM sched_3nf.student_group;

INSERT INTO sat_discipline (discipline_hk, record_source, hash_diff, name)
SELECT hk(name), 'sched_3nf', hk(name), name FROM sched_3nf.discipline;

INSERT INTO sat_room (room_hk, record_source, hash_diff, building_name, building_address, room_number, room_kind, capacity)
SELECT hk(b.name, r.number), 'sched_3nf', hk(b.address, k.name, r.capacity::text),
       b.name, b.address, r.number, k.name, r.capacity
FROM sched_3nf.room r
JOIN sched_3nf.building b  USING (building_id)
JOIN sched_3nf.room_kind k USING (room_kind_id);

INSERT INTO sat_semester (semester_hk, record_source, hash_diff, date_start, date_end)
SELECT hk(year_start::text, term_number::text), 'sched_3nf', hk(date_start::text, date_end::text), date_start, date_end
FROM sched_3nf.semester;

INSERT INTO sat_time_slot (time_slot_hk, record_source, hash_diff, start_time, end_time)
SELECT hk(slot_id::text), 'sched_3nf', hk(start_time::text, end_time::text), start_time, end_time
FROM sched_3nf.time_slot;

INSERT INTO sat_lesson_type (lesson_type_hk, record_source, hash_diff, name)
SELECT hk(name), 'sched_3nf', hk(name), name FROM sched_3nf.lesson_type;

-- ---- Связи ----
INSERT INTO lnk_department_faculty (department_faculty_hk, department_hk, faculty_hk, record_source)
SELECT hk(d.name, f.short_name), hk(d.name), hk(f.short_name), 'sched_3nf'
FROM sched_3nf.department d JOIN sched_3nf.faculty f USING (faculty_id);

INSERT INTO lnk_teacher_department (teacher_department_hk, teacher_hk, department_hk, record_source)
SELECT hk(t.email, d.name), hk(t.email), hk(d.name), 'sched_3nf'
FROM sched_3nf.teacher t JOIN sched_3nf.department d USING (department_id);

INSERT INTO lnk_discipline_department (discipline_department_hk, discipline_hk, department_hk, record_source)
SELECT hk(x.name, d.name), hk(x.name), hk(d.name), 'sched_3nf'
FROM sched_3nf.discipline x JOIN sched_3nf.department d USING (department_id);

INSERT INTO lnk_program_faculty (program_faculty_hk, program_hk, faculty_hk, record_source)
SELECT hk(p.code, f.short_name), hk(p.code), hk(f.short_name), 'sched_3nf'
FROM sched_3nf.study_program p JOIN sched_3nf.faculty f USING (faculty_id);

INSERT INTO lnk_group_program (group_program_hk, group_hk, program_hk, record_source)
SELECT hk(g.name, p.code), hk(g.name), hk(p.code), 'sched_3nf'
FROM sched_3nf.student_group g JOIN sched_3nf.study_program p USING (program_id);

INSERT INTO lnk_teacher_discipline (teacher_discipline_hk, teacher_hk, discipline_hk, record_source)
SELECT hk(t.email, d.name), hk(t.email), hk(d.name), 'sched_3nf'
FROM sched_3nf.teacher_discipline td
JOIN sched_3nf.teacher t    USING (teacher_id)
JOIN sched_3nf.discipline d USING (discipline_id);

INSERT INTO lnk_curriculum (curriculum_hk, program_hk, discipline_hk, course_no, term_number, record_source)
SELECT hk(p.code, d.name, c.course_no::text, c.term_number::text), hk(p.code), hk(d.name),
       c.course_no, c.term_number, 'sched_3nf'
FROM sched_3nf.curriculum_item c
JOIN sched_3nf.study_program p USING (program_id)
JOIN sched_3nf.discipline d    USING (discipline_id);

INSERT INTO sat_curriculum (curriculum_hk, record_source, hash_diff, lecture_hours, practice_hours, lab_hours)
SELECT hk(p.code, d.name, c.course_no::text, c.term_number::text), 'sched_3nf',
       hk(c.lecture_hours::text, c.practice_hours::text, c.lab_hours::text),
       c.lecture_hours, c.practice_hours, c.lab_hours
FROM sched_3nf.curriculum_item c
JOIN sched_3nf.study_program p USING (program_id)
JOIN sched_3nf.discipline d    USING (discipline_id);

-- Занятия расписания
INSERT INTO lnk_schedule_entry (schedule_entry_hk, semester_hk, group_hk, discipline_hk, teacher_hk,
                                lesson_type_hk, room_hk, time_slot_hk, weekday, week_parity, record_source)
SELECT hk(s.year_start::text, s.term_number::text, g.name, d.name, t.email, lt.name,
          b.name, r.number, e.slot_id::text, e.weekday::text, e.week_parity::text),
       hk(s.year_start::text, s.term_number::text), hk(g.name), hk(d.name), hk(t.email),
       hk(lt.name), hk(b.name, r.number), hk(e.slot_id::text), e.weekday, e.week_parity, 'sched_3nf'
FROM sched_3nf.schedule_entry e
JOIN sched_3nf.semester s     USING (semester_id)
JOIN sched_3nf.student_group g USING (group_id)
JOIN sched_3nf.discipline d   USING (discipline_id)
JOIN sched_3nf.teacher t      USING (teacher_id)
JOIN sched_3nf.lesson_type lt USING (lesson_type_id)
JOIN sched_3nf.room r         USING (room_id)
JOIN sched_3nf.building b     USING (building_id);

-- Проверка: актуальное расписание
SELECT * FROM v_current_schedule ORDER BY group_name, weekday, slot_code;
