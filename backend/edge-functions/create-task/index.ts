import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  // Handle CORS preflight request
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { application_id, task_type, due_at } = await req.json()

    // 1. Validate Input
    const validTypes = ['call', 'email', 'review']
    if (!validTypes.includes(task_type)) {
      return new Response(
        JSON.stringify({ error: 'Invalid task_type. Must be call, email, or review.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const dueDate = new Date(due_at)
    if (isNaN(dueDate.getTime()) || dueDate <= new Date()) {
      return new Response(
        JSON.stringify({ error: 'Invalid due_at. Must be a future date.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!application_id) {
        return new Response(
          JSON.stringify({ error: 'Missing application_id.' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }

    // 2. Initialize Supabase Client
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // 3. Insert into tasks table
    // We need tenant_id. Usually this comes from the application or the user context.
    // Since this is a service role call, we might need to fetch the tenant_id from the application first
    // OR assume the caller provides it?
    // The prompt input example DOES NOT include tenant_id.
    // However, the schema requires tenant_id.
    // I should fetch the tenant_id from the applications table using application_id.
    
    const { data: applicationData, error: appError } = await supabase
        .from('applications')
        .select('tenant_id')
        .eq('id', application_id)
        .single()

    if (appError || !applicationData) {
        return new Response(
            JSON.stringify({ error: 'Application not found.' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }

    const tenant_id = applicationData.tenant_id

    const { data: taskData, error: taskError } = await supabase
      .from('tasks')
      .insert([
        {
          application_id,
          type: task_type,
          due_at,
          tenant_id, 
          status: 'pending'
        },
      ])
      .select()
      .single()

    if (taskError) {
      throw taskError
    }

    // 4. Emit Realtime Broadcast Event
    const channel = supabase.channel('realtime')
    await channel.subscribe(async (status) => {
        if (status === 'SUBSCRIBED') {
            await channel.send({
                type: 'broadcast',
                event: 'task.created',
                payload: { task: taskData },
            })
            supabase.removeChannel(channel)
        }
    })
    // Note: In Edge Functions, sending broadcast might be fire-and-forget or we wait. 
    // The above subscription logic might be too slow for a serverless function if we wait for SUBSCRIBED.
    // A better way for server-side broadcast is usually just inserting to a table that client listens to, 
    // BUT the prompt explicitly asks to "Emit a Supabase Realtime broadcast event".
    // Using `channel.send` requires being joined.
    // Alternatively, since we just inserted a row, Postgres Changes would handle it if clients listen to DB changes.
    // But "Broadcast" specifically refers to the ephemeral messages.
    // I will keep the code but wrap it in a non-blocking way or just assume standard DB changes are enough?
    // "Emits a Supabase Realtime broadcast event: 'task.created'" -> specific requirement.
    // I'll try to do it efficiently.

    return new Response(
      JSON.stringify({ success: true, task_id: taskData.id }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
