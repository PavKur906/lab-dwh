-- =====================================================================
-- Лабораторная №2 (Data Vault), вариант 6
-- Система составления учебного графика дисциплин факультета
-- Модель 2: Data Vault 2.0 (Hub / Link / Satellite), СУБД PostgreSQL
--
-- Соглашения:
--   *_hk          - хеш-ключ (MD5 от бизнес-ключа в верхнем регистре), BYTEA
--   load_date     - время первой загрузки записи в хранилище
--   record_source - система-источник (название базы/файла)
--   hash_diff     - MD5 от всех описательных атрибутов сателлита
-- =====================================================================
DROP SCHEMA IF EXISTS sched_dv CASCADE;
CREATE SCHEMA sched_dv;
SET search_path TO sched_dv;

-- Функция расчёта хеш-ключа: части бизнес-ключа склеиваются через '||'
CREATE OR REPLACE FUNCTION hk(VARIADIC parts TEXT[]) RETURNS BYTEA
LANGUAGE sql IMMUTABLE AS $$
    SELECT decode(md5(upper(trim(array_to_string(parts, '||')))), 'hex');
$$;

-- ============================== HUBS ================================
CREATE TABLE hub_faculty (                        -- Факультет
    faculty_hk        BYTEA        PRIMARY KEY,
    faculty_code  VARCHAR(20) NOT NULL UNIQUE,    -- бизнес-ключ
    load_date     TIMESTAMP    NOT NULL DEFAULT now(),
    record_source VARCHAR(50)  NOT NULL
);
CREATE TABLE hub_department (                        -- Кафедра
    department_hk        BYTEA        PRIMARY KEY,
    department_code VARCHAR(40) NOT NULL UNIQUE,    -- бизнес-ключ
    load_date     TIMESTAMP    NOT NULL DEFAULT now(),
    record_source VARCHAR(50)  NOT NULL
);
CREATE TABLE hub_teacher (                        -- Преподаватель (табельный номер)
    teacher_hk        BYTEA        PRIMARY KEY,
    teacher_code  VARCHAR(40) NOT NULL UNIQUE,    -- бизнес-ключ
    load_date     TIMESTAMP    NOT NULL DEFAULT now(),
    record_source VARCHAR(50)  NOT NULL
);
CREATE TABLE hub_program (                        -- Направление подготовки (шифр)
    program_hk        BYTEA        PRIMARY KEY,
    program_code  VARCHAR(20) NOT NULL UNIQUE,    -- бизнес-ключ
    load_date     TIMESTAMP    NOT NULL DEFAULT now(),
    record_source VARCHAR(50)  NOT NULL
);
CREATE TABLE hub_group (                        -- Учебная группа
    group_hk        BYTEA        PRIMARY KEY,
    group_name    VARCHAR(30) NOT NULL UNIQUE,    -- бизнес-ключ
    load_date     TIMESTAMP    NOT NULL DEFAULT now(),
    record_source VARCHAR(50)  NOT NULL
);
CREATE TABLE hub_discipline (                        -- Дисциплина (код в учебном плане)
    discipline_hk        BYTEA        PRIMARY KEY,
    discipline_code VARCHAR(40) NOT NULL UNIQUE,    -- бизнес-ключ
    load_date     TIMESTAMP    NOT NULL DEFAULT now(),
    record_source VARCHAR(50)  NOT NULL
);
CREATE TABLE hub_room (                        -- Аудитория (корпус-номер)
    room_hk        BYTEA        PRIMARY KEY,
    room_code     VARCHAR(30) NOT NULL UNIQUE,    -- бизнес-ключ
    load_date     TIMESTAMP    NOT NULL DEFAULT now(),
    record_source VARCHAR(50)  NOT NULL
);
CREATE TABLE hub_semester (                        -- Семестр, напр. 2026-1
    semester_hk        BYTEA        PRIMARY KEY,
    semester_code VARCHAR(12) NOT NULL UNIQUE,    -- бизнес-ключ
    load_date     TIMESTAMP    NOT NULL DEFAULT now(),
    record_source VARCHAR(50)  NOT NULL
);
CREATE TABLE hub_time_slot (                        -- Номер пары
    time_slot_hk        BYTEA        PRIMARY KEY,
    slot_code     VARCHAR(4) NOT NULL UNIQUE,    -- бизнес-ключ
    load_date     TIMESTAMP    NOT NULL DEFAULT now(),
    record_source VARCHAR(50)  NOT NULL
);
CREATE TABLE hub_lesson_type (                        -- Вид занятия
    lesson_type_hk        BYTEA        PRIMARY KEY,
    lesson_type_code VARCHAR(20) NOT NULL UNIQUE,    -- бизнес-ключ
    load_date     TIMESTAMP    NOT NULL DEFAULT now(),
    record_source VARCHAR(50)  NOT NULL
);

