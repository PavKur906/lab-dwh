-- =====================================================================
-- Лабораторная №2 (Data Vault), вариант 6
-- Система составления учебного графика дисциплин факультета
-- Модель 1: третья нормальная форма (3NF), СУБД PostgreSQL
-- =====================================================================
DROP SCHEMA IF EXISTS sched_3nf CASCADE;
CREATE SCHEMA sched_3nf;
SET search_path TO sched_3nf;

-- ---------- Справочники ----------
CREATE TABLE faculty (                       -- Факультет
    faculty_id   SERIAL       PRIMARY KEY,
    name         VARCHAR(150) NOT NULL UNIQUE,
    short_name   VARCHAR(20)  NOT NULL UNIQUE
);
COMMENT ON TABLE faculty IS 'Факультеты института';

CREATE TABLE department (                    -- Кафедра
    department_id SERIAL       PRIMARY KEY,
    faculty_id    INT          NOT NULL REFERENCES faculty(faculty_id),
    name          VARCHAR(150) NOT NULL,
    UNIQUE (faculty_id, name)
);
COMMENT ON TABLE department IS 'Кафедры, принадлежащие факультету';

CREATE TABLE academic_position (             -- Должность преподавателя
    position_id SERIAL      PRIMARY KEY,
    title       VARCHAR(60) NOT NULL UNIQUE  -- ассистент, доцент, профессор ...
);

CREATE TABLE teacher (                       -- Преподаватель
    teacher_id    SERIAL       PRIMARY KEY,
    department_id INT          NOT NULL REFERENCES department(department_id),
    position_id   INT          NOT NULL REFERENCES academic_position(position_id),
    last_name     VARCHAR(60)  NOT NULL,
    first_name    VARCHAR(60)  NOT NULL,
    middle_name   VARCHAR(60),
    email         VARCHAR(120) UNIQUE
);
COMMENT ON TABLE teacher IS 'Преподаватели; каждый закреплён за одной кафедрой';

CREATE TABLE study_program (                 -- Направление / программа обучения
    program_id    SERIAL       PRIMARY KEY,
    faculty_id    INT          NOT NULL REFERENCES faculty(faculty_id),
    code          VARCHAR(20)  NOT NULL UNIQUE,   -- напр. 09.03.04
    name          VARCHAR(150) NOT NULL,
    duration_year SMALLINT     NOT NULL CHECK (duration_year BETWEEN 1 AND 7)
);

CREATE TABLE student_group (                 -- Учебная группа
    group_id      SERIAL      PRIMARY KEY,
    program_id    INT         NOT NULL REFERENCES study_program(program_id),
    name          VARCHAR(30) NOT NULL UNIQUE,
    admission_year SMALLINT   NOT NULL,
    students_count SMALLINT   NOT NULL CHECK (students_count > 0)
);

CREATE TABLE discipline (                    -- Дисциплина
    discipline_id SERIAL       PRIMARY KEY,
    department_id INT          NOT NULL REFERENCES department(department_id),
    name          VARCHAR(150) NOT NULL,
    UNIQUE (department_id, name)
);
COMMENT ON TABLE discipline IS 'Дисциплины; ответственная кафедра хранится здесь';

CREATE TABLE lesson_type (                   -- Вид занятия
    lesson_type_id SERIAL      PRIMARY KEY,
    name           VARCHAR(40) NOT NULL UNIQUE   -- лекция, практика, лабораторная
);

CREATE TABLE building (                      -- Корпус
    building_id SERIAL       PRIMARY KEY,
    name        VARCHAR(60)  NOT NULL UNIQUE,
    address     VARCHAR(200) NOT NULL
);

CREATE TABLE room_kind (                     -- Тип аудитории
    room_kind_id SERIAL      PRIMARY KEY,
    name         VARCHAR(60) NOT NULL UNIQUE     -- лекционная, компьютерный класс ...
);

