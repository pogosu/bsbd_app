-- ==========================================
-- 0. ОЧИСТКА СТАРЫХ ДАННЫХ
-- ==========================================

DO $$
BEGIN
    -- Удаление пользователей
    IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'Citizen1') THEN DROP USER "Citizen1"; END IF;
    IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'Citizen2') THEN DROP USER "Citizen2"; END IF;
    IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'Inspector1') THEN DROP USER "Inspector1"; END IF;
    IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'AdminUser') THEN DROP USER "AdminUser"; END IF;
    
    -- Удаление ролей
    IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'Гражданин') THEN DROP ROLE "Гражданин"; END IF;
    IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'Инспектор') THEN DROP ROLE "Инспектор"; END IF;
    IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'Администратор') THEN DROP ROLE "Администратор"; END IF;
END
$$;

DROP TABLE IF EXISTS "Платеж" CASCADE;
DROP TABLE IF EXISTS "Штраф" CASCADE;
DROP TABLE IF EXISTS "Автомобиль" CASCADE;
DROP TABLE IF EXISTS "Инспектор" CASCADE;
DROP TABLE IF EXISTS "Гражданин" CASCADE;


-- ==========================================
-- 1. СОЗДАНИЕ ТАБЛИЦ
-- ==========================================

CREATE TABLE "Гражданин" (
    "id_Гражданина" SERIAL PRIMARY KEY CHECK ("id_Гражданина" > 0),
    "ФИО" VARCHAR(100) NOT NULL CHECK ("ФИО" ~ '^[А-ЯЁа-яё\s\-]+$'),
    "Адрес_регистрации" VARCHAR(150) NOT NULL,
    "Номер_телефона" VARCHAR(12) NOT NULL UNIQUE CHECK ("Номер_телефона" ~ '^(\+7|8)[0-9]{10}$'),
    "Номер_ВУ" CHAR(12) NOT NULL UNIQUE CHECK ("Номер_ВУ" ~ '^[0-9]{2} [0-9]{2} [0-9]{6}$')
);

CREATE TABLE "Инспектор" (
    "id_Инспектора" SERIAL PRIMARY KEY CHECK ("id_Инспектора" > 0),
    "ФИО" VARCHAR(100) NOT NULL CHECK ("ФИО" ~ '^[А-ЯЁа-яё\s\-]+$'),
    "Звание" VARCHAR(50) NOT NULL,
    "Номер_удостоверения" VARCHAR(12) NOT NULL UNIQUE CHECK ("Номер_удостоверения" ~ '^[0-9]+$'),
    "Подразделение" VARCHAR(80) NOT NULL
);

CREATE TABLE "Автомобиль" (
    "id_Автомобиля" SERIAL PRIMARY KEY CHECK ("id_Автомобиля" > 0),
    "id_Гражданина" INT NOT NULL REFERENCES "Гражданин"("id_Гражданина"),
    "Госномер" VARCHAR(9) NOT NULL UNIQUE 
        CHECK ("Госномер" ~ '^([АВЕКМНОРСТУХABEKMHOPCTYX]{1}[0-9]{3}[АВЕКМНОРСТУХABEKMHOPCTYX]{2}[0-9]{0,3})$' 
               AND LENGTH("Госномер") BETWEEN 8 AND 9),
    "Марка" VARCHAR(50) NOT NULL CHECK ("Марка" ~ '^[А-ЯЁA-Zа-яёa-z]+$'),
    "Модель" VARCHAR(50) NOT NULL CHECK ("Модель" ~ '^[А-ЯЁA-Zа-яёa-z0-9\s\-]+$')
);

CREATE TABLE "Штраф" (
    "id_Штрафа" SERIAL PRIMARY KEY CHECK ("id_Штрафа" > 0),
    "id_Гражданина" INT NOT NULL REFERENCES "Гражданин"("id_Гражданина"),
    "id_Автомобиля" INT NOT NULL REFERENCES "Автомобиль"("id_Автомобиля"),
    "Сумма" DECIMAL(10,2) NOT NULL CHECK ("Сумма" > 0),
    "Дата_и_время" TIMESTAMP NOT NULL CHECK ("Дата_и_время" <= CURRENT_TIMESTAMP + interval '1 second'),
    "Статус" VARCHAR(11) NOT NULL CHECK ("Статус" IN ('ОПЛАЧЕН', 'НЕ ОПЛАЧЕН')),
    "Место_нарушения" VARCHAR(100) NOT NULL,
    "Причина_штрафа" VARCHAR(100) NOT NULL,
    "id_Инспектора" INT NOT NULL REFERENCES "Инспектор"("id_Инспектора")
);

