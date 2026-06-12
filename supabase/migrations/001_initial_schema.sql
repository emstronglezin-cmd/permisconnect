-- ============================================================
-- PERMISCONNECT - Migration 001 : Schéma Complet Production
-- Supabase PostgreSQL
-- ============================================================

-- Extension UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- TABLE: profiles (liée à auth.users)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name   TEXT NOT NULL DEFAULT '',
    phone       TEXT,
    role        TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('student','admin','instructor','super_admin')),
    avatar_url  TEXT,
    is_active   BOOLEAN DEFAULT TRUE,
    school_id   UUID,
    metadata    JSONB DEFAULT '{}',
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_profiles_user_id  ON public.profiles(user_id);
CREATE INDEX idx_profiles_role     ON public.profiles(role);

-- ============================================================
-- TABLE: admin_invitations (codes d'invitation admin)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.admin_invitations (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code        TEXT UNIQUE NOT NULL,
    email       TEXT,
    used        BOOLEAN DEFAULT FALSE,
    used_by     UUID REFERENCES auth.users(id),
    used_at     TIMESTAMPTZ,
    expires_at  TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
    created_by  UUID REFERENCES auth.users(id),
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Insérer un code d'invitation par défaut (à changer en production)
INSERT INTO public.admin_invitations (code, email) VALUES
    ('ADMIN2024SECRET', NULL),
    ('PERMISADMIN', NULL);

-- ============================================================
-- TABLE: students
-- ============================================================
CREATE TABLE IF NOT EXISTS public.students (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id          UUID UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    student_number      TEXT UNIQUE,
    formula             TEXT DEFAULT 'Standard',
    enrollment_date     DATE DEFAULT CURRENT_DATE,
    hours_completed     DECIMAL(5,2) DEFAULT 0,
    hours_required      INTEGER DEFAULT 30,
    total_amount        DECIMAL(10,2) DEFAULT 120000,
    total_paid          DECIMAL(10,2) DEFAULT 0,
    status              TEXT DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','SUSPENDED','COMPLETED','DROPPED')),
    exam_date           DATE,
    notes               TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_students_profile   ON public.students(profile_id);
CREATE INDEX idx_students_status    ON public.students(status);

-- ============================================================
-- TABLE: instructors
-- ============================================================
CREATE TABLE IF NOT EXISTS public.instructors (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id      UUID UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    license_number  TEXT NOT NULL DEFAULT '',
    vehicle_types   JSONB DEFAULT '["B"]',
    total_lessons   INTEGER DEFAULT 0,
    rating          DECIMAL(3,2) DEFAULT 5.0,
    status          TEXT DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE','ON_LEAVE')),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- TABLE: vehicles
-- ============================================================
CREATE TABLE IF NOT EXISTS public.vehicles (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plate                   TEXT UNIQUE NOT NULL,
    brand                   TEXT NOT NULL,
    model                   TEXT NOT NULL,
    year                    INTEGER,
    color                   TEXT,
    vehicle_type            TEXT DEFAULT 'B',
    status                  TEXT DEFAULT 'AVAILABLE' CHECK (status IN ('AVAILABLE','IN_USE','MAINTENANCE','RETIRED')),
    mileage                 INTEGER DEFAULT 0,
    last_maintenance_date   DATE,
    insurance_expiry        DATE,
    image_url               TEXT,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- TABLE: driving_lessons
-- ============================================================
CREATE TABLE IF NOT EXISTS public.driving_lessons (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id          UUID REFERENCES public.students(id) ON DELETE CASCADE,
    instructor_id       UUID REFERENCES public.instructors(id),
    vehicle_id          UUID REFERENCES public.vehicles(id),
    scheduled_date      DATE NOT NULL,
    start_time          TIME NOT NULL,
    end_time            TIME NOT NULL,
    lesson_type         TEXT DEFAULT 'DRIVING' CHECK (lesson_type IN ('DRIVING','CODE','EXAM','MOCK_EXAM')),
    status              TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING','CONFIRMED','COMPLETED','CANCELLED','NO_SHOW')),
    location            TEXT,
    notes               TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_lessons_student    ON public.driving_lessons(student_id);
CREATE INDEX idx_lessons_instructor ON public.driving_lessons(instructor_id);
CREATE INDEX idx_lessons_date       ON public.driving_lessons(scheduled_date);
CREATE INDEX idx_lessons_status     ON public.driving_lessons(status);

-- Contrainte anti-doublon moniteur
CREATE UNIQUE INDEX idx_no_instructor_overlap
    ON public.driving_lessons(instructor_id, scheduled_date, start_time)
    WHERE status NOT IN ('CANCELLED','NO_SHOW');

-- Contrainte anti-doublon véhicule
CREATE UNIQUE INDEX idx_no_vehicle_overlap
    ON public.driving_lessons(vehicle_id, scheduled_date, start_time)
    WHERE status NOT IN ('CANCELLED','NO_SHOW') AND vehicle_id IS NOT NULL;

-- ============================================================
-- TABLE: payments
-- ============================================================
CREATE TABLE IF NOT EXISTS public.payments (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id          UUID REFERENCES public.students(id) ON DELETE CASCADE,
    amount              DECIMAL(10,2) NOT NULL,
    payment_method      TEXT DEFAULT 'CASH' CHECK (payment_method IN ('CASH','ORANGE_MONEY','MOOV_MONEY','CARD','LEEKPAY')),
    status              TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING','VALIDATED','FAILED','REFUNDED')),
    transaction_id      TEXT,
    leekpay_payment_id  TEXT,
    reference           TEXT UNIQUE DEFAULT ('REF-' || UPPER(SUBSTR(MD5(RANDOM()::TEXT), 1, 8))),
    notes               TEXT,
    payment_date        TIMESTAMPTZ DEFAULT NOW(),
    validated_at        TIMESTAMPTZ,
    validated_by        UUID REFERENCES public.profiles(id),
    receipt_url         TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_payments_student ON public.payments(student_id);
CREATE INDEX idx_payments_status  ON public.payments(status);

-- ============================================================
-- TABLE: notifications
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title       TEXT NOT NULL,
    body        TEXT,
    type        TEXT,
    data        JSONB DEFAULT '{}',
    is_read     BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user    ON public.notifications(user_id);
CREATE INDEX idx_notifications_unread  ON public.notifications(user_id, is_read) WHERE is_read = FALSE;

-- ============================================================
-- TABLE: quiz_categories
-- ============================================================
CREATE TABLE IF NOT EXISTS public.quiz_categories (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name            TEXT NOT NULL,
    description     TEXT,
    color           TEXT DEFAULT '#1E65C5',
    order_index     INTEGER DEFAULT 0,
    question_count  INTEGER DEFAULT 0,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- TABLE: quiz_questions
-- ============================================================
CREATE TABLE IF NOT EXISTS public.quiz_questions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id     UUID REFERENCES public.quiz_categories(id),
    question_text   TEXT NOT NULL,
    image_url       TEXT,
    explanation     TEXT,
    difficulty      TEXT DEFAULT 'MEDIUM' CHECK (difficulty IN ('EASY','MEDIUM','HARD')),
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_questions_category ON public.quiz_questions(category_id);

-- ============================================================
-- TABLE: quiz_answers
-- ============================================================
CREATE TABLE IF NOT EXISTS public.quiz_answers (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id     UUID REFERENCES public.quiz_questions(id) ON DELETE CASCADE,
    answer_text     TEXT NOT NULL,
    is_correct      BOOLEAN NOT NULL DEFAULT FALSE,
    order_index     INTEGER DEFAULT 0
);

CREATE INDEX idx_answers_question ON public.quiz_answers(question_id);

-- ============================================================
-- TABLE: quiz_attempts
-- ============================================================
CREATE TABLE IF NOT EXISTS public.quiz_attempts (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id          UUID REFERENCES public.students(id) ON DELETE CASCADE,
    category_id         UUID REFERENCES public.quiz_categories(id),
    attempt_type        TEXT DEFAULT 'PRACTICE' CHECK (attempt_type IN ('PRACTICE','EXAM','MOCK_EXAM')),
    total_questions     INTEGER NOT NULL,
    correct_answers     INTEGER DEFAULT 0,
    score_percentage    DECIMAL(5,2) DEFAULT 0,
    is_passed           BOOLEAN DEFAULT FALSE,
    answers_detail      JSONB DEFAULT '[]',
    started_at          TIMESTAMPTZ DEFAULT NOW(),
    completed_at        TIMESTAMPTZ
);

CREATE INDEX idx_attempts_student ON public.quiz_attempts(student_id);

-- ============================================================
-- TABLE: driving_skills
-- ============================================================
CREATE TABLE IF NOT EXISTS public.driving_skills (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        TEXT NOT NULL,
    category    TEXT NOT NULL,
    description TEXT,
    order_index INTEGER DEFAULT 0,
    is_required BOOLEAN DEFAULT TRUE
);

-- ============================================================
-- TABLE: student_skills
-- ============================================================
CREATE TABLE IF NOT EXISTS public.student_skills (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id      UUID REFERENCES public.students(id) ON DELETE CASCADE,
    skill_id        UUID REFERENCES public.driving_skills(id),
    level           INTEGER DEFAULT 0 CHECK (level BETWEEN 0 AND 3),
    status          TEXT DEFAULT 'NOT_STARTED' CHECK (status IN ('NOT_STARTED','IN_PROGRESS','VALIDATED')),
    comment         TEXT,
    validated_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, skill_id)
);

-- ============================================================
-- TRIGGERS
-- ============================================================

-- updated_at automatique
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_students_updated_at
    BEFORE UPDATE ON public.students
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_lessons_updated_at
    BEFORE UPDATE ON public.driving_lessons
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Trigger: créer le profil automatiquement après inscription
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_full_name TEXT;
    v_phone TEXT;
    v_role TEXT := 'student';
    v_invite_code TEXT;
BEGIN
    -- Extraire les métadonnées
    v_full_name  := COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email, '');
    v_phone      := COALESCE(NEW.raw_user_meta_data->>'phone', NEW.phone, NULL);
    v_invite_code := NEW.raw_user_meta_data->>'invite_code';

    -- Vérifier le code d'invitation admin
    IF v_invite_code IS NOT NULL THEN
        IF EXISTS (
            SELECT 1 FROM public.admin_invitations
            WHERE code = v_invite_code
              AND used = FALSE
              AND expires_at > NOW()
        ) THEN
            v_role := 'admin';
            UPDATE public.admin_invitations
            SET used = TRUE, used_by = NEW.id, used_at = NOW()
            WHERE code = v_invite_code;
        END IF;
    END IF;

    -- Créer le profil
    INSERT INTO public.profiles (user_id, full_name, phone, role)
    VALUES (NEW.id, v_full_name, v_phone, v_role)
    ON CONFLICT (user_id) DO NOTHING;

    -- Si étudiant, créer l'entrée student
    IF v_role = 'student' THEN
        INSERT INTO public.students (profile_id, student_number)
        VALUES (
            (SELECT id FROM public.profiles WHERE user_id = NEW.id),
            'STU-' || UPPER(SUBSTR(MD5(NEW.id::TEXT), 1, 6))
        )
        ON CONFLICT DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Trigger: mettre à jour total_paid dans students après paiement
CREATE OR REPLACE FUNCTION public.update_student_total_paid()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public.students
    SET total_paid = (
        SELECT COALESCE(SUM(amount), 0)
        FROM public.payments
        WHERE student_id = NEW.student_id
          AND status = 'VALIDATED'
    )
    WHERE id = NEW.student_id;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_update_payment_total
    AFTER INSERT OR UPDATE ON public.payments
    FOR EACH ROW EXECUTE FUNCTION public.update_student_total_paid();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE public.profiles           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.instructors        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driving_lessons    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_categories    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_questions     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_answers       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_attempts      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_skills     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driving_skills     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_invitations  ENABLE ROW LEVEL SECURITY;

-- Helper: vérifier si l'utilisateur est admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE user_id = auth.uid()
          AND role IN ('admin','super_admin')
    );
$$;

-- Helper: récupérer le profil courant
CREATE OR REPLACE FUNCTION public.my_profile_id()
RETURNS UUID LANGUAGE sql SECURITY DEFINER AS $$
    SELECT id FROM public.profiles WHERE user_id = auth.uid() LIMIT 1;
$$;

-- Helper: récupérer le student_id courant
CREATE OR REPLACE FUNCTION public.my_student_id()
RETURNS UUID LANGUAGE sql SECURITY DEFINER AS $$
    SELECT s.id FROM public.students s
    JOIN public.profiles p ON p.id = s.profile_id
    WHERE p.user_id = auth.uid()
    LIMIT 1;
$$;

-- ---- PROFILES ----
CREATE POLICY "Users can read own profile"
    ON public.profiles FOR SELECT
    USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid() AND role = (SELECT role FROM public.profiles WHERE user_id = auth.uid()));

CREATE POLICY "Admins can read all profiles"
    ON public.profiles FOR SELECT
    USING (public.is_admin());

CREATE POLICY "Service role can insert profiles"
    ON public.profiles FOR INSERT
    WITH CHECK (TRUE);

-- ---- STUDENTS ----
CREATE POLICY "Student sees own record"
    ON public.students FOR SELECT
    USING (profile_id = public.my_profile_id() OR public.is_admin());

CREATE POLICY "Admin manages students"
    ON public.students FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ---- INSTRUCTORS ----
CREATE POLICY "Instructors visible to auth users"
    ON public.instructors FOR SELECT
    USING (auth.uid() IS NOT NULL);

CREATE POLICY "Admin manages instructors"
    ON public.instructors FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ---- VEHICLES ----
CREATE POLICY "Vehicles visible to auth users"
    ON public.vehicles FOR SELECT
    USING (auth.uid() IS NOT NULL);

CREATE POLICY "Admin manages vehicles"
    ON public.vehicles FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ---- LESSONS ----
CREATE POLICY "Student sees own lessons"
    ON public.driving_lessons FOR SELECT
    USING (student_id = public.my_student_id() OR public.is_admin());

CREATE POLICY "Admin manages lessons"
    ON public.driving_lessons FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ---- PAYMENTS ----
CREATE POLICY "Student sees own payments"
    ON public.payments FOR SELECT
    USING (student_id = public.my_student_id() OR public.is_admin());

CREATE POLICY "Admin manages payments"
    ON public.payments FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ---- NOTIFICATIONS ----
CREATE POLICY "User sees own notifications"
    ON public.notifications FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "User updates own notifications"
    ON public.notifications FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Service role inserts notifications"
    ON public.notifications FOR INSERT
    WITH CHECK (TRUE);

-- ---- QUIZ (lecture publique pour users connectés) ----
CREATE POLICY "Auth users read quiz categories"
    ON public.quiz_categories FOR SELECT
    USING (auth.uid() IS NOT NULL AND is_active = TRUE);

CREATE POLICY "Auth users read quiz questions"
    ON public.quiz_questions FOR SELECT
    USING (auth.uid() IS NOT NULL AND is_active = TRUE);

CREATE POLICY "Auth users read quiz answers"
    ON public.quiz_answers FOR SELECT
    USING (auth.uid() IS NOT NULL);

CREATE POLICY "Students insert own attempts"
    ON public.quiz_attempts FOR INSERT
    WITH CHECK (student_id = public.my_student_id());

CREATE POLICY "Students read own attempts"
    ON public.quiz_attempts FOR SELECT
    USING (student_id = public.my_student_id() OR public.is_admin());

-- ---- SKILLS ----
CREATE POLICY "Auth users read skills"
    ON public.driving_skills FOR SELECT
    USING (auth.uid() IS NOT NULL);

CREATE POLICY "Student sees own skills"
    ON public.student_skills FOR SELECT
    USING (student_id = public.my_student_id() OR public.is_admin());

CREATE POLICY "Admin manages student skills"
    ON public.student_skills FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ---- ADMIN INVITATIONS ----
CREATE POLICY "Only admins read invitations"
    ON public.admin_invitations FOR SELECT
    USING (public.is_admin());

CREATE POLICY "Only admins create invitations"
    ON public.admin_invitations FOR INSERT
    WITH CHECK (public.is_admin());

-- ============================================================
-- DONNÉES DE BASE (Seeds)
-- ============================================================

-- Catégories de quiz
INSERT INTO public.quiz_categories (name, description, color, order_index, question_count) VALUES
    ('Panneaux de Signalisation', 'Lecture des panneaux routiers', '#E74C3C', 1, 20),
    ('Priorités et Intersections', 'Règles de priorité', '#F39C12', 2, 15),
    ('Vitesse et Distances', 'Limitations de vitesse', '#3498DB', 3, 15),
    ('Dépassement et Stationnement', 'Règles de dépassement', '#9B59B6', 4, 12),
    ('Sécurité Routière', 'Alcool, fatigue, équipements', '#27AE60', 5, 18),
    ('Feux de Signalisation', 'Signification des feux', '#1E65C5', 6, 10)
ON CONFLICT DO NOTHING;

-- Compétences de conduite
INSERT INTO public.driving_skills (name, category, order_index) VALUES
    ('Démarrage moteur', 'vehicle', 1),
    ('Arrêt d''urgence', 'vehicle', 2),
    ('Stationnement créneau', 'vehicle', 3),
    ('Demi-tour', 'vehicle', 4),
    ('Conduite nuit', 'vehicle', 5),
    ('Priorité à droite', 'circulation', 1),
    ('Feux tricolores', 'circulation', 2),
    ('Dépassement sécurisé', 'circulation', 3),
    ('Angles morts', 'safety', 1),
    ('Distances de sécurité', 'safety', 2),
    ('Rond-point', 'urban', 1),
    ('Piétons traversant', 'urban', 2)
ON CONFLICT DO NOTHING;

-- Véhicules de démo
INSERT INTO public.vehicles (plate, brand, model, year, color, status) VALUES
    ('AB 1234 BF', 'Toyota', 'Corolla', 2020, 'Blanc', 'AVAILABLE'),
    ('CD 5678 BF', 'Peugeot', '308', 2021, 'Gris', 'AVAILABLE'),
    ('EF 9012 BF', 'Renault', 'Clio', 2019, 'Rouge', 'MAINTENANCE'),
    ('GH 3456 BF', 'Toyota', 'Yaris', 2022, 'Bleu', 'AVAILABLE')
ON CONFLICT DO NOTHING;

