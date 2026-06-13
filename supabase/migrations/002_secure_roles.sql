-- ============================================================
-- PERMISCONNECT - Migration 002 : Sécurisation des Rôles
-- RÈGLE ABSOLUE : tout nouveau compte = 'student'
-- Les admins sont créés UNIQUEMENT via Supabase dashboard
-- ============================================================

-- ============================================================
-- 1. RECRÉER LE TRIGGER handle_new_user — SANS code invitation
--    Tout nouveau compte reçoit TOUJOURS role = 'student'
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_full_name TEXT;
    v_phone     TEXT;
BEGIN
    -- Récupérer les métadonnées de l'utilisateur
    v_full_name := COALESCE(
        NEW.raw_user_meta_data->>'full_name',
        NEW.email,
        'Utilisateur'
    );
    v_phone := NEW.raw_user_meta_data->>'phone';

    -- ⚠️ SÉCURITÉ : le rôle est TOUJOURS 'student' — ignoré si l'app envoie autre chose
    INSERT INTO public.profiles (user_id, full_name, phone, role)
    VALUES (NEW.id, v_full_name, v_phone, 'student')
    ON CONFLICT (user_id) DO NOTHING;

    -- Créer automatiquement l'enregistrement student
    INSERT INTO public.students (profile_id)
    SELECT id FROM public.profiles WHERE user_id = NEW.id
    ON CONFLICT (profile_id) DO NOTHING;

    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Ne jamais bloquer l'inscription même en cas d'erreur
    RAISE LOG 'handle_new_user error: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Supprimer l'ancien trigger et le recréer
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 2. SUPPRIMER la table admin_invitations (plus nécessaire)
--    Les admins sont gérés via le dashboard Supabase uniquement
-- ============================================================
DROP TABLE IF EXISTS public.admin_invitations CASCADE;

-- ============================================================
-- 3. FONCTIONS RLS SÉCURISÉES
-- ============================================================

-- Vérifie si l'utilisateur connecté est admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE user_id = auth.uid()
          AND role IN ('admin', 'super_admin')
          AND is_active = TRUE
    );
$$;

-- Vérifie si l'utilisateur connecté est student
CREATE OR REPLACE FUNCTION public.is_student()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE user_id = auth.uid()
          AND role = 'student'
    );
$$;

-- Retourne le profile_id de l'utilisateur connecté
CREATE OR REPLACE FUNCTION public.my_profile_id()
RETURNS UUID LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT id FROM public.profiles WHERE user_id = auth.uid() LIMIT 1;
$$;

-- Retourne le student_id de l'utilisateur connecté
CREATE OR REPLACE FUNCTION public.my_student_id()
RETURNS UUID LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT s.id FROM public.students s
    JOIN public.profiles p ON p.id = s.profile_id
    WHERE p.user_id = auth.uid()
    LIMIT 1;
$$;

-- ============================================================
-- 4. ACTIVER RLS SUR TOUTES LES TABLES
-- ============================================================
ALTER TABLE public.profiles         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.instructors      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driving_lessons  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_categories  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_questions   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_attempts    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_skills   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driving_skills   ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 5. SUPPRIMER LES ANCIENNES POLICIES (reset propre)
-- ============================================================
DO $$ DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT schemaname, tablename, policyname
        FROM pg_policies
        WHERE schemaname = 'public'
    ) LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I',
            r.policyname, r.schemaname, r.tablename);
    END LOOP;
END $$;

-- ============================================================
-- 6. POLICIES TABLE: profiles
-- ============================================================

-- Tout utilisateur connecté peut lire son propre profil
CREATE POLICY "profiles_select_own"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- Les admins peuvent voir tous les profils
CREATE POLICY "profiles_select_admin"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (public.is_admin());

-- Tout utilisateur peut mettre à jour uniquement son propre profil
CREATE POLICY "profiles_update_own"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (
        user_id = auth.uid()
        -- Un student ne peut JAMAIS modifier son propre rôle
        AND role = (SELECT role FROM public.profiles WHERE user_id = auth.uid())
    );

