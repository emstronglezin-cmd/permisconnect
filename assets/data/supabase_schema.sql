-- =====================================================
-- PERMISCONNECT - SCHÉMA SQL SUPABASE COMPLET
-- Auto-École Digitale pour l'Afrique Francophone
-- =====================================================

-- Extension UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLE: roles
-- =====================================================
CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    permissions JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO roles (name, description) VALUES
    ('super_admin', 'Accès total à la plateforme'),
    ('admin', 'Administrateur d''une auto-école'),
    ('instructor', 'Moniteur de conduite'),
    ('student', 'Élève en formation');

-- =====================================================
-- TABLE: users (étend auth.users de Supabase)
-- =====================================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role_id UUID REFERENCES roles(id),
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    school_id UUID,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role_id);

-- =====================================================
-- TABLE: driving_schools
-- =====================================================
CREATE TABLE IF NOT EXISTS driving_schools (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    address TEXT,
    city VARCHAR(100),
    country VARCHAR(100) DEFAULT 'Burkina Faso',
    phone VARCHAR(20),
    email VARCHAR(255),
    license_number VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TABLE: formulas (Formules d'inscription)
-- =====================================================
CREATE TABLE IF NOT EXISTS formulas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID REFERENCES driving_schools(id),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    hours_included INTEGER NOT NULL,
    features JSONB DEFAULT '[]',
    is_active BOOLEAN DEFAULT TRUE,
    color VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TABLE: students
-- =====================================================
CREATE TABLE IF NOT EXISTS students (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    school_id UUID REFERENCES driving_schools(id),
    formula_id UUID REFERENCES formulas(id),
    student_number VARCHAR(50) UNIQUE,
    enrollment_date DATE DEFAULT CURRENT_DATE,
    expected_exam_date DATE,
    hours_completed DECIMAL(5,2) DEFAULT 0,
    hours_required INTEGER DEFAULT 20,
    total_amount DECIMAL(10,2) DEFAULT 0,
    total_paid DECIMAL(10,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'SUSPENDED', 'COMPLETED', 'DROPPED')),
    notes TEXT,
    emergency_contact JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_students_user ON students(user_id);
CREATE INDEX idx_students_school ON students(school_id);
CREATE INDEX idx_students_status ON students(status);

-- =====================================================
-- TABLE: instructors
-- =====================================================
CREATE TABLE IF NOT EXISTS instructors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    school_id UUID REFERENCES driving_schools(id),
    license_number VARCHAR(100) NOT NULL,
    vehicle_types JSONB DEFAULT '["B"]',
    total_lessons INTEGER DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 5.0,
    availability JSONB DEFAULT '{}',
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'ON_LEAVE')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TABLE: vehicles
-- =====================================================
CREATE TABLE IF NOT EXISTS vehicles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID REFERENCES driving_schools(id),
    plate VARCHAR(30) UNIQUE NOT NULL,
    brand VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year INTEGER,
    color VARCHAR(50),
    vehicle_type VARCHAR(20) DEFAULT 'B',
    status VARCHAR(20) DEFAULT 'AVAILABLE' CHECK (status IN ('AVAILABLE', 'IN_USE', 'MAINTENANCE', 'RETIRED')),
    mileage INTEGER DEFAULT 0,
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    insurance_expiry DATE,
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_vehicles_school ON vehicles(school_id);
CREATE INDEX idx_vehicles_status ON vehicles(status);

-- =====================================================
-- TABLE: driving_lessons
-- =====================================================
CREATE TABLE IF NOT EXISTS driving_lessons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    instructor_id UUID REFERENCES instructors(id),
    vehicle_id UUID REFERENCES vehicles(id),
    school_id UUID REFERENCES driving_schools(id),
    scheduled_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    duration_minutes INTEGER GENERATED ALWAYS AS (
        EXTRACT(EPOCH FROM (end_time - start_time)) / 60
    ) STORED,
    lesson_type VARCHAR(20) DEFAULT 'DRIVING' CHECK (lesson_type IN ('DRIVING', 'CODE', 'EXAM', 'MOCK_EXAM')),
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'NO_SHOW')),
    location TEXT,
    notes TEXT,
    notification_sent BOOLEAN DEFAULT FALSE,
    sms_sent BOOLEAN DEFAULT FALSE,
    cancelled_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_lessons_student ON driving_lessons(student_id);