CREATE TABLE "Платеж" (
    "id_Платежа" SERIAL PRIMARY KEY CHECK ("id_Платежа" > 0),
    "Дата_и_время" TIMESTAMP NOT NULL CHECK ("Дата_и_время" <= CURRENT_TIMESTAMP + interval '1 second'),
    "Сумма" DECIMAL(10,2) NOT NULL CHECK ("Сумма" > 0),
    "id_Штрафа" INT NOT NULL REFERENCES "Штраф"("id_Штрафа"),
    "Способ_платежа" VARCHAR(30) NOT NULL
);


-- ==========================================
-- 2. ЗАПОЛНЕНИЕ ДАННЫМИ СОЗДАННЫХ ТАБЛИЦ
-- ==========================================

INSERT INTO "Гражданин" ("ФИО", "Адрес_регистрации", "Номер_телефона", "Номер_ВУ")
VALUES
('Занько Андрей Александрович', 'г. Москва, ул. Ленина, д. 1', '+79991234567', '12 34 567890'),
('Крючков Виталий Геннадиевич', 'г. Санкт-Петербург, пр. Мира, д. 10', '89111234567', '56 78 123456'),
('Кочетов Илья Михайлович', 'г. Екатеринбург, ул. 8 Марта, д. 50', '89235678901', '11 22 333444'),
('Матафонов Артем Вячеславович', 'г. Новосибирск, ул. Советская, д. 15', '+79010020030', '98 76 543210'),
('Попова Светлана Андреевна', 'г. Казань, ул. Чуйкова, д. 24', '89876543210', '22 33 121212');

INSERT INTO "Автомобиль" ("id_Гражданина", "Госномер", "Марка", "Модель")
VALUES
(1, 'Т234ОР77', 'Toyota', 'Corona Premio'),
(2, 'Р465ЕВ116', 'Renault', 'Logan'),
(3, 'К789УК96', 'Subaru', 'Impreza'),
(4, 'М321ТР190', 'Lada', 'Priora'),
(5, 'А111ВВ77', 'Daewoo', 'Matiz');

INSERT INTO "Инспектор" ("ФИО", "Звание", "Номер_удостоверения", "Подразделение")
VALUES
('Смирнов Андрей Викторович', 'Капитан', '10001', 'ГИБДД Москва'),
('Егорова Анна Павловна', 'Майор', '10002', 'ГИБДД СПб'),
('Чистяков Сергей Иванович', 'Старший лейтенант', '10003', 'ГИБДД Екатеринбург'),
('Литвинова Дарья Игоревна', 'Лейтенант', '10004', 'ГИБДД Новосибирск'),
('Макаров Николай Львович', 'Полковник', '10005', 'ГИБДД Казань');

INSERT INTO "Штраф" ("id_Гражданина", "id_Автомобиля", "Сумма", "Дата_и_время", "Статус", "Место_нарушения", "Причина_штрафа", "id_Инспектора")
VALUES
(1, 1, 900.00, '2025-11-20 12:16:00', 'НЕ ОПЛАЧЕН', 'Москва, ул. Ленина', 'Превышение скорости на +27 км/ч', 1),
(2, 2, 1500.00, '2025-11-16 13:45:00', 'НЕ ОПЛАЧЕН', 'СПб, ул. Мира', 'Красный свет на перекрестке', 2),
(3, 3, 800.00, '2025-11-10 14:30:00', 'НЕ ОПЛАЧЕН', 'Екатеринбург, ул. 8 Марта', 'Остановка под знаком "Стоянка запрещена"', 3),
(4, 4, 400.00, '2025-11-12 19:20:00', 'НЕ ОПЛАЧЕН', 'Новосибирск, Советская', 'Разворот через двойную сплошную', 4),
(5, 5, 300.00, '2025-10-28 17:10:00', 'НЕ ОПЛАЧЕН', 'Казань, ул. Чуйкова', 'Не уступил дорогу пешеходу', 5);