-- Les admins peuvent tout mettre à jour (y compris les rôles)
CREATE POLICY "profiles_update_admin"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (public.is_admin());

-- Insertion gérée uniquement par le trigger (service role)
CREATE POLICY "profiles_insert_service"
    ON public.profiles FOR INSERT
    TO service_role
    WITH CHECK (TRUE);

-- ============================================================
-- 7. POLICIES TABLE: students
-- ============================================================

-- Un étudiant voit UNIQUEMENT ses propres données
CREATE POLICY "students_select_own"
    ON public.students FOR SELECT
    TO authenticated
    USING (profile_id = public.my_profile_id());

-- Les admins voient tous les étudiants
CREATE POLICY "students_select_admin"
    ON public.students FOR SELECT
    TO authenticated
    USING (public.is_admin());

-- Création via trigger uniquement
CREATE POLICY "students_insert_service"
    ON public.students FOR INSERT
    TO service_role
    WITH CHECK (TRUE);

-- Les admins peuvent modifier les données étudiants
CREATE POLICY "students_update_admin"
    ON public.students FOR UPDATE
    TO authenticated
    USING (public.is_admin());

-- ============================================================
-- 8. POLICIES TABLE: instructors
-- ============================================================

-- Tout utilisateur authentifié peut voir les moniteurs (liste publique interne)
CREATE POLICY "instructors_select_authenticated"
    ON public.instructors FOR SELECT
    TO authenticated
    USING (TRUE);

-- CRUD réservé aux admins
CREATE POLICY "instructors_all_admin"
    ON public.instructors FOR ALL
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ============================================================
-- 9. POLICIES TABLE: vehicles
-- ============================================================

-- Tout utilisateur authentifié peut voir les véhicules
CREATE POLICY "vehicles_select_authenticated"
    ON public.vehicles FOR SELECT
    TO authenticated
    USING (TRUE);

-- CRUD réservé aux admins
CREATE POLICY "vehicles_all_admin"
    ON public.vehicles FOR ALL
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ============================================================
-- 10. POLICIES TABLE: driving_lessons
-- ============================================================

-- Un étudiant voit UNIQUEMENT ses propres cours
CREATE POLICY "lessons_select_own_student"
    ON public.driving_lessons FOR SELECT
    TO authenticated
    USING (student_id = public.my_student_id());

-- Les admins voient tous les cours
CREATE POLICY "lessons_select_admin"
    ON public.driving_lessons FOR SELECT
    TO authenticated
    USING (public.is_admin());

-- Création/modification réservée aux admins
CREATE POLICY "lessons_all_admin"
    ON public.driving_lessons FOR ALL
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ============================================================
-- 11. POLICIES TABLE: payments
-- ============================================================

-- Un étudiant voit UNIQUEMENT ses propres paiements
CREATE POLICY "payments_select_own"
    ON public.payments FOR SELECT
    TO authenticated
    USING (student_id = public.my_student_id());

-- Les admins voient TOUS les paiements
CREATE POLICY "payments_select_admin"
    ON public.payments FOR SELECT
    TO authenticated
    USING (public.is_admin());

-- Création via Edge Function (service role) ou admin
CREATE POLICY "payments_insert_service"
    ON public.payments FOR INSERT
    TO service_role
    WITH CHECK (TRUE);

CREATE POLICY "payments_insert_admin"
    ON public.payments FOR INSERT
    TO authenticated
    WITH CHECK (public.is_admin());

-- Mise à jour réservée aux admins (pour marquer comme payé, etc.)
CREATE POLICY "payments_update_admin"
    ON public.payments FOR UPDATE
    TO authenticated
    USING (public.is_admin());

-- ============================================================
-- 12. POLICIES TABLE: quiz (public en lecture pour étudiants)
-- ============================================================

-- Catégories et questions : lisibles par tous les utilisateurs authentifiés
CREATE POLICY "quiz_categories_select"
    ON public.quiz_categories FOR SELECT
    TO authenticated
    USING (is_active = TRUE OR public.is_admin());

