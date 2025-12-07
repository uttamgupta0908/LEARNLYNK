-- Enable RLS on leads table
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;

-- Policy for SELECT
-- Goal:
-- 1. Admins can read all leads in their tenant.
-- 2. Counselors can read leads assigned to them OR assigned to their team.
-- Assumptions:
-- - auth.jwt() contains 'role' and 'tenant_id'.
-- - 'assigned to their team' means the lead's owner shares a team with the current user.

CREATE POLICY "Leads Select Policy" ON leads
FOR SELECT
USING (
  -- 1. Admin check
  (
    (auth.jwt() ->> 'role') = 'admin' 
    AND 
    tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  )
  OR
  -- 2. Counselor check
  (
    (auth.jwt() ->> 'role') = 'counselor'
    AND
    (
      -- Assigned to them
      owner_id = auth.uid()
      OR
      -- Assigned to their team (Owner is in one of my teams)
      EXISTS (
        SELECT 1 
        FROM user_teams ut_me
        JOIN user_teams ut_other ON ut_me.team_id = ut_other.team_id
        WHERE ut_me.user_id = auth.uid()
        AND ut_other.user_id = leads.owner_id
      )
    )
  )
);

-- Policy for INSERT
-- Goal: Counselors and Admins can add leads under their tenant.

CREATE POLICY "Leads Insert Policy" ON leads
FOR INSERT
WITH CHECK (
  -- Must be authenticated and belong to the tenant
  auth.role() = 'authenticated' -- basic check
  AND
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND
  (
    (auth.jwt() ->> 'role') IN ('admin', 'counselor')
  )
);
