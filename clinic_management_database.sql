-- ============================================
-- SCRIPT DE CRIAÇÃO DO BANCO DE DADOS
-- SaaS para Gestão de Clínicas Multidisciplinares
-- Versão: 1.0
-- Data: 2024
-- ============================================

-- ============================================
-- 1. CRIAÇÃO DAS TABELAS PRINCIPAIS
-- ============================================

-- Tabela: clinics - Dados da clínica
-- Armazena informações básicas da clínica/empresa
CREATE TABLE clinics (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    cnpj VARCHAR(18) UNIQUE NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(2),
    zip_code VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'ACTIVE' -- ACTIVE, INACTIVE, SUSPENDED
);

-- Tabela: roles - Roles do sistema (criada antes de users)
-- Define roles que podem ser atribuídos aos usuários
CREATE TABLE roles (
    id BIGSERIAL PRIMARY KEY,
    clinic_id BIGINT REFERENCES clinics(id),
    name VARCHAR(100) NOT NULL, -- 'Fisioterapeuta', 'Recepcionista', 'Gerente', etc.
    description TEXT,
    is_system_role BOOLEAN DEFAULT FALSE, -- Roles do sistema vs customizados por clínica
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(clinic_id, name), -- Nome único por clínica
    
    -- Constraints originais que foram removidos
    CONSTRAINT chk_role_name 
        CHECK (LENGTH(name) >= 2 AND LENGTH(name) <= 100)
);

-- Tabela: users - Usuários do sistema
-- Inclui administradores, profissionais e recepcionistas
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    clinic_id BIGINT REFERENCES clinics(id),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    role VARCHAR(20) NOT NULL, -- ADMIN, MANAGER, PROFESSIONAL, RECEPTIONIST
    role_id BIGINT REFERENCES roles(id), -- Role customizado da clínica
    professional_type VARCHAR(50), -- FISIOTERAPIA, NUTRIÇÃO, PSICOLOGIA, etc.
    license_number VARCHAR(50), -- CRF, CRP, etc.
    is_active BOOLEAN DEFAULT TRUE, -- Status ativo/inativo
    last_login TIMESTAMP, -- Último login
    login_attempts INTEGER DEFAULT 0, -- Tentativas de login
    locked_until TIMESTAMP, -- Bloqueio por tentativas
    
    -- Campos adicionais para melhorias
    avatar_url VARCHAR(500), -- Foto do usuário
    timezone VARCHAR(50) DEFAULT 'America/Sao_Paulo', -- Fuso horário
    language VARCHAR(10) DEFAULT 'pt-BR', -- Idioma preferido
    two_factor_enabled BOOLEAN DEFAULT FALSE, -- 2FA habilitado
    two_factor_secret VARCHAR(255), -- Secret para 2FA
    notification_preferences JSONB, -- Preferências de notificação
    working_hours JSONB, -- Horários de trabalho (dias da semana e horários)
    bio TEXT, -- Biografia do profissional
    specialties TEXT[], -- Especialidades do profissional
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    
    -- Constraints para campos adicionais
    CONSTRAINT chk_user_language 
        CHECK (language IN ('pt-BR', 'en-US', 'es-ES')),
    CONSTRAINT chk_user_two_factor 
        CHECK (two_factor_enabled IN (TRUE, FALSE)),
    
    -- Constraints originais que foram removidos
    CONSTRAINT chk_user_role 
        CHECK (role IN ('ADMIN', 'MANAGER', 'PROFESSIONAL', 'RECEPTIONIST'))
);

-- Tabela: clients - Clientes/Pacientes da clínica
-- Inclui campos para controle de pagamentos e informações médicas
CREATE TABLE clients (
    id BIGSERIAL PRIMARY KEY,
    clinic_id BIGINT REFERENCES clinics(id),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    cpf VARCHAR(14) UNIQUE,
    birth_date DATE,
    gender VARCHAR(10), -- MALE, FEMALE, OTHER
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(2),
    zip_code VARCHAR(10),
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(20),
    medical_conditions TEXT, -- Condições médicas
    allergies TEXT, -- Alergias
    
    -- Campos para controle de pagamentos
    payment_status VARCHAR(20) DEFAULT 'CURRENT', -- CURRENT, OVERDUE, SUSPENDED
    last_payment_date TIMESTAMP,
    overdue_amount DECIMAL(10,2) DEFAULT 0,
    payment_reminder_count INTEGER DEFAULT 0,
    
    -- Campos adicionais para melhorias
    avatar_url VARCHAR(500), -- Foto do cliente
    preferred_language VARCHAR(10) DEFAULT 'pt-BR', -- Idioma preferido
    timezone VARCHAR(50) DEFAULT 'America/Sao_Paulo', -- Fuso horário
    marketing_consent BOOLEAN DEFAULT FALSE, -- Consentimento para marketing
    data_processing_consent BOOLEAN DEFAULT TRUE, -- Consentimento para processamento de dados
    communication_preferences JSONB, -- Preferências de comunicação (email, sms, whatsapp)
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    
    -- Constraints originais que foram removidos
    CONSTRAINT chk_client_payment_status 
        CHECK (payment_status IN ('CURRENT', 'OVERDUE', 'SUSPENDED')),
    CONSTRAINT chk_client_gender 
        CHECK (gender IN ('MALE', 'FEMALE', 'OTHER'))
);

-- Tabela: service_types - Tipos de serviços oferecidos
-- Define os diferentes tipos de atendimentos e aulas
CREATE TABLE service_types (
    id BIGSERIAL PRIMARY KEY,
    clinic_id BIGINT REFERENCES clinics(id),
    name VARCHAR(100) NOT NULL, -- FISIOTERAPIA, NUTRIÇÃO, PSICOLOGIA, PILATES, etc.
    description TEXT,
    duration_minutes INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    is_group_service BOOLEAN DEFAULT FALSE, -- Para aulas em grupo
    max_capacity INTEGER, -- Para aulas em grupo
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'ACTIVE'
);

-- Tabela: appointments - Agendamentos de consultas/atendimentos
-- Controla todos os agendamentos individuais
CREATE TABLE appointments (
    id BIGSERIAL PRIMARY KEY,
    clinic_id BIGINT REFERENCES clinics(id),
    client_id BIGINT REFERENCES clients(id),
    professional_id BIGINT REFERENCES users(id),
    service_type_id BIGINT REFERENCES service_types(id),
    scheduled_date DATE NOT NULL,
    scheduled_time TIME NOT NULL,
    duration_minutes INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'SCHEDULED', -- SCHEDULED, CONFIRMED, COMPLETED, CANCELLED, NO_SHOW
    notes TEXT,
    price DECIMAL(10,2),
    
    -- Campos adicionais para melhorias
    reminder_sent BOOLEAN DEFAULT FALSE, -- Lembrete enviado
    cancellation_reason TEXT, -- Motivo do cancelamento
    reschedule_count INTEGER DEFAULT 0, -- Quantas vezes foi reagendado
    original_appointment_id BIGINT REFERENCES appointments(id), -- ID do agendamento original (se foi reagendado)
    check_in_time TIMESTAMP, -- Horário de chegada
    check_out_time TIMESTAMP, -- Horário de saída
    satisfaction_rating INTEGER, -- Avaliação do atendimento (1-5)
    satisfaction_comment TEXT, -- Comentário da avaliação
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints para campos adicionais
    CONSTRAINT chk_appointment_rating 
        CHECK (satisfaction_rating IS NULL OR (satisfaction_rating >= 1 AND satisfaction_rating <= 5)),
    CONSTRAINT chk_appointment_reschedule_count 
        CHECK (reschedule_count >= 0),
    
    -- Constraints originais que foram removidos
    CONSTRAINT chk_appointment_time 
        CHECK (scheduled_time >= '06:00' AND scheduled_time <= '22:00'),
    CONSTRAINT chk_appointment_duration 
        CHECK (duration_minutes > 0 AND duration_minutes <= 480), -- Máximo 8 horas
    CONSTRAINT chk_appointment_status 
        CHECK (status IN ('SCHEDULED', 'CONFIRMED', 'COMPLETED', 'CANCELLED', 'NO_SHOW'))
);

