-- ============================================================================
-- PART 1: RE-RUNNABLE HEADER & SCHEMA INITIALIZATION
-- ============================================================================

DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;

SET search_path TO public;

DROP ROLE IF EXISTS dschool_readonly;
DROP ROLE IF EXISTS dschool_writer;

CREATE ROLE dschool_readonly;
CREATE ROLE dschool_writer;


-- ============================================================================
-- PART 2: CREATE TABLES
-- ============================================================================

-- 1. Courses (e.g., Category B, Category C, Extreme Driving Masterclass)
create table if not exists courses (
     course_id serial primary key,
     course_name varchar(100) not null unique,
     slug varchar(100) not null unique,
     price numeric(10,2) not null constraint chk_course_price check (price > 0),
     duration_weeks integer not null constraint chk_course_duration check (duration_weeks > 0)
);

-- 2. Students (Trainees enrolled in the driving school)
create table if not exists students (
     student_id serial primary key,
     email varchar(150) not null constraint uq_student_email unique,
     phone varchar(30) not null,
     full_name varchar(100) not null,
     gender varchar(10) constraint chk_student_gender check (gender in ('M', 'F', 'Other')),
     birth_date date not null
);

-- 3. Instructors (Certified driving masters)
create table if not exists instructors (
     instructor_id serial primary key,
     email varchar(150) not null constraint uq_instructor_email unique,
     phone varchar(30) not null,
     full_name varchar(100) not null,
     license_number varchar(50) not null unique,
     experience_years integer not null constraint chk_instructor_exp check (experience_years >= 0)
);

-- 4. Training Vehicles (The automotive fleet used for practice)
create table if not exists vehicles (
     vehicle_id serial primary key,
     brand varchar(50) not null,
     model varchar(50) not null,
     license_plate varchar(20) not null unique, -- Standardized plate format
     transmission varchar(20) not null constraint chk_vehicle_trans check (transmission in ('Manual', 'Automatic')),
     status varchar(20) not null default 'active' constraint chk_vehicle_status check (status in ('active', 'repair', 'retired'))
);

-- 5. Coupons (Promotional codes and tuition discount adjustments)
create table if not exists coupons (
     coupon_id serial primary key,
     code varchar(20) not null unique,
     discount_percent numeric(5,2) not null,
     status varchar(20) not null default 'active'
);

-- 6. Enrollments (Official training contracts binding a student to a course)
create table if not exists enrollments (
     enrollment_id serial primary key,
     student_id integer not null references students(student_id) on delete restrict,
     course_id integer not null references courses(course_id) on delete restrict,
     coupon_id integer references coupons(coupon_id) on delete set null,
     doc_number varchar(50) not null unique,
     created_at timestamp not null constraint chk_enrollment_date check (created_at > timestamp '2026-01-01 00:00:00')
);

-- 7. Tuition Payments (Financial transactions linked directly to enrollments)
create table if not exists payments (
     payment_id serial primary key,
     enrollment_id integer not null unique references enrollments(enrollment_id) on delete cascade, 
     payment_method varchar(50) not null constraint chk_payment_method check (payment_method in ('Card', 'Cash', 'QR', 'PayPal')),
     amount numeric(10,2) not null constraint chk_payment_amount check (amount > 0),
     status varchar(30) not null default 'pending',
     paid_at timestamp
);

-- 8. Practical Driving Lessons (Bridge entity coordinating student schedules, vehicles, and instructors)
create table if not exists lessons (
     lesson_id serial primary key,
     enrollment_id integer not null references enrollments(enrollment_id) on delete cascade,
     instructor_id integer not null references instructors(instructor_id) on delete restrict,
     vehicle_id integer not null references vehicles(vehicle_id) on delete restrict,
     lesson_date timestamp not null,
     duration_minutes integer not null constraint chk_lesson_duration check (duration_minutes in (45, 60, 90, 120)),
     price_per_hour numeric(10,2) not null,
     total_price numeric(10,2) generated always as ((duration_minutes::numeric / 60.0) * price_per_hour) stored
);

-- 9. Exams (Internal evaluations and state-level qualification scoring)
create table if not exists exams (
     exam_id serial primary key,
     enrollment_id integer not null references enrollments(enrollment_id) on delete cascade,
     exam_type varchar(20) not null constraint chk_exam_type check (exam_type in ('Theory', 'Practice')),
     score integer not null constraint chk_exam_score check (score between 0 and 100),
     is_passed boolean generated always as (score >= 40) stored, -- Standardized 40% passing threshold evaluation
     exam_date date not null
);

