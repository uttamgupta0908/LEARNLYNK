-- Seed data for testing
-- Run this in Supabase SQL Editor

-- 1. Insert a Lead
INSERT INTO leads (id, tenant_id, stage, owner_id)
VALUES 
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'new', 'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380a44');

-- 2. Insert an Application linked to the Lead
INSERT INTO applications (id, tenant_id, lead_id)
VALUES 
    ('c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11');

-- 3. Insert Tasks linked to the Application (using related_id)
INSERT INTO tasks (tenant_id, related_id, type, due_at, status)
VALUES 
    -- Task due today (should show up in dashboard)
    ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'call', NOW() + INTERVAL '1 hour', 'pending'),
    
    -- Task due tomorrow (should NOT show up)
    ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'email', NOW() + INTERVAL '1 day', 'pending'),

    -- Task completed (should NOT show up)
    ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 'review', NOW() - INTERVAL '1 hour', 'completed');
