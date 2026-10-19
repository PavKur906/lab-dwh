-- Тестовые данные для 3NF-модели (факультет информационных технологий)
SET search_path TO sched_3nf;

INSERT INTO faculty (name, short_name) VALUES ('Факультет информационных технологий','ФИТ');
INSERT INTO department (faculty_id, name) VALUES
 (1,'Кафедра информационных систем'),(1,'Кафедра программной инженерии'),(1,'Кафедра высшей математики');
INSERT INTO academic_position (title) VALUES ('Ассистент'),('Доцент'),('Профессор');
INSERT INTO teacher (department_id, position_id, last_name, first_name, middle_name, email) VALUES
 (1,2,'Иванов','Пётр','Сергеевич','ivanov@uni.example'),
 (1,3,'Смирнова','Ольга','Андреевна','smirnova@uni.example'),
 (2,2,'Кузнецов','Андрей','Викторович','kuznetsov@uni.example'),
 (2,1,'Попова','Мария','Игоревна','popova@uni.example'),
 (3,3,'Орлов','Николай','Петрович','orlov@uni.example');
INSERT INTO study_program (faculty_id, code, name, duration_year) VALUES
 (1,'09.03.02','Информационные системы и технологии',4),
 (1,'09.03.04','Программная инженерия',4);
INSERT INTO student_group (program_id, name, admission_year, students_count) VALUES
 (1,'ИС-21',2025,25),(1,'ИС-22',2025,27),(2,'ПИ-21',2025,30);
INSERT INTO discipline (department_id, name) VALUES
 (1,'Хранилища данных'),(1,'Базы данных'),(2,'Объектно-ориентированное программирование'),
 (3,'Математический анализ'),(2,'Тестирование программного обеспечения');
INSERT INTO lesson_type (name) VALUES ('Лекция'),('Практика'),('Лабораторная работа');
INSERT INTO building (name, address) VALUES ('Главный корпус','ул. Университетская, 1'),('Корпус Б','ул. Университетская, 3');
INSERT INTO room_kind (name) VALUES ('Лекционная аудитория'),('Компьютерный класс');
INSERT INTO room (building_id, room_kind_id, number, capacity) VALUES
 (1,1,'101',120),(1,2,'214',30),(2,2,'305',28),(2,1,'210',80);
INSERT INTO time_slot (slot_id, start_time, end_time) VALUES
 (1,'08:30','10:00'),(2,'10:10','11:40'),(3,'12:10','13:40'),(4,'13:50','15:20'),(5,'15:30','17:00');
INSERT INTO semester (year_start, term_number, date_start, date_end) VALUES (2026,1,'2026-09-01','2026-12-31');
INSERT INTO curriculum_item (program_id, discipline_id, course_no, term_number, lecture_hours, practice_hours, lab_hours) VALUES
 (1,1,2,1,32,0,32),(1,2,2,1,32,16,16),(1,4,2,1,32,32,0),(2,3,2,1,32,0,48),(2,5,2,1,16,16,16);
INSERT INTO teacher_discipline VALUES (1,1),(2,1),(2,2),(3,3),(4,3),(4,5),(5,4);
INSERT INTO schedule_entry (semester_id, group_id, discipline_id, teacher_id, lesson_type_id, room_id, slot_id, weekday, week_parity) VALUES
 (1,1,1,2,1,1,1,1,0),   -- ИС-21, Хранилища данных, лекция, пн 1 пара
 (1,1,1,1,3,2,2,1,0),   -- ИС-21, Хранилища данных, лаб., пн 2 пара
 (1,2,1,1,3,2,3,1,0),   -- ИС-22, Хранилища данных, лаб., пн 3 пара
 (1,1,2,2,1,1,1,3,0),   -- ИС-21, Базы данных, лекция, ср 1 пара
 (1,1,4,5,2,4,2,3,0),   -- ИС-21, Мат. анализ, практика, ср 2 пара
 (1,3,3,3,3,3,2,2,0),   -- ПИ-21, ООП, лаб., вт 2 пара
 (1,3,5,4,2,3,3,4,1);   -- ПИ-21, Тестирование, практика, чт 3 пара, нечётная неделя
