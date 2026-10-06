-- 001_app_role.sql
-- Ensure standard roles exist in PostgreSQL roles table
INSERT INTO public.roles (id, role_name, description)
VALUES
    (1, 'ADMIN', 'Platform administrator (SUPER_ADMIN, OPS_ADMIN, FINANCE_ADMIN)'),
    (2, 'MANAGER', 'Turf / Club Manager'),
    (3, 'PLAYER', 'Regular football player account')
ON CONFLICT (id) DO UPDATE SET
    role_name = EXCLUDED.role_name,
    description = EXCLUDED.description;