-- ============================== LINKS ===============================
-- Связь "кафедра входит в факультет"
CREATE TABLE lnk_department_faculty (
    department_faculty_hk BYTEA PRIMARY KEY,
    department_hk BYTEA NOT NULL REFERENCES hub_department(department_hk),
    faculty_hk    BYTEA NOT NULL REFERENCES hub_faculty(faculty_hk),
    load_date     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL,
    UNIQUE (department_hk, faculty_hk)
);

-- Связь "преподаватель работает на кафедре"
CREATE TABLE lnk_teacher_department (
    teacher_department_hk BYTEA PRIMARY KEY,
    teacher_hk    BYTEA NOT NULL REFERENCES hub_teacher(teacher_hk),
    department_hk BYTEA NOT NULL REFERENCES hub_department(department_hk),
    load_date     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL,
    UNIQUE (teacher_hk, department_hk)
);

-- Связь "дисциплина закреплена за кафедрой"
CREATE TABLE lnk_discipline_department (
    discipline_department_hk BYTEA PRIMARY KEY,
    discipline_hk BYTEA NOT NULL REFERENCES hub_discipline(discipline_hk),
    department_hk BYTEA NOT NULL REFERENCES hub_department(department_hk),
    load_date     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL,
    UNIQUE (discipline_hk, department_hk)
);

-- Связь "направление относится к факультету"
CREATE TABLE lnk_program_faculty (
    program_faculty_hk BYTEA PRIMARY KEY,
    program_hk    BYTEA NOT NULL REFERENCES hub_program(program_hk),
    faculty_hk    BYTEA NOT NULL REFERENCES hub_faculty(faculty_hk),
    load_date     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL,
    UNIQUE (program_hk, faculty_hk)
);

-- Связь "группа обучается по направлению"
CREATE TABLE lnk_group_program (
    group_program_hk BYTEA PRIMARY KEY,
    group_hk      BYTEA NOT NULL REFERENCES hub_group(group_hk),
    program_hk    BYTEA NOT NULL REFERENCES hub_program(program_hk),
    load_date     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL,
    UNIQUE (group_hk, program_hk)
);

-- Связь M:N "преподаватель может вести дисциплину"
CREATE TABLE lnk_teacher_discipline (
    teacher_discipline_hk BYTEA PRIMARY KEY,
    teacher_hk    BYTEA NOT NULL REFERENCES hub_teacher(teacher_hk),
    discipline_hk BYTEA NOT NULL REFERENCES hub_discipline(discipline_hk),
    load_date     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL,
    UNIQUE (teacher_hk, discipline_hk)
);

-- Связь "дисциплина в учебном плане направления"
CREATE TABLE lnk_curriculum (
    curriculum_hk BYTEA PRIMARY KEY,
    program_hk    BYTEA NOT NULL REFERENCES hub_program(program_hk),
    discipline_hk BYTEA NOT NULL REFERENCES hub_discipline(discipline_hk),
    course_no     SMALLINT NOT NULL,      -- degenerate key: курс
    term_number   SMALLINT NOT NULL,      -- degenerate key: семестр в году
    load_date     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL,
    UNIQUE (program_hk, discipline_hk, course_no, term_number)
);