-- 10. Instructor Reviews (Performance feedback submitted by trainees)
create table if not exists instructor_reviews (
     review_id serial primary key,
     student_id integer not null references students(student_id) on delete cascade,
     instructor_id integer not null references instructors(instructor_id) on delete cascade,
     rating integer not null constraint chk_review_rating check (rating between 1 and 5),
     comment_text text
);


-- ============================================================================
-- PART 3: ALTER TABLES (Schema adjustments and migration validations)
-- ============================================================================

-- 1. ALTER COLUMN DEFAULT
alter table coupons alter column status set default 'pending';

-- 2. ADD COLUMN
alter table vehicles add column if not exists seasonal_promo varchar(50);

-- 3. DROP COLUMN
alter table vehicles drop column if exists seasonal_promo;

-- 4. ALTER COLUMN TYPE
alter table enrollments alter column doc_number type varchar(100);

-- 5. ADD CONSTRAINT
alter table coupons drop constraint if exists chk_max_discount;
alter table coupons add constraint chk_max_discount check (discount_percent <= 90.00);


-- ============================================================================
-- PART 4: CLEANUP & TRUNCATE (Ensures deterministic, idempotent data seeding)
-- ============================================================================

truncate table 
     courses, 
     students, 
     instructors, 
     vehicles, 
     coupons, 
     enrollments, 
     payments, 
     lessons, 
     exams, 
     instructor_reviews
restart identity cascade;


-- ============================================================================
-- PART 5: INSERT DATA (Seeding authentic production-grade records)
-- ============================================================================

insert into courses (course_name, slug, price, duration_weeks) values
('Category B (Automatic)', 'cat-b-auto', 120000.00, 10),
('Category B (Manual)', 'cat-b-manual', 110000.00, 10),
('Category A (Motorcycle)', 'cat-a', 85000.00, 6),
('Category C (Trucks)', 'cat-c', 180000.00, 12),
('Extreme Driving Masterclass', 'extreme-driving', 95000.00, 2)
on conflict (slug) do nothing;

insert into students (email, phone, full_name, gender, birth_date) values
('alikhan.asanov@example.kz', '+77011112233', 'Alikhan Asanov', 'M', '2005-04-12'),
('aruzhan.serikova@example.kz', '+77022223344', 'Aruzhan Serikova', 'F', '2006-09-18'),
('dmitriy.kim@example.kz', '+77033334455', 'Dmitriy Kim', 'M', '1998-02-25'),
('dinara.sultanova@example.kz', '+77044445566', 'Dinara Sultanova', 'F', '2001-11-05'),
('berik.akhmetov@example.kz', '+77055556677', 'Berik Akhmetov', 'Other', '1993-07-30')
on conflict (email) do nothing;

insert into instructors (email, phone, full_name, license_number, experience_years) values
('maxim.romanov@dschool.kz', '+77071234567', 'Maxim Romanov', 'AB-123456', 12),
('sapar.akhmetov@dschool.kz', '+77077654321', 'Sapar Akhmetov', 'CD-789012', 8),
('elena.kuznetsova@dschool.kz', '+77079998877', 'Elena Kuznetsova', 'EF-345678', 5)
on conflict (email) do nothing;

insert into vehicles (brand, model, license_plate, transmission, status) values
('Toyota', 'Camry', '249 ADL 06', 'Automatic', 'active'),
('Volkswagen', 'Polo', '112 VIP 06', 'Manual', 'active'),
('Hyundai', 'Accent', '785 AAA 06', 'Automatic', 'active'),
('KamAZ', '43118', '005 ССА 06', 'Manual', 'active'),
('BMW', 'X5', '999 XA 06', 'Automatic', 'repair')
on conflict (license_plate) do nothing;

insert into coupons (code, discount_percent, status) values
('WINTER2026', 10.00, 'active'), 
('SPRING26', 15.00, 'active'), 
('WELCOMEST', 5.00, 'active'), 
('EXPIRED26', 20.00, 'expired'), 
('VIPONLY', 25.00, 'active')
on conflict (code) do nothing;

-- Enrollments (Binding contracts generation)
insert into enrollments (student_id, course_id, coupon_id, doc_number, created_at)
select (select student_id from students where email = 'alikhan.asanov@example.kz'), (select course_id from courses where slug = 'cat-b-auto'), (select coupon_id from coupons where code = 'WINTER2026'), 'DS-2026-001', '2026-01-05 11:00:00'
where not exists (select 1 from enrollments where doc_number = 'DS-2026-001');