-- Tabela: classes - Aulas em grupo
-- Controla aulas como pilates, hidroginástica, etc.
CREATE TABLE classes (
    id BIGSERIAL PRIMARY KEY,
    clinic_id BIGINT REFERENCES clinics(id),
    name VARCHAR(100) NOT NULL, -- PILATES, HIDROGINÁSTICA, etc.
    instructor_id BIGINT REFERENCES users(id),
    service_type_id BIGINT REFERENCES service_types(id),
    scheduled_date DATE NOT NULL,
    scheduled_time TIME NOT NULL,
    duration_minutes INTEGER NOT NULL,
    max_capacity INTEGER NOT NULL,
    current_enrollment INTEGER DEFAULT 0,
    price DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'SCHEDULED', -- SCHEDULED, CONFIRMED, COMPLETED, CANCELLED
    
    -- Campos adicionais para melhorias
    waiting_list JSONB, -- Lista de espera (array de client_ids)
    equipment_needed TEXT, -- Equipamentos necessários
    difficulty_level VARCHAR(20), -- BEGINNER, INTERMEDIATE, ADVANCED
    room_location VARCHAR(100), -- Local da aula (Sala 1, Piscina, etc.)
    special_instructions TEXT, -- Instruções especiais
    cancellation_reason TEXT, -- Motivo do cancelamento
    reminder_sent BOOLEAN DEFAULT FALSE, -- Lembrete enviado
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints para campos adicionais
    CONSTRAINT chk_class_difficulty 
        CHECK (difficulty_level IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED')),
    
    -- Constraints originais que foram removidos
    CONSTRAINT chk_class_capacity 
        CHECK (current_enrollment <= max_capacity),
    CONSTRAINT chk_class_time 
        CHECK (scheduled_time >= '06:00' AND scheduled_time <= '22:00'),
    CONSTRAINT chk_class_status 
        CHECK (status IN ('SCHEDULED', 'CONFIRMED', 'COMPLETED', 'CANCELLED'))
);

-- Tabela: class_enrollments - Inscrições em aulas
-- Relaciona clientes com aulas específicas
CREATE TABLE class_enrollments (
    id BIGSERIAL PRIMARY KEY,
    class_id BIGINT REFERENCES classes(id),
    client_id BIGINT REFERENCES clients(id),
    enrollment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'ACTIVE', -- ACTIVE, CANCELLED, COMPLETED
    notes TEXT
);

-- Tabela: payments - Pagamentos
-- Controla todos os pagamentos realizados
CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,
    clinic_id BIGINT REFERENCES clinics(id),
    client_id BIGINT REFERENCES clients(id),
    appointment_id BIGINT REFERENCES appointments(id), -- NULL se for pagamento de aula
    class_id BIGINT REFERENCES classes(id), -- NULL se for pagamento de consulta
    amount DECIMAL(10,2) NOT NULL,
    payment_date TIMESTAMP NOT NULL,
    payment_method VARCHAR(20) NOT NULL, -- PIX, CARD, CASH, BANK_TRANSFER
    payment_type VARCHAR(20) NOT NULL, -- APPOINTMENT, CLASS, MONTHLY, PACKAGE
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, COMPLETED, FAILED, REFUNDED
    transaction_id VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints originais que foram removidos
    CONSTRAINT chk_payment_amount 
        CHECK (amount > 0),
    CONSTRAINT chk_payment_status 
        CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED')),
    CONSTRAINT chk_payment_method 
        CHECK (payment_method IN ('PIX', 'CARD', 'CASH', 'BANK_TRANSFER')),
    CONSTRAINT chk_payment_type 
        CHECK (payment_type IN ('APPOINTMENT', 'CLASS', 'MONTHLY', 'PACKAGE'))
);

-- Tabela: payment_plans - Planos de pagamento
-- Define pacotes e mensalidades
CREATE TABLE payment_plans (
    id BIGSERIAL PRIMARY KEY,
    clinic_id BIGINT REFERENCES clinics(id),
    name VARCHAR(100) NOT NULL, -- PACOTE 10 SESSÕES, MENSALIDADE, etc.
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    sessions_included INTEGER, -- Número de sessões incluídas
    validity_days INTEGER, -- Dias de validade do plano
    is_recurring BOOLEAN DEFAULT FALSE, -- Se é mensalidade recorrente
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'ACTIVE'
);