CREATE TABLE room (                          -- Аудитория
    room_id      SERIAL      PRIMARY KEY,
    building_id  INT         NOT NULL REFERENCES building(building_id),
    room_kind_id INT         NOT NULL REFERENCES room_kind(room_kind_id),
    number       VARCHAR(10) NOT NULL,
    capacity     SMALLINT    NOT NULL CHECK (capacity > 0),
    UNIQUE (building_id, number)
);

CREATE TABLE time_slot (                     -- Номер пары и время
    slot_id    SMALLINT PRIMARY KEY CHECK (slot_id BETWEEN 1 AND 8),
    start_time TIME     NOT NULL,
    end_time   TIME     NOT NULL,
    CHECK (end_time > start_time)
);

CREATE TABLE semester (                      -- Семестр
    semester_id SERIAL   PRIMARY KEY,
    year_start  SMALLINT NOT NULL,             -- учебный год начинается в ...
    term_number SMALLINT NOT NULL CHECK (term_number IN (1, 2)),
    date_start  DATE     NOT NULL,
    date_end    DATE     NOT NULL,
    UNIQUE (year_start, term_number),
    CHECK (date_end > date_start)
);

-- ---------- Учебный план ----------
CREATE TABLE curriculum_item (               -- Дисциплина в плане направления
    curriculum_id   SERIAL   PRIMARY KEY,
    program_id      INT      NOT NULL REFERENCES study_program(program_id),
    discipline_id   INT      NOT NULL REFERENCES discipline(discipline_id),
    course_no       SMALLINT NOT NULL CHECK (course_no BETWEEN 1 AND 6),
    term_number     SMALLINT NOT NULL CHECK (term_number IN (1, 2)),
    lecture_hours   SMALLINT NOT NULL DEFAULT 0 CHECK (lecture_hours   >= 0),
    practice_hours  SMALLINT NOT NULL DEFAULT 0 CHECK (practice_hours  >= 0),
    lab_hours       SMALLINT NOT NULL DEFAULT 0 CHECK (lab_hours       >= 0),
    UNIQUE (program_id, discipline_id, course_no, term_number)
);
COMMENT ON TABLE curriculum_item IS 'Сколько часов каждого вида занятий положено по плану';

-- Какие преподаватели могут вести дисциплину (M:N)
CREATE TABLE teacher_discipline (
    teacher_id    INT NOT NULL REFERENCES teacher(teacher_id),
    discipline_id INT NOT NULL REFERENCES discipline(discipline_id),
    PRIMARY KEY (teacher_id, discipline_id)
);

-- ---------- Расписание ----------
CREATE TABLE schedule_entry (                -- Занятие в расписании
    entry_id       SERIAL   PRIMARY KEY,
    semester_id    INT      NOT NULL REFERENCES semester(semester_id),
    group_id       INT      NOT NULL REFERENCES student_group(group_id),
    discipline_id  INT      NOT NULL REFERENCES discipline(discipline_id),
    teacher_id     INT      NOT NULL REFERENCES teacher(teacher_id),
    lesson_type_id INT      NOT NULL REFERENCES lesson_type(lesson_type_id),
    room_id        INT      NOT NULL REFERENCES room(room_id),
    slot_id        SMALLINT NOT NULL REFERENCES time_slot(slot_id),
    weekday        SMALLINT NOT NULL CHECK (weekday BETWEEN 1 AND 6),   -- 1 = понедельник
    week_parity    SMALLINT NOT NULL DEFAULT 0 CHECK (week_parity IN (0, 1, 2)), -- 0 каждая, 1 нечётная, 2 чётная
    -- конфликты: одна группа / один преподаватель / одна аудитория не могут быть заняты дважды
    UNIQUE (semester_id, group_id,   weekday, slot_id, week_parity),
    UNIQUE (semester_id, teacher_id, weekday, slot_id, week_parity),
    UNIQUE (semester_id, room_id,    weekday, slot_id, week_parity)
);
COMMENT ON TABLE schedule_entry IS 'Одно занятие: кто, что, где и когда';
CREATE INDEX ix_schedule_group   ON schedule_entry (group_id);
CREATE INDEX ix_schedule_teacher ON schedule_entry (teacher_id);
