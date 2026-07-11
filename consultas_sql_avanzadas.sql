-- =================================================================
-- Consultas SQL Avanzadas
-- Base de datos: accommodations_tourism
-- Motor: PostgreSQL
-- =================================================================

-- ----------------------------------------------------------------
-- 01. INSERT | Insertar propietario
--     Descripción: Agregar un nuevo propietario
-- ----------------------------------------------------------------
INSERT INTO owners (
    first_name, last_name, company_name, email, phone,
    tax_id, address_line1, city, state, country, postal_code
)
VALUES (
    'Carlos', 'Martínez', 'Martínez Properties S.A.',
    'carlos.martinez@properties.com', '+503-7890-1234',
    'TAX-2024-001', 'Calle Principal 45', 'San Salvador',
    'San Salvador', 'El Salvador', '01101'
);

-- ----------------------------------------------------------------
-- 02. INSERT | Insertar alojamiento
--     Descripción: Ligar alojamiento vinculado al propietario recién insertado
-- ----------------------------------------------------------------
INSERT INTO accommodations (
    owner_id, accommodation_type_id, location_id, name,
    description, max_guests, bedroom_count, bathroom_count,
    base_price_per_night, currency_code, check_in_time, check_out_time, is_active
)
VALUES (
    (SELECT owner_id FROM owners WHERE email = 'carlos.martinez@properties.com'),
    1,   -- Hotel
    1,
    'Hotel Volcán Izalco',
    'Hermoso hotel con vista al volcán Izalco, habitaciones modernas.',
    4, 2, 1,
    150.00, 'USD', '15:00', '11:00', TRUE
);

-- ----------------------------------------------------------------
-- 03. INSERT | Huésped y reserva
--     Descripción: Registrar huésped y reserva en una transacción
-- ----------------------------------------------------------------
INSERT INTO guests (
    first_name, last_name, email, phone,
    date_of_birth, nationality, passport_number
)
VALUES (
    'Ana', 'López', 'ana.lopez@email.com', '+503-7111-2222',
    '1990-05-15', 'Salvadoreña', 'A12345678'
);

INSERT INTO bookings (
    guest_id, accommodation_id, room_id, booking_status_id,
    check_in_date, check_out_date, adult_count, child_count,
    subtotal_amount, tax_amount, discount_amount, total_amount,
    special_requests, booking_reference
)
VALUES (
    (SELECT guest_id FROM guests WHERE email = 'ana.lopez@email.com'),
    1,   -- accommodation_id existente
    NULL,
    1,   -- booking_status_id: ej. "Confirmed"
    '2026-07-01', '2026-07-05',
    2, 0,
    600.00, 78.00, 0.00, 678.00,
    'Habitación con vista al jardín, por favor.',
    'REF-2026-ANA-001'
);

-- ----------------------------------------------------------------
-- 04. INSERT | Insertar pago
--     Descripción: Registrar pago para una reserva existente
-- ----------------------------------------------------------------
INSERT INTO payments (
    booking_id, payment_date, amount,
    payment_method, payment_status, transaction_reference, notes
)
VALUES (
    (SELECT booking_id FROM bookings WHERE booking_reference = 'REF-2026-ANA-001'),
    CURRENT_TIMESTAMP,
    678.00,
    'Credit Card', 'Completed',
    'TXN-CC-20260701-0001',
    'Pago total de la reserva en una cuota.'
);

-- ----------------------------------------------------------------
-- 05. SELECT | Alojamientos activos
--     Descripción: Filtrar activos
-- ----------------------------------------------------------------
SELECT
    accommodation_id,
    name,
    base_price_per_night,
    currency_code,
    max_guests,
    bedroom_count,
    bathroom_count,
    is_active
FROM accommodations
WHERE is_active = TRUE
ORDER BY base_price_per_night ASC;

-- ----------------------------------------------------------------
-- 06. SELECT | Huéspedes por país
--     Descripción: Filtrar por nacionalidad
-- ----------------------------------------------------------------
SELECT
    guest_id,
    first_name,
    last_name,
    email,
    nationality
FROM guests
WHERE nationality = 'American'
ORDER BY last_name, first_name;

-- ----------------------------------------------------------------
-- 07. SELECT | Reservas por fechas
--     Descripción: Uso de BETWEEN para filtrar rango de fechas
-- ----------------------------------------------------------------
SELECT
    booking_id,
    booking_reference,
    guest_id,
    accommodation_id,
    check_in_date,
    check_out_date,
    total_nights,
    total_amount
FROM bookings
WHERE check_in_date BETWEEN '2026-01-01' AND '2026-12-31'
ORDER BY check_in_date ASC;

-- ----------------------------------------------------------------
-- 08. UPDATE | Actualizar precio
--     Descripción: Modificar precio base de un alojamiento
-- ----------------------------------------------------------------
UPDATE accommodations
SET base_price_per_night = 175.00
WHERE accommodation_id = 1;

-- ----------------------------------------------------------------
-- 09. UPDATE | Estado reserva
--     Descripción: Actualizar estado de una reserva existente
-- ----------------------------------------------------------------
UPDATE bookings
SET booking_status_id = (
    SELECT booking_status_id
    FROM booking_statuses
    WHERE status_name = 'Cancelled'
    LIMIT 1
)
WHERE booking_reference = 'REF-2026-ANA-001';

-- ----------------------------------------------------------------
-- 10. DELETE | Eliminar reseña
--     Descripción: DELETE WHERE para borrar una reseña específica
-- ----------------------------------------------------------------
DELETE FROM reviews
WHERE review_id = (
    SELECT review_id
    FROM reviews
    ORDER BY review_date ASC
    LIMIT 1
);