CREATE POLICY "quiz_categories_all_admin"
    ON public.quiz_categories FOR ALL
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

CREATE POLICY "quiz_questions_select"
    ON public.quiz_questions FOR SELECT
    TO authenticated
    USING (TRUE);

CREATE POLICY "quiz_questions_all_admin"
    ON public.quiz_questions FOR ALL
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- Tentatives de quiz : chaque étudiant voit les siennes
CREATE POLICY "quiz_attempts_select_own"
    ON public.quiz_attempts FOR SELECT
    TO authenticated
    USING (student_id = public.my_student_id());

CREATE POLICY "quiz_attempts_select_admin"
    ON public.quiz_attempts FOR SELECT
    TO authenticated
    USING (public.is_admin());

CREATE POLICY "quiz_attempts_insert_own"
    ON public.quiz_attempts FOR INSERT
    TO authenticated
    WITH CHECK (student_id = public.my_student_id());

-- ============================================================
-- 13. POLICIES TABLE: driving_skills + student_skills
-- ============================================================

CREATE POLICY "driving_skills_select"
    ON public.driving_skills FOR SELECT
    TO authenticated
    USING (TRUE);

CREATE POLICY "driving_skills_all_admin"
    ON public.driving_skills FOR ALL
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

CREATE POLICY "student_skills_select_own"
    ON public.student_skills FOR SELECT
    TO authenticated
    USING (student_id = public.my_student_id());

CREATE POLICY "student_skills_select_admin"
    ON public.student_skills FOR SELECT
    TO authenticated
    USING (public.is_admin());

CREATE POLICY "student_skills_all_admin"
    ON public.student_skills FOR ALL
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ============================================================
-- 14. SEED : Données de démonstration
-- ============================================================

-- Catégories de quiz si absentes
INSERT INTO public.quiz_categories (name, description, color, is_active) VALUES
    ('Panneaux de signalisation', 'Reconnaître et comprendre les panneaux routiers', '#1E65C5', TRUE),
    ('Priorités et intersections', 'Règles de priorité aux carrefours', '#FF7F27', TRUE),
    ('Règles de conduite', 'Code de la route et comportement au volant', '#27AE60', TRUE),
    ('Distances et vitesses', 'Distances de sécurité et limitations de vitesse', '#8E44AD', TRUE),
    ('Alcool et drogues', 'Effets sur la conduite et sanctions', '#E74C3C', TRUE),
    ('Premiers secours', 'Gestes à adopter en cas d''accident', '#16A085', TRUE)
ON CONFLICT DO NOTHING;

-- Compétences de conduite si absentes
INSERT INTO public.driving_skills (name, category, description) VALUES
    ('Démarrage en côte', 'Manœuvres de base', 'Maîtriser le démarrage sur une pente'),
    ('Stationnement en créneau', 'Manœuvres de base', 'Se garer en marche arrière entre deux véhicules'),
    ('Demi-tour', 'Manœuvres de base', 'Faire demi-tour en manœuvrant'),
    ('Respect des priorités', 'Code de la route', 'Appliquer les règles de priorité'),
    ('Gestion de la vitesse', 'Code de la route', 'Adapter sa vitesse aux conditions'),
    ('Regard et anticipation', 'Conduite préventive', 'Observer et anticiper les situations dangereuses'),
    ('Conduite en agglomération', 'Environnements', 'Maîtriser la conduite en ville'),
    ('Conduite sur route', 'Environnements', 'Maîtriser la conduite hors agglomération')
ON CONFLICT DO NOTHING;

-- ============================================================
-- INSTRUCTION : Comment créer un admin
-- ============================================================
-- Dans Supabase Dashboard > Table Editor > profiles
-- Mettre à jour le champ role = 'admin' pour l'utilisateur souhaité
--
-- Ou via SQL :
-- UPDATE public.profiles SET role = 'admin' WHERE user_id = 'UUID_DU_USER';
-- ============================================================