CREATE INDEX idx_lessons_instructor ON driving_lessons(instructor_id);
CREATE INDEX idx_lessons_vehicle ON driving_lessons(vehicle_id);
CREATE INDEX idx_lessons_date ON driving_lessons(scheduled_date);
CREATE INDEX idx_lessons_status ON driving_lessons(status);

-- Contrainte: pas de double réservation moniteur
CREATE UNIQUE INDEX idx_no_instructor_overlap ON driving_lessons(instructor_id, scheduled_date, start_time)
WHERE status NOT IN ('CANCELLED', 'NO_SHOW');

-- Contrainte: pas de double réservation véhicule
CREATE UNIQUE INDEX idx_no_vehicle_overlap ON driving_lessons(vehicle_id, scheduled_date, start_time)
WHERE status NOT IN ('CANCELLED', 'NO_SHOW') AND vehicle_id IS NOT NULL;

-- =====================================================
-- TABLE: driving_skills
-- =====================================================
CREATE TABLE IF NOT EXISTS driving_skills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    description TEXT,
    order_index INTEGER DEFAULT 0,
    is_required BOOLEAN DEFAULT TRUE,
    max_level INTEGER DEFAULT 3,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO driving_skills (name, category, order_index) VALUES
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
    ('Piétons traversant', 'urban', 2);

-- =====================================================
-- TABLE: student_skills
-- =====================================================
CREATE TABLE IF NOT EXISTS student_skills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    skill_id UUID REFERENCES driving_skills(id),
    lesson_id UUID REFERENCES driving_lessons(id),
    instructor_id UUID REFERENCES instructors(id),
    level INTEGER DEFAULT 0 CHECK (level BETWEEN 0 AND 3),
    status VARCHAR(20) DEFAULT 'NOT_STARTED' CHECK (status IN ('NOT_STARTED', 'IN_PROGRESS', 'VALIDATED')),
    comment TEXT,
    validated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, skill_id)
);

-- =====================================================
-- TABLE: lesson_evaluations
-- =====================================================
CREATE TABLE IF NOT EXISTS lesson_evaluations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id UUID REFERENCES driving_lessons(id) ON DELETE CASCADE,
    student_id UUID REFERENCES students(id),
    instructor_id UUID REFERENCES instructors(id),
    overall_rating INTEGER CHECK (overall_rating BETWEEN 1 AND 5),
    skill_evaluations JSONB DEFAULT '[]',
    general_comment TEXT,
    next_objectives TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TABLE: quiz_categories
-- =====================================================
CREATE TABLE IF NOT EXISTS quiz_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon_url TEXT,
    color VARCHAR(20),
    order_index INTEGER DEFAULT 0,
    question_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TABLE: quiz_questions
-- =====================================================
CREATE TABLE IF NOT EXISTS quiz_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID REFERENCES quiz_categories(id),
    question_text TEXT NOT NULL,
    image_url TEXT,
    explanation TEXT,
    difficulty VARCHAR(10) DEFAULT 'MEDIUM' CHECK (difficulty IN ('EASY', 'MEDIUM', 'HARD')),
    is_active BOOLEAN DEFAULT TRUE,
    source VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_questions_category ON quiz_questions(category_id);
CREATE INDEX idx_questions_difficulty ON quiz_questions(difficulty);

-- =====================================================
-- TABLE: quiz_answers
-- =====================================================
CREATE TABLE IF NOT EXISTS quiz_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID REFERENCES quiz_questions(id) ON DELETE CASCADE,
    answer_text TEXT NOT NULL,
    is_correct BOOLEAN NOT NULL DEFAULT FALSE,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_answers_question ON quiz_answers(question_id);

-- =====================================================
-- TABLE: quiz_attempts
-- =====================================================
CREATE TABLE IF NOT EXISTS quiz_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    category_id UUID REFERENCES quiz_categories(id),
    attempt_type VARCHAR(20) DEFAULT 'PRACTICE' CHECK (attempt_type IN ('PRACTICE', 'EXAM', 'MOCK_EXAM')),
    total_questions INTEGER NOT NULL,
    correct_answers INTEGER DEFAULT 0,
    wrong_answers INTEGER DEFAULT 0,
    time_spent_seconds INTEGER DEFAULT 0,
    score_percentage DECIMAL(5,2) DEFAULT 0,
    is_passed BOOLEAN DEFAULT FALSE,
    pass_threshold INTEGER DEFAULT 70,
    answers_detail JSONB DEFAULT '[]',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE INDEX idx_attempts_student ON quiz_attempts(student_id);