-- ----------------------------------------------------------------
-- 11. JOIN | Reservas + huésped
--     Descripción: INNER JOIN entre bookings y guests
-- ----------------------------------------------------------------
SELECT
    b.booking_id,
    b.booking_reference,
    g.first_name || ' ' || g.last_name AS huesped,
    g.email,
    b.check_in_date,
    b.check_out_date,
    b.total_amount
FROM bookings b
INNER JOIN guests g ON b.guest_id = g.guest_id
ORDER BY b.check_in_date DESC;

-- ----------------------------------------------------------------
-- 12. JOIN | Alojamiento completo
--     Descripción: INNER JOIN múltiple: accommodations + owners + locations
-- ----------------------------------------------------------------
SELECT
    a.accommodation_id,
    a.name                                          AS alojamiento,
    o.first_name || ' ' || o.last_name              AS propietario,
    o.email                                         AS email_propietario,
    l.city,
    l.country,
    at.type_name                                    AS tipo,
    a.base_price_per_night,
    a.is_active
FROM accommodations a
INNER JOIN owners        o  ON a.owner_id              = o.owner_id
INNER JOIN locations     l  ON a.location_id           = l.location_id
INNER JOIN accommodation_types at ON a.accommodation_type_id = at.accommodation_type_id
ORDER BY a.accommodation_id;

-- ----------------------------------------------------------------
-- 13. JOIN | Pagos + reservas
--     Descripción: JOIN combinado entre payments, bookings y guests
-- ----------------------------------------------------------------
SELECT
    p.payment_id,
    p.payment_date,
    p.amount,
    p.payment_method,
    p.payment_status,
    b.booking_reference,
    g.first_name || ' ' || g.last_name AS huesped
FROM payments p
INNER JOIN bookings b ON p.booking_id = b.booking_id
INNER JOIN guests   g ON b.guest_id   = g.guest_id
ORDER BY p.payment_date DESC;

-- ----------------------------------------------------------------
-- 14. LEFT JOIN | Sin reseñas
--     Descripción: Incluye nulls — alojamientos que nunca han recibido reseña
-- ----------------------------------------------------------------
SELECT
    a.accommodation_id,
    a.name,
    r.review_id,
    r.rating,
    r.review_title
FROM accommodations a
LEFT JOIN reviews r ON a.accommodation_id = r.accommodation_id
ORDER BY r.review_id NULLS FIRST;

-- ----------------------------------------------------------------
-- 15. LEFT JOIN | Sin reservas
--     Descripción: Filtrar null — huéspedes que nunca han hecho una reserva
-- ----------------------------------------------------------------
SELECT
    g.guest_id,
    g.first_name,
    g.last_name,
    g.email,
    g.nationality
FROM guests g
LEFT JOIN bookings b ON g.guest_id = b.guest_id
WHERE b.booking_id IS NULL
ORDER BY g.last_name;

-- ----------------------------------------------------------------
-- 16. AGG | Total ingresos
--     Descripción: SUM de todos los pagos completados
-- ----------------------------------------------------------------
SELECT
    SUM(p.amount)                   AS ingresos_totales,
    COUNT(p.payment_id)             AS total_pagos,
    AVG(p.amount)                   AS promedio_por_pago,
    MIN(p.amount)                   AS pago_minimo,
    MAX(p.amount)                   AS pago_maximo
FROM payments p
WHERE p.payment_status = 'Completed';

-- ----------------------------------------------------------------
-- 17. AGG | Promedio rating
--     Descripción: AVG del rating agrupado por alojamiento
-- ----------------------------------------------------------------
SELECT
    a.accommodation_id,
    a.name                      AS alojamiento,
    ROUND(AVG(r.rating), 2)     AS promedio_rating,
    COUNT(r.review_id)          AS total_resenas
FROM accommodations a
INNER JOIN reviews r ON a.accommodation_id = r.accommodation_id
GROUP BY a.accommodation_id, a.name
ORDER BY promedio_rating DESC;

-- ----------------------------------------------------------------
-- 18. AGG | Top alojamientos
--     Descripción: COUNT + LIMIT — los 5 alojamientos con más reservas
-- ----------------------------------------------------------------
SELECT
    a.accommodation_id,
    a.name          AS alojamiento,
    COUNT(b.booking_id) AS total_reservas
FROM accommodations a
INNER JOIN bookings b ON a.accommodation_id = b.accommodation_id
GROUP BY a.accommodation_id, a.name
ORDER BY total_reservas DESC
LIMIT 5;

-- ----------------------------------------------------------------
-- 19. HAVING | Más de 3 reservas
--     Descripción: GROUP BY + HAVING para filtrar grupos
-- ----------------------------------------------------------------
SELECT
    g.guest_id,
    g.first_name || ' ' || g.last_name AS huesped,
    g.nationality,
    COUNT(b.booking_id)                AS total_reservas,
    SUM(b.total_amount)                AS gasto_total
FROM guests g
INNER JOIN bookings b ON g.guest_id = b.guest_id
GROUP BY g.guest_id, g.first_name, g.last_name, g.nationality
HAVING COUNT(b.booking_id) > 3
ORDER BY total_reservas DESC;

-- ----------------------------------------------------------------
-- 20. Subconsulta | Alojamiento más caro
--     Descripción: Subquery para encontrar el alojamiento con mayor precio
-- ----------------------------------------------------------------
SELECT
    accommodation_id,
    name,
    base_price_per_night,
    currency_code
FROM accommodations
WHERE base_price_per_night = (
    SELECT MAX(base_price_per_night)
    FROM accommodations
    WHERE is_active = TRUE
);

-- =================================================================
-- FIN DEL SCRIPT — 20 consultas completadas
-- =================================================================