INSERT INTO "Платеж" ("Дата_и_время", "Сумма", "id_Штрафа", "Способ_платежа")
VALUES
('2025-11-23 15:10:00', 900.00, 1, 'Онлайн'),
('2025-11-17 14:00:00', 1500.00, 2, 'Карта');


-- ==========================================
-- 3. РЕАЛИЗАЦИЯ РАЗГРАНИЧЕНИЯ ПРАВ ДОСТУПА
-- ==========================================

CREATE ROLE "Гражданин";
CREATE ROLE "Инспектор";
CREATE ROLE "Администратор";

CREATE USER "Citizen1"  WITH PASSWORD 'citizen1';
CREATE USER "Citizen2"  WITH PASSWORD 'citizen2';
CREATE USER "Inspector1" WITH PASSWORD 'inspector1';
CREATE USER "AdminUser"  WITH PASSWORD 'admin123';

GRANT "Гражданин"    TO "Citizen1";
GRANT "Гражданин"    TO "Citizen2";
GRANT "Инспектор"    TO "Inspector1";
GRANT "Администратор" TO "AdminUser";

-- Функции для определения ID должны использовать session_user, 
-- чтобы работать внутри SECURITY DEFINER функций.
CREATE OR REPLACE FUNCTION get_citizen_id()
RETURNS int LANGUAGE sql STABLE AS $$
    SELECT substring(session_user from '[0-9]+')::int;
$$;

CREATE OR REPLACE FUNCTION get_inspector_id()
RETURNS int LANGUAGE sql STABLE AS $$
    SELECT substring(session_user from '[0-9]+')::int;
$$;

GRANT SELECT ON "Гражданин", "Автомобиль", "Штраф", "Платеж" TO "Гражданин";
GRANT INSERT ON "Платеж" TO "Гражданин";

GRANT SELECT ON "Гражданин", "Автомобиль", "Штраф", "Инспектор" TO "Инспектор";
GRANT INSERT ON "Штраф" TO "Инспектор";

GRANT SELECT, INSERT, UPDATE, DELETE ON "Гражданин", "Автомобиль", "Штраф", "Платеж", "Инспектор" TO "Администратор";
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO "Гражданин", "Инспектор", "Администратор";

ALTER TABLE "Гражданин"  ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Автомобиль" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Штраф"      ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Платеж"     ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Инспектор"  ENABLE ROW LEVEL SECURITY;

-- Политики Гражданина (используют get_citizen_id(), которая теперь на session_user)
CREATE POLICY citizen_see_self ON "Гражданин" FOR SELECT TO "Гражданин" USING ("id_Гражданина" = get_citizen_id());
CREATE POLICY citizen_see_own_cars ON "Автомобиль" FOR SELECT TO "Гражданин" USING ("id_Гражданина" = get_citizen_id());
CREATE POLICY citizen_see_own_fines ON "Штраф" FOR SELECT TO "Гражданин" USING ("id_Гражданина" = get_citizen_id());
CREATE POLICY citizen_see_own_payments ON "Платеж" FOR SELECT TO "Гражданин" USING (
    EXISTS (SELECT 1 FROM "Штраф" s WHERE s."id_Штрафа" = "Платеж"."id_Штрафа" AND s."id_Гражданина" = get_citizen_id())
);
CREATE POLICY citizen_insert_payments ON "Платеж" FOR INSERT TO "Гражданин" WITH CHECK (
    EXISTS (SELECT 1 FROM "Штраф" s WHERE s."id_Штрафа" = "id_Штрафа" AND s."id_Гражданина" = get_citizen_id())
);