-- Главная связь: занятие в расписании
-- (день недели и чётность недели входят в ключ связи как degenerate keys)
CREATE TABLE lnk_schedule_entry (
    schedule_entry_hk BYTEA PRIMARY KEY,
    semester_hk    BYTEA NOT NULL REFERENCES hub_semester(semester_hk),
    group_hk       BYTEA NOT NULL REFERENCES hub_group(group_hk),
    discipline_hk  BYTEA NOT NULL REFERENCES hub_discipline(discipline_hk),
    teacher_hk     BYTEA NOT NULL REFERENCES hub_teacher(teacher_hk),
    lesson_type_hk BYTEA NOT NULL REFERENCES hub_lesson_type(lesson_type_hk),
    room_hk        BYTEA NOT NULL REFERENCES hub_room(room_hk),
    time_slot_hk   BYTEA NOT NULL REFERENCES hub_time_slot(time_slot_hk),
    weekday        SMALLINT NOT NULL,
    week_parity    SMALLINT NOT NULL,
    load_date      TIMESTAMP   NOT NULL DEFAULT now(),
    record_source  VARCHAR(50) NOT NULL,
    UNIQUE (semester_hk, group_hk, discipline_hk, teacher_hk, lesson_type_hk,
            room_hk, time_slot_hk, weekday, week_parity)
);
CREATE INDEX ix_lnk_sched_group   ON lnk_schedule_entry (group_hk);
CREATE INDEX ix_lnk_sched_teacher ON lnk_schedule_entry (teacher_hk);
CREATE INDEX ix_lnk_sched_room    ON lnk_schedule_entry (room_hk);

-- ============================ SATELLITES ============================
-- Первичный ключ сателлита = (хеш-ключ родителя, load_date): история изменений.

CREATE TABLE sat_faculty (
    faculty_hk BYTEA NOT NULL REFERENCES hub_faculty(faculty_hk),
    load_date     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL,
    hash_diff     BYTEA       NOT NULL,
    name VARCHAR(150) NOT NULL,
    short_name VARCHAR(20) NOT NULL,
    PRIMARY KEY (faculty_hk, load_date)
);
CREATE TABLE sat_department (
    department_hk BYTEA NOT NULL REFERENCES hub_department(department_hk),
    load_date     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL,
    hash_diff     BYTEA       NOT NULL,
    name VARCHAR(150) NOT NULL,
    PRIMARY KEY (department_hk, load_date)
);
CREATE TABLE sat_teacher (
    teacher_hk BYTEA NOT NULL REFERENCES hub_teacher(teacher_hk),
    load_date     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL,
    hash_diff     BYTEA       NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    first_name VARCHAR(60) NOT NULL,
    middle_name VARCHAR(60),
    academic_position VARCHAR(60),
    email VARCHAR(120),
    PRIMARY KEY (teacher_hk, load_date)
);
CREATE TABLE sat_program (
    program_hk BYTEA NOT NULL REFERENCES hub_program(program_hk),
    load_date     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL,
    hash_diff     BYTEA       NOT NULL,
    name VARCHAR(150) NOT NULL,
    duration_year SMALLINT NOT NULL,
    PRIMARY KEY (program_hk, load_date)
);
CREATE TABLE sat_group (
    group_hk BYTEA NOT NULL REFERENCES hub_group(group_hk),
    load_date     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL,
    hash_diff     BYTEA       NOT NULL,
    admission_year SMALLINT NOT NULL,
    students_count SMALLINT NOT NULL,
    PRIMARY KEY (group_hk, load_date)
);
CREATE TABLE sat_discipline (
    discipline_hk BYTEA NOT NULL REFERENCES hub_discipline(discipline_hk),
    load_date     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL,
    hash_diff     BYTEA       NOT NULL,
    name VARCHAR(150) NOT NULL,
    PRIMARY KEY (discipline_hk, load_date)
);
CREATE TABLE sat_room (
    room_hk BYTEA NOT NULL REFERENCES hub_room(room_hk),
    load_date     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL,
    hash_diff     BYTEA       NOT NULL,
    building_name VARCHAR(60) NOT NULL,
    building_address VARCHAR(200),
    room_number VARCHAR(10) NOT NULL,
    room_kind VARCHAR(60),
    capacity SMALLINT NOT NULL,
    PRIMARY KEY (room_hk, load_date)
);
CREATE TABLE sat_semester (
    semester_hk BYTEA NOT NULL REFERENCES hub_semester(semester_hk),
    load_date     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL,
    hash_diff     BYTEA       NOT NULL,
    date_start DATE NOT NULL,
    date_end DATE NOT NULL,
    PRIMARY KEY (semester_hk, load_date)
);
CREATE TABLE sat_time_slot (
    time_slot_hk BYTEA NOT NULL REFERENCES hub_time_slot(time_slot_hk),
    load_date     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL,
    hash_diff     BYTEA       NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    PRIMARY KEY (time_slot_hk, load_date)
);
CREATE TABLE sat_lesson_type (
    lesson_type_hk BYTEA NOT NULL REFERENCES hub_lesson_type(lesson_type_hk),
    load_date     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL,
    hash_diff     BYTEA       NOT NULL,
    name VARCHAR(40) NOT NULL,
    PRIMARY KEY (lesson_type_hk, load_date)
);
-- Описательные данные связей
CREATE TABLE sat_curriculum (
    curriculum_hk BYTEA NOT NULL REFERENCES lnk_curriculum(curriculum_hk),
    load_date     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL,
    hash_diff     BYTEA       NOT NULL,
    lecture_hours  SMALLINT NOT NULL,
    practice_hours SMALLINT NOT NULL,
    lab_hours      SMALLINT NOT NULL,
    PRIMARY KEY (curriculum_hk, load_date)
);