insert into enrollments (student_id, course_id, coupon_id, doc_number, created_at)
select (select student_id from students where email = 'aruzhan.serikova@example.kz'), (select course_id from courses where slug = 'cat-b-manual'), null, 'DS-2026-002', '2026-02-15 14:30:00'
where not exists (select 1 from enrollments where doc_number = 'DS-2026-002');

insert into enrollments (student_id, course_id, coupon_id, doc_number, created_at)
select (select student_id from students where email = 'dmitriy.kim@example.kz'), (select course_id from courses where slug = 'cat-c'), null, 'DS-2026-003', '2026-03-01 10:15:00'
where not exists (select 1 from enrollments where doc_number = 'DS-2026-003');

insert into enrollments (student_id, course_id, coupon_id, doc_number, created_at)
select (select student_id from students where email = 'dinara.sultanova@example.kz'), (select course_id from courses where slug = 'extreme-driving'), (select coupon_id from coupons where code = 'WELCOMEST'), 'DS-2026-004', '2026-03-10 18:45:00'
where not exists (select 1 from enrollments where doc_number = 'DS-2026-004');

-- Payments ledger entries
insert into payments (enrollment_id, payment_method, amount, status, paid_at)
select (select enrollment_id from enrollments where doc_number = 'DS-2026-001'), 'Card', 108000.00, 'completed', '2026-01-05 11:15:00'
where not exists (select 1 from payments where enrollment_id = (select enrollment_id from enrollments where doc_number = 'DS-2026-001'));

insert into payments (enrollment_id, payment_method, amount, status, paid_at)
select (select enrollment_id from enrollments where doc_number = 'DS-2026-002'), 'QR', 110000.00, 'completed', '2026-02-15 14:35:00'
where not exists (select 1 from payments where enrollment_id = (select enrollment_id from enrollments where doc_number = 'DS-2026-002'));

insert into payments (enrollment_id, payment_method, amount, status, paid_at)
select (select enrollment_id from enrollments where doc_number = 'DS-2026-003'), 'Card', 180000.00, 'pending', null
where not exists (select 1 from payments where enrollment_id = (select enrollment_id from enrollments where doc_number = 'DS-2026-003'));

insert into payments (enrollment_id, payment_method, amount, status, paid_at)
select (select enrollment_id from enrollments where doc_number = 'DS-2026-004'), 'PayPal', 90250.00, 'completed', '2026-03-10 19:00:00'
where not exists (select 1 from payments where enrollment_id = (select enrollment_id from enrollments where doc_number = 'DS-2026-004'));


-- Practical Driving Lessons scheduling logs
insert into lessons (enrollment_id, instructor_id, vehicle_id, lesson_date, duration_minutes, price_per_hour)
select (select enrollment_id from enrollments where doc_number = 'DS-2026-001'), (select instructor_id from instructors where email = 'maxim.romanov@dschool.kz'), (select vehicle_id from vehicles where license_plate = '249 ADL 06'), '2026-01-15 09:00:00', 90, 4000.00
where not exists (select 1 from lessons where enrollment_id = (select enrollment_id from enrollments where doc_number = 'DS-2026-001') and lesson_date = '2026-01-15 09:00:00');

insert into lessons (enrollment_id, instructor_id, vehicle_id, lesson_date, duration_minutes, price_per_hour)
select (select enrollment_id from enrollments where doc_number = 'DS-2026-002'), (select instructor_id from instructors where email = 'sapar.akhmetov@dschool.kz'), (select vehicle_id from vehicles where license_plate = '112 VIP 06'), '2026-02-20 11:00:00', 120, 4500.00
where not exists (select 1 from lessons where enrollment_id = (select enrollment_id from enrollments where doc_number = 'DS-2026-002') and lesson_date = '2026-02-20 11:00:00');

insert into lessons (enrollment_id, instructor_id, vehicle_id, lesson_date, duration_minutes, price_per_hour)
select (select enrollment_id from enrollments where doc_number = 'DS-2026-003'), (select instructor_id from instructors where email = 'sapar.akhmetov@dschool.kz'), (select vehicle_id from vehicles where license_plate = '005 ССА 06'), '2026-03-05 14:00:00', 90, 6000.00
where not exists (select 1 from lessons where enrollment_id = (select enrollment_id from enrollments where doc_number = 'DS-2026-003') and lesson_date = '2026-03-05 14:00:00');


