-- These tables are required for the RLS policies to work.
-- The prompt asked to "assume" their existence, but we must create them to run the code.

CREATE TABLE IF NOT EXISTS teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL
);

CREATE TABLE IF NOT EXISTS user_teams (
    user_id UUID NOT NULL, -- References auth.users(id)
    team_id UUID NOT NULL REFERENCES teams(id),
    PRIMARY KEY (user_id, team_id)
);

-- Insert some dummy data for testing
-- INSERT INTO teams (id, tenant_id) VALUES ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22');
-- INSERT INTO user_teams (user_id, team_id) VALUES ('your-user-id', 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22');
