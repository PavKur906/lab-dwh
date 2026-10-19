# Хранилища данных: лабораторная №2 (Data Vault)

Вариант 6 — система составления учебного графика дисциплин факультета.
Две модели БД в PostgreSQL: третья нормальная форма и Data Vault 2.0.

| Файл | Назначение |
|---|---|
| `sql/01_schema_3nf.sql` | схема `sched_3nf`: 16 таблиц в 3НФ |
| `sql/02_schema_data_vault.sql` | схема `sched_dv`: 10 хабов, 8 ссылок, 12 сателлитов, представление `v_current_schedule` |
| `sql/03_seed_3nf.sql` | тестовые данные |
| `sql/04_load_data_vault.sql` | загрузка Data Vault из 3НФ-модели |
| `docs/erd_3nf.png`, `docs/erd_dv.png` | схемы моделей |

## Запуск
```bash
createdb schedule
psql -d schedule -f sql/01_schema_3nf.sql
psql -d schedule -f sql/02_schema_data_vault.sql
psql -d schedule -f sql/03_seed_3nf.sql
psql -d schedule -f sql/04_load_data_vault.sql
```