-- Qualification Exams results logging
insert into exams (enrollment_id, exam_type, score, exam_date)
select (select enrollment_id from enrollments where doc_number = 'DS-2026-001'), 'Theory', 45, '2026-02-10'
where not exists (select 1 from exams where enrollment_id = (select enrollment_id from enrollments where doc_number = 'DS-2026-001') and exam_type = 'Theory');

insert into exams (enrollment_id, exam_type, score, exam_date)
select (select enrollment_id from enrollments where doc_number = 'DS-2026-001'), 'Practice', 85, '2026-02-12'
where not exists (select 1 from exams where enrollment_id = (select enrollment_id from enrollments where doc_number = 'DS-2026-001') and exam_type = 'Practice');

insert into exams (enrollment_id, exam_type, score, exam_date)
select (select enrollment_id from enrollments where doc_number = 'DS-2026-002'), 'Theory', 35, '2026-03-15'
where not exists (select 1 from exams where enrollment_id = (select enrollment_id from enrollments where doc_number = 'DS-2026-002') and exam_type = 'Theory');


-- Instructor Performance Reviews submissions
insert into instructor_reviews (student_id, instructor_id, rating, comment_text)
select (select student_id from students where email = 'alikhan.asanov@example.kz'), (select instructor_id from instructors where email = 'maxim.romanov@dschool.kz'), 5, 'Great explanation of parallel parking!'
where not exists (select 1 from instructor_reviews where student_id = (select student_id from students where email = 'alikhan.asanov@example.kz') and instructor_id = (select instructor_id from instructors where email = 'maxim.romanov@dschool.kz'));

insert into instructor_reviews (student_id, instructor_id, rating, comment_text)
select (select student_id from students where email = 'aruzhan.serikova@example.kz'), (select instructor_id from instructors where email = 'sapar.akhmetov@dschool.kz'), 4, 'Patient, but sometimes strict on errors.'
where not exists (select 1 from instructor_reviews where student_id = (select student_id from students where email = 'aruzhan.serikova@example.kz') and instructor_id = (select instructor_id from instructors where email = 'sapar.akhmetov@dschool.kz'));


-- ============================================================================
-- PART 6: UPDATE DATA (Business logic simulations)
-- ============================================================================

-- 1. Apply seasonal promotional 10% discount to all Category B courses
update courses set price = price * 0.90 where slug like 'cat-b%';

-- 2. Append (VIP) marker to students whose completed financial footprint across courses exceeds 100,000 KZT
update students set full_name = full_name || ' (VIP)' where student_id in (
      select e.student_id from enrollments e join payments p on e.enrollment_id = p.enrollment_id where p.status = 'completed' group by e.student_id having sum(p.amount) > 100000.00
) and full_name not like '%(VIP)%';


-- ============================================================================
-- PART 7: ROLES & PERMISSIONS
-- ============================================================================

grant select on all tables in schema public to dschool_readonly;
grant insert, update on vehicles to dschool_writer;
revoke update on vehicles from dschool_writer;


-- ============================================================================
-- PART 8: TRANSACTION TESTS (Architectural Validation & Side-Effect Isolation)
-- ============================================================================

/*
   PROFESSIONAL TRANSACTIONAL DESIGN EXPLANATION:
   --------------------------------------------------------------------------
   1. ARCHITECTURAL ISOLATION: 
      By initializing this testing segment with 'BEGIN;', we construct an isolated,
      private transactional context. All operations executed within this boundary 
      are entirely invisible to concurrent database sessions (Read Committed isolation status).
   
   2. DATA INTEGRITY SAFEGUARDS & ZERO FOOTPRINT:
      This segment safely simulates a critical data destructive operation—the extraction and 
      cascading removal of records targeting students failing academic thresholds (score < 38). 
      The 'RETURNING' clause intercepts the deleted runtime context for programmatic evaluation.
      
   3. IDEMPOTENT ROLLBACK EXECUTION:
      Invoking the 'ROLLBACK;' statement instructs the PostgreSQL engine to completely discard the 
      transaction log journal compiled since the 'BEGIN' token. This reverses all data mutations, 
      returning the database back to its exact initial clean state. This prevents data corruption 
      on persistent staging sets and ensures testing processes remain completely repeatable (idempotent).
*/

begin;

-- Simulate cascading extraction/purging of enrollments tied to critical exam failure states
delete from enrollments 
where enrollment_id in (select enrollment_id from exams where score < 38)
returning enrollment_id, student_id, doc_number;

-- Safely abort all mutations, ensuring the local database dataset remains unmodified and pristine
rollback;