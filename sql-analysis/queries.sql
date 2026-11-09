-- SQL-запросы для анализа данных
-- Проект: учёт выработки и расчёт премий

-- 1. Ежедневный контроль выработки: агрегация по сотруднику за месяц
-- Выявляет отставания и незавершённые изделия
SELECT
    e.full_name,
    p.month,
    SUM(p.items_count) AS total_items,
    SUM(p.norm_hours) AS total_norm_hours,
    SUM(p.fact_hours) AS total_fact_hours,
    ROUND(SUM(p.norm_hours) / NULLIF(SUM(p.fact_hours), 0), 4) AS ratio
FROM productivity p
JOIN employees e ON e.id = p.employee_id
WHERE p.month = '2025-10'
GROUP BY e.full_name, p.month
ORDER BY ratio ASC;

-- 2. Сводная таблица для мастера: сотрудник, изделие, норма, факт, соотношение
SELECT
    e.full_name,
    i.name AS item_name,
    p.month,
    p.items_count,
    p.norm_hours,
    p.fact_hours,
    p.ratio
FROM productivity p
JOIN employees e ON e.id = p.employee_id
JOIN items i ON i.id = p.item_id
WHERE p.month = '2025-10'
ORDER BY e.full_name, i.name;

-- 3. Выгрузка для отчёта: сводная таблица с премиями
SELECT
    e.full_name,
    p.month,
    SUM(p.items_count) AS total_items,
    SUM(p.fact_hours) AS total_fact_hours,
    ROUND(AVG(p.ratio), 4) AS avg_ratio,
    bc.bonus_percent,
    ba.bonus_amount,
    ba.status AS bonus_status
FROM productivity p
JOIN employees e ON e.id = p.employee_id
LEFT JOIN bonus_accruals ba ON ba.employee_id = e.id AND ba.month = p.month
LEFT JOIN bonus_coefficients bc ON bc.id = ba.bonus_coefficient_id
WHERE p.month = '2025-10'
GROUP BY e.full_name, p.month, bc.bonus_percent, ba.bonus_amount, ba.status
ORDER BY e.full_name;

-- 4. Сотрудники с отставанием (ratio < 1) за месяц
SELECT
    e.full_name,
    p.month,
    SUM(p.items_count) AS total_items,
    ROUND(SUM(p.norm_hours) / NULLIF(SUM(p.fact_hours), 0), 4) AS ratio
FROM productivity p
JOIN employees e ON e.id = p.employee_id
WHERE p.month = '2025-10'
GROUP BY e.full_name, p.month
HAVING SUM(p.norm_hours) / NULLIF(SUM(p.fact_hours), 0) < 1
ORDER BY ratio ASC;

-- 5. История изменений по сотруднику (для аудита)
SELECT
    al.entity,
    al.entity_id,
    al.action,
    e.full_name AS changed_by_name,
    al.changed_at,
    al.old_value,
    al.new_value
FROM audit_log al
LEFT JOIN employees e ON e.id = al.changed_by
ORDER BY al.changed_at DESC;