-- Политики Инспектора
CREATE POLICY inspector_all_citizens  ON "Гражданин"  FOR SELECT TO "Инспектор" USING (true);
CREATE POLICY inspector_all_cars      ON "Автомобиль" FOR SELECT TO "Инспектор" USING (true);
CREATE POLICY inspector_all_fines     ON "Штраф"      FOR SELECT TO "Инспектор" USING (true);
CREATE POLICY inspector_all_payments  ON "Платеж"     FOR SELECT TO "Инспектор" USING (true);
CREATE POLICY inspector_all_inspectors ON "Инспектор"  FOR SELECT TO "Инспектор" USING (true);

-- Политики Администратора
CREATE POLICY admin_all ON "Гражданин"  TO "Администратор" USING (true) WITH CHECK (true);
CREATE POLICY admin_all ON "Автомобиль" TO "Администратор" USING (true) WITH CHECK (true);
CREATE POLICY admin_all ON "Штраф"      TO "Администратор" USING (true) WITH CHECK (true);
CREATE POLICY admin_all ON "Платеж"     TO "Администратор" USING (true) WITH CHECK (true);
CREATE POLICY admin_all ON "Инспектор"  TO "Администратор" USING (true) WITH CHECK (true);


-- ==========================================
-- 4. СОЗДАНИЕ ТРИГГЕРОВ
-- ==========================================

CREATE OR REPLACE FUNCTION check_payment_amount()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW."Сумма" <> (SELECT "Сумма" FROM "Штраф" WHERE "id_Штрафа" = NEW."id_Штрафа") THEN
        RAISE EXCEPTION 'Сумма платежа должна равняться сумме штрафа';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_payment_amount
    BEFORE INSERT OR UPDATE ON "Платеж"
    FOR EACH ROW EXECUTE FUNCTION check_payment_amount();

CREATE OR REPLACE FUNCTION update_fine_status()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
    UPDATE "Штраф" SET "Статус" = 'ОПЛАЧЕН' WHERE "id_Штрафа" = NEW."id_Штрафа";
    RETURN NEW;
END;
$$;

-- Назначаем владельца, чтобы обходить RLS при обновлении статуса
ALTER FUNCTION update_fine_status() OWNER TO "AdminUser";

CREATE TRIGGER trg_update_status
    AFTER INSERT ON "Платеж"
    FOR EACH ROW EXECUTE FUNCTION update_fine_status();


-- ==========================================
-- 5. СКРИПТ ФУНКЦИЙ ДЛЯ РАБОТЫ С ПРОГРАММОЙ
-- ==========================================