CREATE INDEX idx_attempts_type ON quiz_attempts(attempt_type);

-- =====================================================
-- TABLE: payments
-- =====================================================
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    school_id UUID REFERENCES driving_schools(id),
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(20) DEFAULT 'CASH' CHECK (payment_method IN ('CASH', 'ORANGE_MONEY', 'MOOV_MONEY', 'CARD', 'TRANSFER')),
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'VALIDATED', 'FAILED', 'REFUNDED')),
    transaction_id VARCHAR(100),
    reference VARCHAR(100),
    notes TEXT,
    payment_date TIMESTAMPTZ DEFAULT NOW(),
    validated_at TIMESTAMPTZ,
    validated_by UUID REFERENCES users(id),
    receipt_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_payments_student ON payments(student_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_method ON payments(payment_method);

-- =====================================================
-- TABLE: notifications
-- =====================================================
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    body TEXT,
    type VARCHAR(50),
    data JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT FALSE,
    sent_via JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);

-- =====================================================
-- TABLE: sms_logs
-- =====================================================
CREATE TABLE IF NOT EXISTS sms_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recipient_phone VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    provider VARCHAR(50),
    status VARCHAR(20) DEFAULT 'PENDING',
    external_id VARCHAR(100),
    sent_at TIMESTAMPTZ,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TRIGGERS - Mise à jour auto
-- =====================================================

-- Trigger updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_students_updated_at
    BEFORE UPDATE ON students
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_lessons_updated_at
    BEFORE UPDATE ON driving_lessons
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Trigger: met à jour total_paid dans students après paiement
CREATE OR REPLACE FUNCTION update_student_payment()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE students 
    SET total_paid = (
        SELECT COALESCE(SUM(amount), 0) 
        FROM payments 
        WHERE student_id = NEW.student_id AND status = 'VALIDATED'
    )
    WHERE id = NEW.student_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_payment_change
    AFTER INSERT OR UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION update_student_payment();

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE driving_lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Policies: élèves ne voient que leurs propres données
CREATE POLICY "Students view own data" ON students
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Students view own lessons" ON driving_lessons
    FOR SELECT USING (
        student_id IN (SELECT id FROM students WHERE user_id = auth.uid())
    );

CREATE POLICY "Students view own payments" ON payments
    FOR SELECT USING (
        student_id IN (SELECT id FROM students WHERE user_id = auth.uid())
    );

CREATE POLICY "Students view own attempts" ON quiz_attempts
    FOR SELECT USING (
        student_id IN (SELECT id FROM students WHERE user_id = auth.uid())
    );

CREATE POLICY "Students insert own attempts" ON quiz_attempts
    FOR INSERT WITH CHECK (
        student_id IN (SELECT id FROM students WHERE user_id = auth.uid())
    );

-- Policies quiz publiques (lecture seule pour tous les utilisateurs connectés)
ALTER TABLE quiz_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_answers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read quiz categories" ON quiz_categories
    FOR SELECT USING (is_active = true);

CREATE POLICY "Anyone can read quiz questions" ON quiz_questions
    FOR SELECT USING (is_active = true);

CREATE POLICY "Anyone can read quiz answers" ON quiz_answers
    FOR SELECT USING (true);

-- =====================================================
-- FONCTIONS UTILITAIRES
-- =====================================================

-- Calcul statistiques école
CREATE OR REPLACE FUNCTION get_school_stats(p_school_id UUID)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_students', COUNT(DISTINCT s.id),
        'active_students', COUNT(DISTINCT s.id) FILTER (WHERE s.status = 'ACTIVE'),
        'total_instructors', COUNT(DISTINCT i.id),
        'lessons_this_month', (
            SELECT COUNT(*) FROM driving_lessons dl
            WHERE dl.school_id = p_school_id
            AND dl.scheduled_date >= DATE_TRUNC('month', NOW())
        ),
        'revenue_this_month', (
            SELECT COALESCE(SUM(p.amount), 0) FROM payments p
            WHERE p.school_id = p_school_id
            AND p.status = 'VALIDATED'
            AND p.payment_date >= DATE_TRUNC('month', NOW())
        )
    ) INTO result
    FROM students s
    LEFT JOIN instructors i ON i.school_id = p_school_id
    WHERE s.school_id = p_school_id;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
