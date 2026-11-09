-- SQL schema (PostgreSQL-compatible) для «Учёт выработки и премий»

-- 1. employees (сотрудники)
CREATE TABLE employees (
    id          INTEGER PRIMARY KEY,
    full_name   VARCHAR(255) NOT NULL,
    position    VARCHAR(255) NOT NULL,
    hire_date   DATE NOT NULL,
    role        VARCHAR(50) NOT NULL CHECK (role IN ('master', 'site_manager', 'employee', 'norm_admin')),
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. items (изделия)
CREATE TABLE items (
    id        INTEGER PRIMARY KEY,
    name      VARCHAR(255) NOT NULL,
    item_type VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 3. norms (нормы времени)
CREATE TABLE norms (
    id                  INTEGER PRIMARY KEY,
    item_id             INTEGER NOT NULL,
    norm_hours_per_item DECIMAL(10, 2) NOT NULL,
    valid_from          DATE NOT NULL,
    valid_to            DATE,
    version             INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT fk_norms_item FOREIGN KEY (item_id) REFERENCES items(id)
);

-- 4. productivity (выработка)
CREATE TABLE productivity (
    id          INTEGER PRIMARY KEY,
    employee_id INTEGER NOT NULL,
    item_id     INTEGER NOT NULL,
    month       CHAR(7) NOT NULL,
    items_count INTEGER NOT NULL DEFAULT 0,
    fact_hours  DECIMAL(10, 2) NOT NULL DEFAULT 0,
    norm_hours  DECIMAL(10, 2),
    ratio       DECIMAL(10, 4),
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_productivity_employee FOREIGN KEY (employee_id) REFERENCES employees(id),
    CONSTRAINT fk_productivity_item FOREIGN KEY (item_id) REFERENCES items(id),
    CONSTRAINT uq_productivity UNIQUE (employee_id, item_id, month)
);

-- 5. bonus_coefficients (справочник коэффициентов премии)
CREATE TABLE bonus_coefficients (
    id            INTEGER PRIMARY KEY,
    ratio_from    DECIMAL(10, 4) NOT NULL,
    ratio_to      DECIMAL(10, 4) NOT NULL,
    bonus_percent DECIMAL(5, 2) NOT NULL,
    valid_from    DATE NOT NULL,
    valid_to      DATE,
    CONSTRAINT chk_ratio CHECK (ratio_from < ratio_to),
    CONSTRAINT chk_percent CHECK (bonus_percent >= 0)
);

-- 6. bonus_accruals (начисления премий)
CREATE TABLE bonus_accruals (
    id                   INTEGER PRIMARY KEY,
    employee_id          INTEGER NOT NULL,
    month                CHAR(7) NOT NULL,
    ratio                DECIMAL(10, 4),
    bonus_coefficient_id INTEGER,
    bonus_percent        DECIMAL(5, 2),
    bonus_amount         DECIMAL(12, 2),
    status               VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'approved', 'adjusted')),
    approved_by          INTEGER,
    approved_at          TIMESTAMP,
    adjustment_reason    TEXT,
    CONSTRAINT fk_accruals_employee FOREIGN KEY (employee_id) REFERENCES employees(id),
    CONSTRAINT fk_accruals_coefficient FOREIGN KEY (bonus_coefficient_id) REFERENCES bonus_coefficients(id),
    CONSTRAINT fk_accruals_approved_by FOREIGN KEY (approved_by) REFERENCES employees(id),
    CONSTRAINT uq_accruals UNIQUE (employee_id, month)
);

-- 7. periods (расчётные периоды)
CREATE TABLE periods (
    id        INTEGER PRIMARY KEY,
    month     CHAR(7) NOT NULL UNIQUE,
    status    VARCHAR(20) NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed')),
    closed_by INTEGER,
    closed_at TIMESTAMP,
    CONSTRAINT fk_periods_closed_by FOREIGN KEY (closed_by) REFERENCES employees(id)
);

-- 8. audit_log (журнал аудита)
CREATE TABLE audit_log (
    id         INTEGER PRIMARY KEY,
    entity     VARCHAR(50) NOT NULL,
    entity_id  INTEGER NOT NULL,
    action     VARCHAR(20) NOT NULL CHECK (action IN ('create', 'update', 'delete')),
    changed_by INTEGER,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    old_value  TEXT,
    new_value  TEXT,
    CONSTRAINT fk_audit_changed_by FOREIGN KEY (changed_by) REFERENCES employees(id)
);

-- Индексы
CREATE INDEX idx_productivity_employee ON productivity(employee_id);
CREATE INDEX idx_productivity_item ON productivity(item_id);
CREATE INDEX idx_productivity_month ON productivity(month);
CREATE INDEX idx_norms_item ON norms(item_id);
CREATE INDEX idx_accruals_employee ON bonus_accruals(employee_id);
CREATE INDEX idx_accruals_month ON bonus_accruals(month);
CREATE INDEX idx_audit_entity ON audit_log(entity, entity_id);

-- Представление для выгрузки
CREATE VIEW v_productivity_summary AS
SELECT
    e.id            AS employee_id,
    e.full_name,
    p.month,
    i.name          AS item_name,
    p.items_count,
    p.norm_hours,
    p.fact_hours,
    p.ratio,
    bc.bonus_percent,
    ba.bonus_amount,
    ba.status       AS bonus_status
FROM productivity p
JOIN employees e ON e.id = p.employee_id
JOIN items i ON i.id = p.item_id
LEFT JOIN bonus_accruals ba ON ba.employee_id = e.id AND ba.month = p.month
LEFT JOIN bonus_coefficients bc ON bc.id = ba.bonus_coefficient_id;