CREATE OR REPLACE FUNCTION make_payment(
    p_fine_id int,
    p_sum numeric(10,2),
    p_method text
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_citizen int;
BEGIN
    v_citizen := get_citizen_id();
    PERFORM 1 FROM "Штраф" WHERE "id_Штрафа" = p_fine_id AND "id_Гражданина" = v_citizen;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Нельзя оплатить чужой штраф';
    END IF;
    INSERT INTO "Платеж"("Дата_и_время", "Сумма", "id_Штрафа", "Способ_платежа")
    VALUES (CURRENT_TIMESTAMP(0), p_sum, p_fine_id, p_method);
END;
$$;

CREATE OR REPLACE FUNCTION create_fine_by_owner(
    p_fio text,
    p_plate text,
    p_sum numeric(10,2),
    p_reason text,
    p_place text,
    p_dt timestamp default CURRENT_TIMESTAMP
) RETURNS int LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_inspector int;
    v_new_id int;
    v_citizen int;
    v_car int;
BEGIN
    v_inspector := get_inspector_id();
    SELECT c."id_Гражданина", a."id_Автомобиля"
    INTO v_citizen, v_car
    FROM "Гражданин" c
    JOIN "Автомобиль" a ON a."id_Гражданина" = c."id_Гражданина"
    WHERE c."ФИО" ILIKE p_fio AND a."Госномер" ILIKE p_plate
    LIMIT 1;

    IF v_citizen IS NULL OR v_car IS NULL THEN
        RAISE EXCEPTION 'Не найден гражданин/автомобиль по заданным данным';
    END IF;

    INSERT INTO "Штраф"(
        "id_Гражданина", "id_Автомобиля", "Сумма", "Дата_и_время", 
        "Статус", "Место_нарушения", "Причина_штрафа", "id_Инспектора"
    ) VALUES (
        v_citizen, v_car, p_sum, p_dt, 'НЕ ОПЛАЧЕН', p_place, p_reason, v_inspector
    )
    RETURNING "id_Штрафа" INTO v_new_id;
    RETURN v_new_id;
END;
$$;

CREATE OR REPLACE FUNCTION citizen_fines(p_status text default null, p_search text default null)
RETURNS TABLE (id_штрафа int, статус text, сумма numeric, дата_и_время timestamp, место_нарушения text, причина_штрафа text, госномер text, марка text, модель text )
LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT
        f."id_Штрафа", f."Статус", f."Сумма", f."Дата_и_время",
        f."Место_нарушения", f."Причина_штрафа", a."Госномер", a."Марка", a."Модель"
    FROM "Штраф" f
    JOIN "Автомобиль" a ON a."id_Автомобиля" = f."id_Автомобиля"
    WHERE f."id_Гражданина" = get_citizen_id()
        AND (p_status IS NULL OR f."Статус" = p_status)
        AND (p_search IS NULL OR p_search = '' OR f."Место_нарушения" ILIKE '%' || p_search || '%' OR f."Причина_штрафа" ILIKE '%' || p_search || '%')
    ORDER BY f."Дата_и_время" DESC;
$$;

CREATE OR REPLACE FUNCTION citizen_payments()
RETURNS TABLE (id_платежа int, дата_и_время timestamp, сумма numeric, способ_платежа text, id_штрафа int)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT p."id_Платежа", p."Дата_и_время", p."Сумма", p."Способ_платежа", p."id_Штрафа"
    FROM "Платеж" p
    JOIN "Штраф" f ON f."id_Штрафа" = p."id_Штрафа"
    WHERE f."id_Гражданина" = get_citizen_id()
    ORDER BY p."Дата_и_время" DESC;
$$;

CREATE OR REPLACE FUNCTION citizen_cars()
RETURNS TABLE (id_автомобиля int, госномер text, марка text, модель text)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT a."id_Автомобиля", a."Госномер", a."Марка", a."Модель"
    FROM "Автомобиль" a
    WHERE a."id_Гражданина" = get_citizen_id()
    ORDER BY a."id_Автомобиля";
$$;

CREATE OR REPLACE FUNCTION citizen_info()
RETURNS TABLE (фио text, адрес_регистрации text, номер_телефона text, номер_ву text)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT "ФИО"::text, "Адрес_регистрации"::text, "Номер_телефона"::text, "Номер_ВУ"::text
    FROM "Гражданин"
    WHERE "id_Гражданина" = get_citizen_id();
$$;

CREATE OR REPLACE FUNCTION inspector_fines(p_status text default null, p_fio text default null, p_plate text default null, p_search text default null)
RETURNS TABLE (id_штрафа int, статус text, сумма numeric, дата_и_время timestamp, место_нарушения text, причина_штрафа text, госномер text, марка text, модель text, гражданин_фио text, инспектор_фио text)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT
        f."id_Штрафа", f."Статус", f."Сумма", f."Дата_и_время", f."Место_нарушения", f."Причина_штрафа",
        a."Госномер", a."Марка", a."Модель", c."ФИО", i."ФИО"
    FROM "Штраф" f
    JOIN "Автомобиль" a ON a."id_Автомобиля" = f."id_Автомобиля"
    JOIN "Гражданин" c ON c."id_Гражданина" = f."id_Гражданина"
    JOIN "Инспектор" i ON i."id_Инспектора" = f."id_Инспектора"
    WHERE (p_status IS NULL OR f."Статус" = p_status)
        AND (p_search IS NULL OR p_search = '' OR f."Место_нарушения" ILIKE '%' || p_search || '%' OR f."Причина_штрафа" ILIKE '%' || p_search || '%' OR c."ФИО" ILIKE '%' || p_search || '%' OR a."Госномер" ILIKE '%' || p_search || '%')
        AND (p_fio IS NULL OR p_fio = '' OR c."ФИО" ILIKE '%' || p_fio || '%')
        AND (p_plate IS NULL OR p_plate = '' OR a."Госномер" ILIKE '%' || p_plate || '%')
    ORDER BY f."Дата_и_время" DESC;
$$;