-- Tabela: client_plans - Planos adquiridos pelos clientes
-- Controla quais planos cada cliente possui
CREATE TABLE client_plans (
    id BIGSERIAL PRIMARY KEY,
    client_id BIGINT REFERENCES clients(id),
    payment_plan_id BIGINT REFERENCES payment_plans(id),
    purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expiry_date TIMESTAMP,
    sessions_used INTEGER DEFAULT 0,
    sessions_remaining INTEGER,
    status VARCHAR(20) DEFAULT 'ACTIVE', -- ACTIVE, EXPIRED, CANCELLED
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela: payment_history - Histórico de pagamentos
-- Mantém histórico detalhado de todos os pagamentos
CREATE TABLE payment_history (
    id BIGSERIAL PRIMARY KEY,
    client_id BIGINT REFERENCES clients(id),
    payment_id BIGINT REFERENCES payments(id),
    amount DECIMAL(10,2) NOT NULL,
    payment_date TIMESTAMP NOT NULL,
    due_date TIMESTAMP,
    status VARCHAR(20) NOT NULL, -- PAID, OVERDUE, PENDING
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela: payment_settings - Configurações de pagamento da clínica
-- Define regras de pagamento específicas de cada clínica
CREATE TABLE payment_settings (
    id BIGSERIAL PRIMARY KEY,
    clinic_id BIGINT REFERENCES clinics(id),
    payment_terms_days INTEGER DEFAULT 30, -- Dias para pagamento
    late_fee_percentage DECIMAL(5,2) DEFAULT 0, -- Multa por atraso (%)
    reminder_days INTEGER DEFAULT 7, -- Dias antes do vencimento para lembrete
    suspension_days INTEGER DEFAULT 15, -- Dias de atraso para suspensão
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela: audit_logs - Log de auditoria
-- Registra todas as alterações importantes no sistema
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id BIGINT NOT NULL,
    action VARCHAR(20) NOT NULL, -- INSERT, UPDATE, DELETE
    old_values JSONB,
    new_values JSONB,
    user_id BIGINT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela: notifications - Notificações
-- Sistema de notificações para clientes e usuários
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    clinic_id BIGINT REFERENCES clinics(id),
    user_id BIGINT REFERENCES users(id),
    client_id BIGINT REFERENCES clients(id),
    type VARCHAR(50) NOT NULL, -- APPOINTMENT_REMINDER, PAYMENT_DUE, etc.
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    scheduled_for TIMESTAMP,
    sent_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela: settings - Configurações gerais
-- Configurações específicas de cada clínica
CREATE TABLE settings (
    id BIGSERIAL PRIMARY KEY,
    clinic_id BIGINT REFERENCES clinics(id),
    setting_key VARCHAR(100) NOT NULL,
    setting_value TEXT,
    setting_type VARCHAR(20) DEFAULT 'STRING', -- STRING, NUMBER, BOOLEAN, JSON
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(clinic_id, setting_key)
);

-- ============================================
-- 2. NOVAS TABELAS PARA MELHORIAS
-- ============================================

-- Tabela: reminders - Lembretes automáticos
-- Gerencia lembretes de consultas, aulas e pagamentos
CREATE TABLE reminders (
    id BIGSERIAL PRIMARY KEY,
    clinic_id BIGINT REFERENCES clinics(id),
    appointment_id BIGINT REFERENCES appointments(id),
    class_id BIGINT REFERENCES classes(id),
    client_id BIGINT REFERENCES clients(id),
    reminder_type VARCHAR(50) NOT NULL, -- APPOINTMENT, CLASS, PAYMENT, BIRTHDAY, etc.
    scheduled_time TIMESTAMP NOT NULL,
    sent_time TIMESTAMP,
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, SENT, FAILED, CANCELLED
    method VARCHAR(20) NOT NULL, -- EMAIL, SMS, WHATSAPP, PUSH
    message TEXT NOT NULL,
    subject VARCHAR(255), -- Assunto (para email)
    retry_count INTEGER DEFAULT 0,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_reminder_type 
        CHECK (reminder_type IN ('APPOINTMENT', 'CLASS', 'PAYMENT', 'BIRTHDAY', 'PROMOTION', 'GENERAL')),
    CONSTRAINT chk_reminder_status 
        CHECK (status IN ('PENDING', 'SENT', 'FAILED', 'CANCELLED')),
    CONSTRAINT chk_reminder_method 
        CHECK (method IN ('EMAIL', 'SMS', 'WHATSAPP', 'PUSH')),
    CONSTRAINT chk_reminder_retry_count 
        CHECK (retry_count >= 0)
);

-- Tabela: notification_preferences - Preferências de notificação
-- Controla como cada usuário/cliente prefere receber notificações
CREATE TABLE notification_preferences (
    id BIGSERIAL PRIMARY KEY,
    clinic_id BIGINT REFERENCES clinics(id),
    user_id BIGINT REFERENCES users(id),
    client_id BIGINT REFERENCES clients(id),
    notification_type VARCHAR(50) NOT NULL, -- APPOINTMENT_REMINDER, PAYMENT_DUE, CLASS_REMINDER, etc.
    email_enabled BOOLEAN DEFAULT TRUE,
    sms_enabled BOOLEAN DEFAULT FALSE,
    whatsapp_enabled BOOLEAN DEFAULT FALSE,
    push_enabled BOOLEAN DEFAULT TRUE,
    advance_hours INTEGER DEFAULT 24, -- Quantas horas antes enviar
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(clinic_id, user_id, client_id, notification_type),
    
    -- Constraints
    CONSTRAINT chk_notification_type 
        CHECK (notification_type IN ('APPOINTMENT_REMINDER', 'PAYMENT_DUE', 'CLASS_REMINDER', 'BIRTHDAY', 'PROMOTION', 'SYSTEM')),
    CONSTRAINT chk_notification_advance_hours 
        CHECK (advance_hours >= 0 AND advance_hours <= 168) -- Máximo 7 dias
);

-- Tabela: integrations - Integrações externas
-- Gerencia integrações com serviços externos
CREATE TABLE integrations (
    id BIGSERIAL PRIMARY KEY,
    clinic_id BIGINT REFERENCES clinics(id),
    integration_type VARCHAR(50) NOT NULL, -- ZOOM, GOOGLE_CALENDAR, WHATSAPP, STRIPE, etc.
    name VARCHAR(100) NOT NULL, -- Nome da integração
    api_key VARCHAR(500),
    api_secret VARCHAR(500),
    webhook_url VARCHAR(500),
    configuration JSONB, -- Configurações específicas da integração
    is_active BOOLEAN DEFAULT TRUE,
    last_sync TIMESTAMP,
    sync_status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, SUCCESS, FAILED
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_integration_type 
        CHECK (integration_type IN ('ZOOM', 'GOOGLE_CALENDAR', 'WHATSAPP', 'STRIPE', 'PAGSEGURO', 'MERCADO_PAGO', 'SENDGRID', 'TWILIO')),
    CONSTRAINT chk_integration_status 
        CHECK (sync_status IN ('PENDING', 'SUCCESS', 'FAILED'))
);

-- Tabela: client_notes - Notas dos clientes
-- Permite adicionar notas personalizadas aos clientes
CREATE TABLE client_notes (
    id BIGSERIAL PRIMARY KEY,
    client_id BIGINT REFERENCES clients(id),
    user_id BIGINT REFERENCES users(id),
    note_type VARCHAR(50) DEFAULT 'GENERAL', -- GENERAL, MEDICAL, ADMINISTRATIVE, etc.
    title VARCHAR(255),
    content TEXT NOT NULL,
    is_private BOOLEAN DEFAULT FALSE, -- Se apenas o criador pode ver
    is_important BOOLEAN DEFAULT FALSE, -- Se é uma nota importante
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_note_type 
        CHECK (note_type IN ('GENERAL', 'MEDICAL', 'ADMINISTRATIVE', 'FINANCIAL', 'PERSONAL'))
);

-- Tabela: appointment_feedback - Feedback dos atendimentos
-- Coleta feedback dos clientes sobre os atendimentos
CREATE TABLE appointment_feedback (
    id BIGSERIAL PRIMARY KEY,
    appointment_id BIGINT REFERENCES appointments(id),
    client_id BIGINT REFERENCES clients(id),
    professional_id BIGINT REFERENCES users(id),
    overall_rating INTEGER NOT NULL, -- 1-5
    professional_rating INTEGER, -- 1-5
    facility_rating INTEGER, -- 1-5
    service_rating INTEGER, -- 1-5
    comments TEXT,
    would_recommend BOOLEAN,
    improvement_suggestions TEXT,
    is_anonymous BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_appointment_feedback_rating 
        CHECK (overall_rating >= 1 AND overall_rating <= 5),
    CONSTRAINT chk_appointment_feedback_professional_rating 
        CHECK (professional_rating IS NULL OR (professional_rating >= 1 AND professional_rating <= 5)),
    CONSTRAINT chk_appointment_feedback_facility_rating 
        CHECK (facility_rating IS NULL OR (facility_rating >= 1 AND facility_rating <= 5)),
    CONSTRAINT chk_appointment_feedback_service_rating 
        CHECK (service_rating IS NULL OR (service_rating >= 1 AND service_rating <= 5))
);

-- Tabela: class_feedback - Feedback das aulas
-- Coleta feedback dos alunos sobre as aulas
CREATE TABLE class_feedback (
    id BIGSERIAL PRIMARY KEY,
    class_id BIGINT REFERENCES classes(id),
    client_id BIGINT REFERENCES clients(id),
    instructor_id BIGINT REFERENCES users(id),
    overall_rating INTEGER NOT NULL, -- 1-5
    instructor_rating INTEGER, -- 1-5
    difficulty_rating INTEGER, -- 1-5 (muito fácil - muito difícil)
    comments TEXT,
    would_recommend BOOLEAN,
    improvement_suggestions TEXT,
    is_anonymous BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_class_feedback_rating 
        CHECK (overall_rating >= 1 AND overall_rating <= 5),
    CONSTRAINT chk_class_feedback_instructor_rating 
        CHECK (instructor_rating IS NULL OR (instructor_rating >= 1 AND instructor_rating <= 5)),
    CONSTRAINT chk_class_feedback_difficulty_rating 
        CHECK (difficulty_rating IS NULL OR (difficulty_rating >= 1 AND difficulty_rating <= 5))
);

-- Tabela: system_logs - Logs do sistema
-- Registra eventos importantes do sistema
CREATE TABLE system_logs (
    id BIGSERIAL PRIMARY KEY,
    clinic_id BIGINT REFERENCES clinics(id),
    user_id BIGINT REFERENCES users(id),
    log_level VARCHAR(20) NOT NULL, -- INFO, WARN, ERROR, DEBUG
    category VARCHAR(50) NOT NULL, -- AUTH, PAYMENT, APPOINTMENT, etc.
    message TEXT NOT NULL,
    details JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_system_log_level 
        CHECK (log_level IN ('INFO', 'WARN', 'ERROR', 'DEBUG')),
    CONSTRAINT chk_system_log_category 
        CHECK (category IN ('AUTH', 'PAYMENT', 'APPOINTMENT', 'CLASS', 'CLIENT', 'USER', 'SYSTEM', 'INTEGRATION'))
);

-- ============================================
-- 3. CRIAÇÃO DE ÍNDICES PARA PERFORMANCE
-- ============================================

-- Índices para tabela clients
CREATE INDEX idx_clients_clinic_id ON clients(clinic_id);
CREATE INDEX idx_clients_cpf ON clients(cpf);
CREATE INDEX idx_clients_payment_status ON clients(payment_status);
CREATE INDEX idx_clients_status ON clients(status);
CREATE INDEX idx_clients_marketing_consent ON clients(marketing_consent);
CREATE INDEX idx_clients_language ON clients(preferred_language);
CREATE INDEX idx_clients_timezone ON clients(timezone);

-- Índices para tabela appointments
CREATE INDEX idx_appointments_date ON appointments(scheduled_date);
CREATE INDEX idx_appointments_client ON appointments(client_id);
CREATE INDEX idx_appointments_professional ON appointments(professional_id);
CREATE INDEX idx_appointments_clinic ON appointments(clinic_id);
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_appointments_reminder_sent ON appointments(reminder_sent);
CREATE INDEX idx_appointments_rating ON appointments(satisfaction_rating);
CREATE INDEX idx_appointments_original ON appointments(original_appointment_id);

-- Índices para tabela classes
CREATE INDEX idx_classes_date ON classes(scheduled_date);
CREATE INDEX idx_classes_instructor ON classes(instructor_id);
CREATE INDEX idx_classes_clinic ON classes(clinic_id);
CREATE INDEX idx_classes_status ON classes(status);
CREATE INDEX idx_classes_difficulty ON classes(difficulty_level);
CREATE INDEX idx_classes_reminder_sent ON classes(reminder_sent);
CREATE INDEX idx_classes_location ON classes(room_location);

-- Índices para tabela payments
CREATE INDEX idx_payments_client ON payments(client_id);
CREATE INDEX idx_payments_date ON payments(payment_date);
CREATE INDEX idx_payments_clinic ON payments(clinic_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_type ON payments(payment_type);

-- Índices para tabela roles
CREATE INDEX idx_roles_clinic ON roles(clinic_id);
CREATE INDEX idx_roles_active ON roles(is_active);
CREATE INDEX idx_roles_system ON roles(is_system_role);

-- Índices para tabela users
CREATE INDEX idx_users_clinic ON users(clinic_id);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_role_id ON users(role_id);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_active ON users(is_active);
CREATE INDEX idx_users_last_login ON users(last_login);
CREATE INDEX idx_users_locked ON users(locked_until);
CREATE INDEX idx_users_language ON users(language);
CREATE INDEX idx_users_timezone ON users(timezone);
CREATE INDEX idx_users_two_factor ON users(two_factor_enabled);

-- Índices para tabela class_enrollments
CREATE INDEX idx_class_enrollments_class ON class_enrollments(class_id);
CREATE INDEX idx_class_enrollments_client ON class_enrollments(client_id);
CREATE INDEX idx_class_enrollments_status ON class_enrollments(status);

-- Índices para tabela notifications
CREATE INDEX idx_notifications_clinic ON notifications(clinic_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_client ON notifications(client_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_scheduled ON notifications(scheduled_for);


-- ============================================
-- 4. VIEWS PARA RELATÓRIOS
-- ============================================

-- View: Clientes inadimplentes
CREATE VIEW v_overdue_clients AS
SELECT 
    c.id,
    c.name,
    c.phone,
    c.email,
    c.overdue_amount,
    c.last_payment_date,
    (CURRENT_DATE - c.last_payment_date::date) as days_overdue,
    c.payment_reminder_count
FROM clients c
WHERE c.payment_status = 'OVERDUE'
    AND c.status = 'ACTIVE';

-- View: Atendimentos do dia
CREATE VIEW v_appointments_today AS
SELECT 
    a.id,
    a.scheduled_date,
    a.scheduled_time,
    c.name as client_name,
    c.phone as client_phone,
    u.name as professional_name,
    st.name as service_name,
    a.status,
    a.price
FROM appointments a
JOIN clients c ON a.client_id = c.id
JOIN users u ON a.professional_id = u.id
JOIN service_types st ON a.service_type_id = st.id
WHERE a.scheduled_date = CURRENT_DATE
    AND a.status IN ('SCHEDULED', 'CONFIRMED');

-- View: Aulas do dia
CREATE VIEW v_classes_today AS
SELECT 
    cl.id,
    cl.scheduled_date,
    cl.scheduled_time,
    cl.name as class_name,
    u.name as instructor_name,
    cl.current_enrollment,
    cl.max_capacity,
    cl.status,
    cl.price
FROM classes cl
JOIN users u ON cl.instructor_id = u.id
WHERE cl.scheduled_date = CURRENT_DATE
    AND cl.status IN ('SCHEDULED', 'CONFIRMED');

-- View: Faturamento mensal
CREATE VIEW v_monthly_revenue AS
SELECT 
    clinic_id,
    DATE_TRUNC('month', payment_date) as month,
    payment_type,
    COUNT(*) as total_transactions,
    SUM(amount) as total_revenue,
    AVG(amount) as average_ticket
FROM payments 
WHERE status = 'COMPLETED'
GROUP BY clinic_id, DATE_TRUNC('month', payment_date), payment_type;

-- View: Calendário unificado (aulas + atendimentos)
CREATE VIEW v_daily_schedule AS
SELECT 
    'APPOINTMENT' as type,
    a.scheduled_time as time,
    c.name as client_name,
    u.name as professional_name,
    st.name as service_name,
    a.status,
    a.price
FROM appointments a
JOIN clients c ON a.client_id = c.id
JOIN users u ON a.professional_id = u.id
JOIN service_types st ON a.service_type_id = st.id
WHERE a.scheduled_date = CURRENT_DATE

UNION ALL

SELECT 
    'CLASS' as type,
    cl.scheduled_time as time,
    CONCAT('Aula: ', cl.name) as client_name,
    u.name as professional_name,
    CONCAT('Capacidade: ', cl.current_enrollment, '/', cl.max_capacity) as service_name,
    cl.status,
    cl.price
FROM classes cl
JOIN users u ON cl.instructor_id = u.id
WHERE cl.scheduled_date = CURRENT_DATE

ORDER BY time;

-- View: Alunos por aula
CREATE VIEW v_class_enrollments AS
SELECT 
    cl.id as class_id,
    cl.name as class_name,
    cl.scheduled_date,
    cl.scheduled_time,
    c.name as client_name,
    c.phone as client_phone,
    ce.enrollment_date,
    ce.status as enrollment_status
FROM classes cl
JOIN class_enrollments ce ON cl.id = ce.class_id
JOIN clients c ON ce.client_id = c.id
WHERE ce.status = 'ACTIVE';

-- ============================================
-- 5. DADOS INICIAIS
-- ============================================

-- Inserir clínica exemplo
INSERT INTO clinics (name, cnpj, email, phone, address, city, state, zip_code) 
VALUES ('Clínica Exemplo', '12.345.678/0001-90', 'contato@clinicaexemplo.com', '(11) 99999-9999', 'Rua Exemplo, 123', 'São Paulo', 'SP', '01234-567');

-- Inserir roles do sistema
INSERT INTO roles (clinic_id, name, description, is_system_role) VALUES
(1, 'Administrador', 'Acesso total ao sistema', TRUE),
(1, 'Gerente', 'Gestão completa da clínica', TRUE),
(1, 'Recepcionista', 'Atendimento e agendamentos', TRUE),
(1, 'Fisioterapeuta', 'Profissional de fisioterapia', TRUE),
(1, 'Nutricionista', 'Profissional de nutrição', TRUE),
(1, 'Psicólogo', 'Profissional de psicologia', TRUE);

-- Inserir usuário administrador
INSERT INTO users (clinic_id, name, email, password_hash, phone, role, role_id, professional_type, license_number, is_active, last_login)
VALUES (1, 'Admin Sistema', 'admin@clinicaexemplo.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', '(11) 99999-9999', 'ADMIN', 1, NULL, NULL, TRUE, CURRENT_TIMESTAMP);

-- Inserir tipos de serviços
INSERT INTO service_types (clinic_id, name, description, duration_minutes, price, is_group_service, max_capacity)
VALUES 
(1, 'Fisioterapia', 'Sessão individual de fisioterapia', 60, 150.00, FALSE, NULL),
(1, 'Nutrição', 'Consulta nutricional', 45, 120.00, FALSE, NULL),
(1, 'Psicologia', 'Sessão de terapia psicológica', 50, 180.00, FALSE, NULL),
(1, 'Pilates', 'Aula de pilates em grupo', 60, 80.00, TRUE, 12),
(1, 'Hidroginástica', 'Aula de hidroginástica', 45, 60.00, TRUE, 20);

-- Inserir configurações de pagamento
INSERT INTO payment_settings (clinic_id, payment_terms_days, late_fee_percentage, reminder_days, suspension_days)
VALUES (1, 30, 2.0, 7, 15);

-- Inserir configurações gerais
INSERT INTO settings (clinic_id, setting_key, setting_value, setting_type)
VALUES 
(1, 'business_hours_start', '07:00', 'STRING'),
(1, 'business_hours_end', '21:00', 'STRING'),
(1, 'appointment_reminder_hours', '24', 'NUMBER'),
(1, 'class_reminder_hours', '2', 'NUMBER');

-- ============================================
-- 6. COMENTÁRIOS FINAIS
-- ============================================

-- Este script cria um banco de dados completo para gestão de clínicas multidisciplinares
-- Principais funcionalidades cobertas:
-- ✅ Controle de clientes com status de pagamento
-- ✅ Agendamento de consultas individuais
-- ✅ Gestão de aulas em grupo
-- ✅ Sistema de pagamentos completo
-- ✅ Relatórios de faturamento
-- ✅ Calendário unificado
-- ✅ Controle de inadimplência
-- ✅ Sistema de notificações
-- ✅ Auditoria de alterações
-- ✅ Configurações flexíveis por clínica

-- Próximos passos recomendados:
-- 1. Testar todas as queries de exemplo
-- 2. Implementar as entidades JPA correspondentes
-- 3. Criar os endpoints da API REST
-- 4. Desenvolver o frontend React
-- 5. Implementar sistema de autenticação
-- 6. Adicionar testes automatizados

-- ============================================
-- 7. NOVAS TABELAS BASEADAS NA ANÁLISE COMPETITIVA
-- ============================================

-- Tabela: medical_records - Prontuários eletrônicos
-- Armazena informações médicas dos pacientes
CREATE TABLE medical_records (
    id BIGSERIAL PRIMARY KEY,
    client_id BIGINT REFERENCES clients(id),
    professional_id BIGINT REFERENCES users(id),
    appointment_id BIGINT REFERENCES appointments(id),
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    diagnosis TEXT,
    treatment_plan TEXT,
    observations TEXT,
    prescriptions JSONB, -- Medicamentos prescritos
    attachments JSONB, -- Anexos (imagens, documentos)
    vital_signs JSONB, -- Sinais vitais (pressão, temperatura, etc.)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints originais que foram removidos
    CONSTRAINT chk_medical_record_date 
        CHECK (record_date <= CURRENT_TIMESTAMP)
);

-- Tabela: telemedicine_sessions - Consultas online
-- Controla sessões de telemedicina
CREATE TABLE telemedicine_sessions (
    id BIGSERIAL PRIMARY KEY,
    appointment_id BIGINT REFERENCES appointments(id),
    meeting_url VARCHAR(500),
    meeting_id VARCHAR(100),
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    duration_minutes INTEGER,
    status VARCHAR(20) DEFAULT 'SCHEDULED', -- SCHEDULED, IN_PROGRESS, COMPLETED, CANCELLED
    recording_url VARCHAR(500),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints originais que foram removidos
    CONSTRAINT chk_telemedicine_duration 
        CHECK (duration_minutes >= 0),
    CONSTRAINT chk_telemedicine_status 
        CHECK (status IN ('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'))
);

-- Tabela: marketing_campaigns - Campanhas de marketing
-- Gerencia campanhas de marketing para clientes
CREATE TABLE marketing_campaigns (
    id BIGSERIAL PRIMARY KEY,
    clinic_id BIGINT REFERENCES clinics(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    campaign_type VARCHAR(50), -- EMAIL, SMS, WHATSAPP, SOCIAL_MEDIA
    target_audience VARCHAR(100), -- ALL_CLIENTS, NEW_CLIENTS, OVERDUE_CLIENTS, SPECIFIC_GROUP
    message TEXT NOT NULL,
    scheduled_date TIMESTAMP,
    sent_date TIMESTAMP,
    status VARCHAR(20) DEFAULT 'DRAFT', -- DRAFT, SCHEDULED, SENT, CANCELLED
    total_recipients INTEGER DEFAULT 0,
    total_sent INTEGER DEFAULT 0,
    total_opened INTEGER DEFAULT 0,
    total_clicked INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints originais que foram removidos
    CONSTRAINT chk_marketing_type 
        CHECK (campaign_type IN ('EMAIL', 'SMS', 'WHATSAPP', 'SOCIAL_MEDIA')),
    CONSTRAINT chk_marketing_status 
        CHECK (status IN ('DRAFT', 'SCHEDULED', 'SENT', 'CANCELLED')),
    CONSTRAINT chk_marketing_audience 
        CHECK (target_audience IN ('ALL_CLIENTS', 'NEW_CLIENTS', 'OVERDUE_CLIENTS', 'SPECIFIC_GROUP'))
);

-- Tabela: campaign_recipients - Destinatários das campanhas
-- Controla quem recebeu cada campanha
CREATE TABLE campaign_recipients (
    id BIGSERIAL PRIMARY KEY,
    campaign_id BIGINT REFERENCES marketing_campaigns(id),
    client_id BIGINT REFERENCES clients(id),
    sent_at TIMESTAMP,
    opened_at TIMESTAMP,
    clicked_at TIMESTAMP,
    status VARCHAR(20) DEFAULT 'SENT', -- SENT, OPENED, CLICKED, BOUNCED, UNSUBSCRIBED
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints originais que foram removidos
    CONSTRAINT chk_campaign_recipient_status 
        CHECK (status IN ('SENT', 'OPENED', 'CLICKED', 'BOUNCED', 'UNSUBSCRIBED'))
);

-- Tabela: inventory - Controle de estoque
-- Gerencia estoque de produtos e materiais
CREATE TABLE inventory (
    id BIGSERIAL PRIMARY KEY,
    clinic_id BIGINT REFERENCES clinics(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100), -- MEDICINE, EQUIPMENT, SUPPLIES, etc.
    sku VARCHAR(100), -- Código do produto
    current_stock INTEGER DEFAULT 0,
    minimum_stock INTEGER DEFAULT 0,
    maximum_stock INTEGER DEFAULT 0,
    unit_price DECIMAL(10,2),
    supplier VARCHAR(255),
    expiry_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    
    -- Constraints originais que foram removidos
    CONSTRAINT chk_inventory_stock 
        CHECK (current_stock >= 0 AND minimum_stock >= 0 AND maximum_stock >= 0),
    CONSTRAINT chk_inventory_category 
        CHECK (category IN ('MEDICINE', 'EQUIPMENT', 'SUPPLIES', 'OTHER'))
);

-- Tabela: inventory_movements - Movimentações de estoque
-- Registra entradas e saídas do estoque
CREATE TABLE inventory_movements (
    id BIGSERIAL PRIMARY KEY,
    inventory_id BIGINT REFERENCES inventory(id),
    movement_type VARCHAR(20) NOT NULL, -- IN, OUT, ADJUSTMENT
    quantity INTEGER NOT NULL,
    reason VARCHAR(255),
    reference_id BIGINT, -- ID de referência (compra, venda, etc.)
    reference_type VARCHAR(50), -- PURCHASE, SALE, ADJUSTMENT, etc.
    user_id BIGINT REFERENCES users(id),
    movement_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    
    -- Constraints originais que foram removidos
    CONSTRAINT chk_inventory_movement_type 
        CHECK (movement_type IN ('IN', 'OUT', 'ADJUSTMENT')),
    CONSTRAINT chk_inventory_movement_quantity 
        CHECK (quantity != 0)
);

-- ============================================
-- 8. ÍNDICES PARA NOVAS TABELAS
-- ============================================

-- Índices para medical_records
CREATE INDEX idx_medical_records_client ON medical_records(client_id);
CREATE INDEX idx_medical_records_professional ON medical_records(professional_id);
CREATE INDEX idx_medical_records_appointment ON medical_records(appointment_id);
CREATE INDEX idx_medical_records_date ON medical_records(record_date);

-- Índices para telemedicine_sessions
CREATE INDEX idx_telemedicine_appointment ON telemedicine_sessions(appointment_id);
CREATE INDEX idx_telemedicine_status ON telemedicine_sessions(status);
CREATE INDEX idx_telemedicine_start_time ON telemedicine_sessions(start_time);

-- Índices para marketing_campaigns
CREATE INDEX idx_marketing_clinic ON marketing_campaigns(clinic_id);
CREATE INDEX idx_marketing_type ON marketing_campaigns(campaign_type);
CREATE INDEX idx_marketing_status ON marketing_campaigns(status);
CREATE INDEX idx_marketing_scheduled ON marketing_campaigns(scheduled_date);

-- Índices para campaign_recipients
CREATE INDEX idx_campaign_recipients_campaign ON campaign_recipients(campaign_id);
CREATE INDEX idx_campaign_recipients_client ON campaign_recipients(client_id);
CREATE INDEX idx_campaign_recipients_status ON campaign_recipients(status);

-- Índices para inventory
CREATE INDEX idx_inventory_clinic ON inventory(clinic_id);
CREATE INDEX idx_inventory_category ON inventory(category);
CREATE INDEX idx_inventory_status ON inventory(status);
CREATE INDEX idx_inventory_sku ON inventory(sku);

-- Índices para inventory_movements
CREATE INDEX idx_inventory_movements_inventory ON inventory_movements(inventory_id);
CREATE INDEX idx_inventory_movements_type ON inventory_movements(movement_type);
CREATE INDEX idx_inventory_movements_date ON inventory_movements(movement_date);
CREATE INDEX idx_inventory_movements_user ON inventory_movements(user_id);


-- ============================================
-- 10. VIEWS PARA NOVAS FUNCIONALIDADES
-- ============================================

-- View: Prontuários por cliente
CREATE VIEW v_client_medical_records AS
SELECT 
    mr.id,
    mr.record_date,
    c.name as client_name,
    u.name as professional_name,
    st.name as service_name,
    mr.diagnosis,
    mr.treatment_plan,
    mr.observations
FROM medical_records mr
JOIN clients c ON mr.client_id = c.id
JOIN users u ON mr.professional_id = u.id
JOIN appointments a ON mr.appointment_id = a.id
JOIN service_types st ON a.service_type_id = st.id
WHERE c.status = 'ACTIVE'
ORDER BY mr.record_date DESC;

-- View: Sessões de telemedicina
CREATE VIEW v_telemedicine_sessions AS
SELECT 
    ts.id,
    ts.start_time,
    ts.end_time,
    ts.duration_minutes,
    c.name as client_name,
    u.name as professional_name,
    st.name as service_name,
    ts.status,
    ts.meeting_url
FROM telemedicine_sessions ts
JOIN appointments a ON ts.appointment_id = a.id
JOIN clients c ON a.client_id = c.id
JOIN users u ON a.professional_id = u.id
JOIN service_types st ON a.service_type_id = st.id
WHERE ts.status IN ('SCHEDULED', 'IN_PROGRESS', 'COMPLETED')
ORDER BY ts.start_time DESC;

-- View: Campanhas de marketing
CREATE VIEW v_marketing_campaigns AS
SELECT 
    mc.id,
    mc.name,
    mc.campaign_type,
    mc.target_audience,
    mc.scheduled_date,
    mc.sent_date,
    mc.status,
    mc.total_recipients,
    mc.total_sent,
    mc.total_opened,
    mc.total_clicked,
    CASE 
        WHEN mc.total_sent > 0 THEN ROUND((mc.total_opened::DECIMAL / mc.total_sent) * 100, 2)
        ELSE 0 
    END as open_rate,
    CASE 
        WHEN mc.total_opened > 0 THEN ROUND((mc.total_clicked::DECIMAL / mc.total_opened) * 100, 2)
        ELSE 0 
    END as click_rate
FROM marketing_campaigns mc
WHERE mc.status IN ('SCHEDULED', 'SENT')
ORDER BY mc.scheduled_date DESC;

-- View: Estoque com baixo nível
CREATE VIEW v_low_stock_inventory AS
SELECT 
    i.id,
    i.name,
    i.category,
    i.current_stock,
    i.minimum_stock,
    i.maximum_stock,
    i.unit_price,
    (i.minimum_stock - i.current_stock) as shortage_quantity,
    CASE 
        WHEN i.current_stock <= 0 THEN 'OUT_OF_STOCK'
        WHEN i.current_stock <= i.minimum_stock THEN 'LOW_STOCK'
        ELSE 'OK'
    END as stock_status
FROM inventory i
WHERE i.current_stock <= i.minimum_stock
    AND i.status = 'ACTIVE'
ORDER BY shortage_quantity DESC;

-- ============================================
-- 11. DADOS INICIAIS PARA NOVAS TABELAS
-- ============================================

-- Inserir categorias de estoque
INSERT INTO inventory (clinic_id, name, description, category, sku, current_stock, minimum_stock, maximum_stock, unit_price, supplier)
VALUES 
(1, 'Gaze Estéril', 'Gaze estéril 10x10cm', 'SUPPLIES', 'GAZE-001', 50, 10, 100, 2.50, 'Fornecedor A'),
(1, 'Algodão', 'Algodão hidrófilo 500g', 'SUPPLIES', 'ALG-001', 20, 5, 50, 15.00, 'Fornecedor B'),
(1, 'Termômetro Digital', 'Termômetro digital infravermelho', 'EQUIPMENT', 'TERM-001', 3, 1, 5, 89.90, 'Fornecedor C');

-- Inserir configurações de marketing
INSERT INTO settings (clinic_id, setting_key, setting_value, setting_type)
VALUES 
(1, 'marketing_email_enabled', 'true', 'BOOLEAN'),
(1, 'marketing_sms_enabled', 'true', 'BOOLEAN'),
(1, 'marketing_whatsapp_enabled', 'true', 'BOOLEAN'),
(1, 'marketing_reminder_days', '3', 'NUMBER'),
(1, 'marketing_promotion_days', '7', 'NUMBER');

-- ============================================
-- 12. SISTEMA DE PERMISSÕES E SEGURANÇA
-- ============================================

-- Tabela: permissions - Permissões do sistema
-- Define todas as permissões disponíveis no sistema
CREATE TABLE permissions (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE, -- 'CREATE_APPOINTMENT', 'VIEW_REPORTS', etc.
    description TEXT,
    module VARCHAR(50) NOT NULL, -- 'APPOINTMENTS', 'CLASSES', 'REPORTS', 'CLIENTS', etc.
    action VARCHAR(50) NOT NULL, -- 'CREATE', 'READ', 'UPDATE', 'DELETE', 'EXECUTE'
    resource VARCHAR(50) NOT NULL, -- 'APPOINTMENT', 'CLASS', 'CLIENT', 'REPORT', etc.
    is_system_permission BOOLEAN DEFAULT TRUE, -- Permissões do sistema vs customizadas
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    
    -- Constraints originais que foram removidos
    CONSTRAINT chk_permission_action 
        CHECK (action IN ('CREATE', 'READ', 'UPDATE', 'DELETE', 'EXECUTE', 'EXPORT', 'IMPORT')),
    CONSTRAINT chk_permission_module 
        CHECK (module IN ('APPOINTMENTS', 'CLASSES', 'CLIENTS', 'REPORTS', 'USERS', 'SETTINGS', 'INVENTORY', 'MARKETING', 'TELEMEDICINE', 'MEDICAL_RECORDS'))
);


-- Tabela: role_permissions - Permissões por role
-- Relaciona roles com suas permissões
CREATE TABLE role_permissions (
    id BIGSERIAL PRIMARY KEY,
    role_id BIGINT REFERENCES roles(id),
    permission_id BIGINT REFERENCES permissions(id),
    granted BOOLEAN DEFAULT TRUE, -- TRUE = permissão concedida, FALSE = permissão negada
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(role_id, permission_id),
    
    -- Constraints originais que foram removidos
    CONSTRAINT chk_role_permission_granted 
        CHECK (granted IN (TRUE, FALSE))
);

-- Tabela: user_permissions - Permissões específicas por usuário
-- Permite conceder/negar permissões específicas a usuários individuais
CREATE TABLE user_permissions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    permission_id BIGINT REFERENCES permissions(id),
    granted BOOLEAN DEFAULT TRUE, -- TRUE = permissão concedida, FALSE = permissão negada
    granted_by BIGINT REFERENCES users(id), -- Quem concedeu a permissão
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP, -- Data de expiração da permissão (NULL = permanente)
    reason TEXT, -- Motivo da concessão/negação
    UNIQUE(user_id, permission_id),
    
    -- Constraints originais que foram removidos
    CONSTRAINT chk_user_permission_granted 
        CHECK (granted IN (TRUE, FALSE)),
    CONSTRAINT chk_user_permission_expires 
        CHECK (expires_at IS NULL OR expires_at > granted_at)
);

-- Tabela: access_logs - Logs de acesso e ações
-- Registra todas as ações dos usuários no sistema
CREATE TABLE access_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    clinic_id BIGINT REFERENCES clinics(id),
    action VARCHAR(100) NOT NULL, -- 'LOGIN', 'LOGOUT', 'CREATE_APPOINTMENT', 'UPDATE_CLIENT', etc.
    resource_type VARCHAR(50), -- 'APPOINTMENT', 'CLASS', 'CLIENT', 'USER', etc.
    resource_id BIGINT, -- ID do recurso afetado
    old_values JSONB, -- Valores anteriores (para updates)
    new_values JSONB, -- Novos valores (para creates/updates)
    ip_address VARCHAR(45), -- IP do usuário
    user_agent TEXT, -- User agent do navegador
    session_id VARCHAR(255), -- ID da sessão
    success BOOLEAN DEFAULT TRUE, -- Se a ação foi bem-sucedida
    error_message TEXT, -- Mensagem de erro (se houver)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints originais que foram removidos
    CONSTRAINT chk_access_log_success 
        CHECK (success IN (TRUE, FALSE))
);

-- Tabela: user_sessions - Controle de sessões
-- Gerencia sessões ativas dos usuários
CREATE TABLE user_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    clinic_id BIGINT REFERENCES clinics(id),
    session_id VARCHAR(255) UNIQUE NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    logout_time TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints originais que foram removidos
    CONSTRAINT chk_user_session_expires 
        CHECK (expires_at > login_time),
    CONSTRAINT chk_user_session_active 
        CHECK (is_active IN (TRUE, FALSE))
);

-- Tabela: security_settings - Configurações de segurança
-- Configurações de segurança específicas por clínica
CREATE TABLE security_settings (
    id BIGSERIAL PRIMARY KEY,
    clinic_id BIGINT REFERENCES clinics(id),
    setting_key VARCHAR(100) NOT NULL,
    setting_value TEXT,
    setting_type VARCHAR(20) DEFAULT 'STRING', -- STRING, NUMBER, BOOLEAN, JSON
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(clinic_id, setting_key)
);

-- Tabela: failed_login_attempts - Tentativas de login falhadas
-- Controla tentativas de login para prevenção de ataques
CREATE TABLE failed_login_attempts (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45),
    attempt_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_agent TEXT,
    reason VARCHAR(100), -- 'INVALID_PASSWORD', 'USER_NOT_FOUND', 'ACCOUNT_LOCKED', etc.
    clinic_id BIGINT REFERENCES clinics(id),
    
    -- Constraints originais que foram removidos
    CONSTRAINT chk_failed_login_reason 
        CHECK (reason IN ('INVALID_PASSWORD', 'USER_NOT_FOUND', 'ACCOUNT_LOCKED', 'ACCOUNT_INACTIVE', 'INVALID_EMAIL', 'TOO_MANY_ATTEMPTS'))
);

-- ============================================
-- 13. ÍNDICES PARA SISTEMA DE SEGURANÇA
-- ============================================

-- Índices para permissions
CREATE INDEX idx_permissions_module ON permissions(module);
CREATE INDEX idx_permissions_action ON permissions(action);
CREATE INDEX idx_permissions_resource ON permissions(resource);
CREATE INDEX idx_permissions_status ON permissions(status);


-- Índices para role_permissions
CREATE INDEX idx_role_permissions_role ON role_permissions(role_id);
CREATE INDEX idx_role_permissions_permission ON role_permissions(permission_id);
CREATE INDEX idx_role_permissions_granted ON role_permissions(granted);

-- Índices para user_permissions
CREATE INDEX idx_user_permissions_user ON user_permissions(user_id);
CREATE INDEX idx_user_permissions_permission ON user_permissions(permission_id);
CREATE INDEX idx_user_permissions_granted ON user_permissions(granted);
CREATE INDEX idx_user_permissions_expires ON user_permissions(expires_at);

-- Índices para access_logs
CREATE INDEX idx_access_logs_user ON access_logs(user_id);
CREATE INDEX idx_access_logs_clinic ON access_logs(clinic_id);
CREATE INDEX idx_access_logs_action ON access_logs(action);
CREATE INDEX idx_access_logs_resource ON access_logs(resource_type, resource_id);
CREATE INDEX idx_access_logs_created ON access_logs(created_at);
CREATE INDEX idx_access_logs_success ON access_logs(success);

-- Índices para user_sessions
CREATE INDEX idx_user_sessions_user ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_clinic ON user_sessions(clinic_id);
CREATE INDEX idx_user_sessions_active ON user_sessions(is_active);
CREATE INDEX idx_user_sessions_expires ON user_sessions(expires_at);
CREATE INDEX idx_user_sessions_last_activity ON user_sessions(last_activity);

-- Índices para security_settings
CREATE INDEX idx_security_settings_clinic ON security_settings(clinic_id);
CREATE INDEX idx_security_settings_key ON security_settings(setting_key);

-- Índices para failed_login_attempts
CREATE INDEX idx_failed_login_email ON failed_login_attempts(email);
CREATE INDEX idx_failed_login_ip ON failed_login_attempts(ip_address);
CREATE INDEX idx_failed_login_time ON failed_login_attempts(attempt_time);
CREATE INDEX idx_failed_login_clinic ON failed_login_attempts(clinic_id);

-- Índices para novas tabelas de melhorias
-- Índices para reminders
CREATE INDEX idx_reminders_clinic ON reminders(clinic_id);
CREATE INDEX idx_reminders_type ON reminders(reminder_type);
CREATE INDEX idx_reminders_status ON reminders(status);
CREATE INDEX idx_reminders_scheduled ON reminders(scheduled_time);
CREATE INDEX idx_reminders_client ON reminders(client_id);
CREATE INDEX idx_reminders_appointment ON reminders(appointment_id);
CREATE INDEX idx_reminders_class ON reminders(class_id);

-- Índices para notification_preferences
CREATE INDEX idx_notification_preferences_clinic ON notification_preferences(clinic_id);
CREATE INDEX idx_notification_preferences_user ON notification_preferences(user_id);
CREATE INDEX idx_notification_preferences_client ON notification_preferences(client_id);
CREATE INDEX idx_notification_preferences_type ON notification_preferences(notification_type);

-- Índices para integrations
CREATE INDEX idx_integrations_clinic ON integrations(clinic_id);
CREATE INDEX idx_integrations_type ON integrations(integration_type);
CREATE INDEX idx_integrations_active ON integrations(is_active);
CREATE INDEX idx_integrations_status ON integrations(sync_status);

-- Índices para client_notes
CREATE INDEX idx_client_notes_client ON client_notes(client_id);
CREATE INDEX idx_client_notes_user ON client_notes(user_id);
CREATE INDEX idx_client_notes_type ON client_notes(note_type);
CREATE INDEX idx_client_notes_important ON client_notes(is_important);
CREATE INDEX idx_client_notes_private ON client_notes(is_private);

-- Índices para appointment_feedback
CREATE INDEX idx_appointment_feedback_appointment ON appointment_feedback(appointment_id);
CREATE INDEX idx_appointment_feedback_client ON appointment_feedback(client_id);
CREATE INDEX idx_appointment_feedback_professional ON appointment_feedback(professional_id);
CREATE INDEX idx_appointment_feedback_rating ON appointment_feedback(overall_rating);

-- Índices para class_feedback
CREATE INDEX idx_class_feedback_class ON class_feedback(class_id);
CREATE INDEX idx_class_feedback_client ON class_feedback(client_id);
CREATE INDEX idx_class_feedback_instructor ON class_feedback(instructor_id);
CREATE INDEX idx_class_feedback_rating ON class_feedback(overall_rating);

-- Índices para system_logs
CREATE INDEX idx_system_logs_clinic ON system_logs(clinic_id);
CREATE INDEX idx_system_logs_user ON system_logs(user_id);
CREATE INDEX idx_system_logs_level ON system_logs(log_level);
CREATE INDEX idx_system_logs_category ON system_logs(category);
CREATE INDEX idx_system_logs_created ON system_logs(created_at);

-- ============================================
-- 14. CONSTRAINTS PARA SISTEMA DE SEGURANÇA
-- ============================================



-- ============================================
-- 15. VIEWS PARA CONTROLE DE ACESSO
-- ============================================

-- View: Permissões do usuário
CREATE VIEW v_user_permissions AS
SELECT DISTINCT
    u.id as user_id,
    u.name as user_name,
    u.email,
    u.clinic_id,
    p.id as permission_id,
    p.name as permission_name,
    p.module,
    p.action,
    p.resource,
    COALESCE(up.granted, rp.granted, FALSE) as granted,
    CASE 
        WHEN up.id IS NOT NULL THEN 'USER_SPECIFIC'
        WHEN rp.id IS NOT NULL THEN 'ROLE_BASED'
        ELSE 'NONE'
    END as permission_source
FROM users u
LEFT JOIN user_permissions up ON u.id = up.user_id AND up.granted = TRUE
LEFT JOIN role_permissions rp ON u.role_id = rp.role_id AND rp.granted = TRUE
LEFT JOIN permissions p ON (up.permission_id = p.id OR rp.permission_id = p.id)
WHERE u.status = 'ACTIVE'
    AND (up.expires_at IS NULL OR up.expires_at > CURRENT_TIMESTAMP)
    AND p.status = 'ACTIVE';

-- View: Usuários ativos com suas permissões
CREATE VIEW v_active_users_permissions AS
SELECT 
    u.id as user_id,
    u.name as user_name,
    u.email,
    u.role,
    c.name as clinic_name,
    r.name as role_name,
    COUNT(DISTINCT p.id) as total_permissions,
    COUNT(DISTINCT CASE WHEN vp.granted = TRUE THEN p.id END) as granted_permissions
FROM users u
JOIN clinics c ON u.clinic_id = c.id
LEFT JOIN roles r ON u.role_id = r.id
LEFT JOIN v_user_permissions vp ON u.id = vp.user_id
LEFT JOIN permissions p ON vp.permission_id = p.id
WHERE u.status = 'ACTIVE'
GROUP BY u.id, u.name, u.email, u.role, c.name, r.name;

-- View: Logs de acesso recentes
CREATE VIEW v_recent_access_logs AS
SELECT 
    al.id,
    al.created_at,
    u.name as user_name,
    c.name as clinic_name,
    al.action,
    al.resource_type,
    al.resource_id,
    al.success,
    al.ip_address,
    al.error_message
FROM access_logs al
JOIN users u ON al.user_id = u.id
JOIN clinics c ON al.clinic_id = c.id
WHERE al.created_at >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY al.created_at DESC;

-- View: Sessões ativas
CREATE VIEW v_active_sessions AS
SELECT 
    us.id,
    us.session_id,
    u.name as user_name,
    c.name as clinic_name,
    us.login_time,
    us.last_activity,
    us.ip_address,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - us.last_activity))/60 as minutes_inactive
FROM user_sessions us
JOIN users u ON us.user_id = u.id
JOIN clinics c ON us.clinic_id = c.id
WHERE us.is_active = TRUE
    AND us.expires_at > CURRENT_TIMESTAMP
ORDER BY us.last_activity DESC;

-- View: Tentativas de login falhadas recentes
CREATE VIEW v_recent_failed_logins AS
SELECT 
    fla.email,
    fla.ip_address,
    fla.attempt_time,
    fla.reason,
    c.name as clinic_name,
    COUNT(*) as attempt_count
FROM failed_login_attempts fla
LEFT JOIN clinics c ON fla.clinic_id = c.id
WHERE fla.attempt_time >= CURRENT_DATE - INTERVAL '24 hours'
GROUP BY fla.email, fla.ip_address, fla.attempt_time, fla.reason, c.name
ORDER BY fla.attempt_time DESC;

-- ============================================
-- 16. DADOS INICIAIS PARA SISTEMA DE SEGURANÇA
-- ============================================

-- Inserir permissões básicas do sistema
INSERT INTO permissions (name, description, module, action, resource) VALUES
-- Permissões de Clientes
('CREATE_CLIENT', 'Criar novos clientes', 'CLIENTS', 'CREATE', 'CLIENT'),
('READ_CLIENT', 'Visualizar clientes', 'CLIENTS', 'READ', 'CLIENT'),
('UPDATE_CLIENT', 'Editar clientes', 'CLIENTS', 'UPDATE', 'CLIENT'),
('DELETE_CLIENT', 'Excluir clientes', 'CLIENTS', 'DELETE', 'CLIENT'),

-- Permissões de Agendamentos
('CREATE_APPOINTMENT', 'Criar agendamentos', 'APPOINTMENTS', 'CREATE', 'APPOINTMENT'),
('READ_APPOINTMENT', 'Visualizar agendamentos', 'APPOINTMENTS', 'READ', 'APPOINTMENT'),
('UPDATE_APPOINTMENT', 'Editar agendamentos', 'APPOINTMENTS', 'UPDATE', 'APPOINTMENT'),
('DELETE_APPOINTMENT', 'Excluir agendamentos', 'APPOINTMENTS', 'DELETE', 'APPOINTMENT'),

-- Permissões de Aulas
('CREATE_CLASS', 'Criar aulas', 'CLASSES', 'CREATE', 'CLASS'),
('READ_CLASS', 'Visualizar aulas', 'CLASSES', 'READ', 'CLASS'),
('UPDATE_CLASS', 'Editar aulas', 'CLASSES', 'UPDATE', 'CLASS'),
('DELETE_CLASS', 'Excluir aulas', 'CLASSES', 'DELETE', 'CLASS'),

-- Permissões de Relatórios
('VIEW_REPORTS', 'Visualizar relatórios', 'REPORTS', 'READ', 'REPORT'),
('EXPORT_REPORTS', 'Exportar relatórios', 'REPORTS', 'EXPORT', 'REPORT'),

-- Permissões de Usuários
('MANAGE_USERS', 'Gerenciar usuários', 'USERS', 'CREATE', 'USER'),
('VIEW_USERS', 'Visualizar usuários', 'USERS', 'READ', 'USER'),

-- Permissões de Configurações
('MANAGE_SETTINGS', 'Gerenciar configurações', 'SETTINGS', 'UPDATE', 'SETTING'),
('VIEW_SETTINGS', 'Visualizar configurações', 'SETTINGS', 'READ', 'SETTING'),

-- Permissões de Pagamentos
('VIEW_PAYMENTS', 'Visualizar pagamentos', 'PAYMENTS', 'READ', 'PAYMENT'),
('MANAGE_PAYMENTS', 'Gerenciar pagamentos', 'PAYMENTS', 'UPDATE', 'PAYMENT'),

-- Permissões de Prontuários
('CREATE_MEDICAL_RECORD', 'Criar prontuários', 'MEDICAL_RECORDS', 'CREATE', 'MEDICAL_RECORD'),
('READ_MEDICAL_RECORD', 'Visualizar prontuários', 'MEDICAL_RECORDS', 'READ', 'MEDICAL_RECORD'),
('UPDATE_MEDICAL_RECORD', 'Editar prontuários', 'MEDICAL_RECORDS', 'UPDATE', 'MEDICAL_RECORD');

-- Inserir permissões para roles do sistema
-- Administrador - todas as permissões
INSERT INTO role_permissions (role_id, permission_id, granted)
SELECT r.id, p.id, TRUE
FROM roles r, permissions p
WHERE r.name = 'Administrador' AND r.clinic_id = 1;

-- Gerente - quase todas as permissões (exceto gerenciar usuários)
INSERT INTO role_permissions (role_id, permission_id, granted)
SELECT r.id, p.id, TRUE
FROM roles r, permissions p
WHERE r.name = 'Gerente' AND r.clinic_id = 1
    AND p.name != 'MANAGE_USERS';

-- Recepcionista - permissões básicas
INSERT INTO role_permissions (role_id, permission_id, granted)
SELECT r.id, p.id, TRUE
FROM roles r, permissions p
WHERE r.name = 'Recepcionista' AND r.clinic_id = 1
    AND p.name IN ('CREATE_CLIENT', 'READ_CLIENT', 'UPDATE_CLIENT', 'CREATE_APPOINTMENT', 'READ_APPOINTMENT', 'UPDATE_APPOINTMENT', 'CREATE_CLASS', 'READ_CLASS', 'UPDATE_CLASS', 'VIEW_REPORTS');

-- Profissionais - permissões limitadas
INSERT INTO role_permissions (role_id, permission_id, granted)
SELECT r.id, p.id, TRUE
FROM roles r, permissions p
WHERE r.name IN ('Fisioterapeuta', 'Nutricionista', 'Psicólogo') AND r.clinic_id = 1
    AND p.name IN ('READ_CLIENT', 'READ_APPOINTMENT', 'UPDATE_APPOINTMENT', 'READ_CLASS', 'UPDATE_CLASS', 'CREATE_MEDICAL_RECORD', 'READ_MEDICAL_RECORD', 'UPDATE_MEDICAL_RECORD', 'VIEW_PAYMENTS');

-- Inserir configurações de segurança padrão
INSERT INTO security_settings (clinic_id, setting_key, setting_value, setting_type, description) VALUES
(1, 'max_login_attempts', '5', 'NUMBER', 'Máximo de tentativas de login'),
(1, 'lockout_duration_minutes', '30', 'NUMBER', 'Duração do bloqueio em minutos'),
(1, 'session_timeout_minutes', '480', 'NUMBER', 'Timeout da sessão em minutos'),
(1, 'password_min_length', '8', 'NUMBER', 'Tamanho mínimo da senha'),
(1, 'require_strong_password', 'true', 'BOOLEAN', 'Exigir senha forte'),
(1, 'enable_two_factor', 'false', 'BOOLEAN', 'Habilitar autenticação de dois fatores'),
(1, 'audit_log_retention_days', '365', 'NUMBER', 'Dias para retenção de logs'),
(1, 'enable_ip_whitelist', 'false', 'BOOLEAN', 'Habilitar lista branca de IPs');

-- ============================================
-- FIM DO SCRIPT
-- ============================================