-- Статус занятия: перенесено, отменено, комментарий диспетчера
CREATE TABLE sat_schedule_entry (
    schedule_entry_hk BYTEA NOT NULL REFERENCES lnk_schedule_entry(schedule_entry_hk),
    load_date     TIMESTAMP   NOT NULL DEFAULT now(),
    record_source VARCHAR(50) NOT NULL,
    hash_diff     BYTEA       NOT NULL,
    status        VARCHAR(20) NOT NULL DEFAULT 'planned',  -- planned / moved / cancelled
    comment       TEXT,
    PRIMARY KEY (schedule_entry_hk, load_date)
);

-- ========================= BUSINESS VAULT ===========================
-- Актуальное расписание: берём последнюю версию каждого сателлита
CREATE VIEW v_current_schedule AS
SELECT s.semester_code, g.group_name, d.discipline_code, sd.name AS discipline,
       lt.name AS lesson_type, l.weekday, l.week_parity, ts.slot_code,
       st.start_time, st.end_time, sr.building_name, sr.room_number,
       t.last_name || ' ' || t.first_name AS teacher, se.status
FROM lnk_schedule_entry l
JOIN hub_semester    s  USING (semester_hk)
JOIN hub_group       g  USING (group_hk)
JOIN hub_discipline  d  USING (discipline_hk)
JOIN hub_teacher     tt USING (teacher_hk)
JOIN hub_room        r  USING (room_hk)
JOIN hub_time_slot   ts USING (time_slot_hk)
JOIN LATERAL (SELECT * FROM sat_discipline x WHERE x.discipline_hk = d.discipline_hk ORDER BY load_date DESC LIMIT 1) sd ON true
JOIN LATERAL (SELECT * FROM sat_teacher    x WHERE x.teacher_hk    = tt.teacher_hk  ORDER BY load_date DESC LIMIT 1) t  ON true
JOIN LATERAL (SELECT * FROM sat_room       x WHERE x.room_hk       = r.room_hk      ORDER BY load_date DESC LIMIT 1) sr ON true
JOIN LATERAL (SELECT * FROM sat_time_slot  x WHERE x.time_slot_hk  = ts.time_slot_hk ORDER BY load_date DESC LIMIT 1) st ON true
JOIN hub_lesson_type lt0 USING (lesson_type_hk)
JOIN LATERAL (SELECT * FROM sat_lesson_type x WHERE x.lesson_type_hk = lt0.lesson_type_hk ORDER BY load_date DESC LIMIT 1) lt ON true
LEFT JOIN LATERAL (SELECT * FROM sat_schedule_entry x WHERE x.schedule_entry_hk = l.schedule_entry_hk ORDER BY load_date DESC LIMIT 1) se ON true;
