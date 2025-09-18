import { serve } from "https://deno.land/std@0.200.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.7";
import { Pool } from "https://deno.land/x/postgres@v0.17.0/mod.ts";

type Json = Record<string, unknown> | Array<unknown> | string | number | boolean | null;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const databaseUrl = Deno.env.get("SUPABASE_DB_URL");
const fcmKey = Deno.env.get("FCM_SERVER_KEY");
const reminderHours = Number(Deno.env.get("RATING_REMINDER_HOURS") ?? 1);

const supabase = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false } });
const pool = databaseUrl ? new Pool(databaseUrl, 3, true) : null;

interface ReminderRow {
  appointment_id: string;
  customer_id: string;
  business_id: string;
  scheduled_at: string;
  duration_minutes: number;
  customer_name: string | null;
  customer_fcm: string | null;
  business_name: string;
}

function respond(status: number, body: Json) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders,
    },
  });
}

async function sendFcm(to: string, title: string, body: string, data: Record<string, string>) {
  if (!fcmKey) {
    console.warn("FCM_SERVER_KEY tanımlı değil, push gönderilmedi");
    return;
  }

  await fetch("https://fcm.googleapis.com/fcm/send", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `key=${fcmKey}`,
    },
    body: JSON.stringify({
      to,
      notification: { title, body },
      data,
    }),
  });
}

async function handleRequest(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (!pool) {
    return respond(500, { error: "Database connection is not configured" });
  }

  const limitParam = Number(new URL(req.url).searchParams.get("limit") ?? 20);
  const limit = Number.isNaN(limitParam) ? 20 : Math.min(limitParam, 100);

  const connection = await pool.connect();
  const reminders: ReminderRow[] = [];
  try {
    await connection.queryArray`begin`;

    const reminderResult = await connection.queryObject<ReminderRow>`
      select a.id as appointment_id,
             a.customer_id,
             a.business_id,
             a.scheduled_at,
             a.duration_minutes,
             customer.full_name as customer_name,
             customer.fcm_token as customer_fcm,
             b.name as business_name
      from public.appointments a
        join public.businesses b on b.id = a.business_id
        join public.profiles customer on customer.id = a.customer_id
      where a.status = 'completed'
        and a.deleted_at is null
        and a.scheduled_at + make_interval(mins => coalesce(a.duration_minutes, 0)) <= timezone('utc', now()) - (${reminderHours} || ' hour')::interval
        and not exists (
          select 1 from public.notifications n
          where n.profile_id = a.customer_id
            and n.type = 'rating_reminder'
            and n.payload ->> 'appointment_id' = a.id::text
        )
      order by a.scheduled_at asc
      limit ${limit}
      for update
    `;

    reminders.push(...reminderResult.rows);

    for (const reminder of reminders) {
      await connection.queryArray`
        insert into public.notifications (profile_id, type, payload)
        values (${reminder.customer_id}::uuid, 'rating_reminder', ${
        JSON.stringify({
          appointment_id: reminder.appointment_id,
          business_id: reminder.business_id,
          scheduled_at: reminder.scheduled_at,
        })
      }::jsonb)
      `;

      await connection.queryArray`
        insert into public.audit_logs (actor_id, business_id, action, metadata)
        values (null, ${reminder.business_id}::uuid, 'rating_reminder_sent', ${
        JSON.stringify({ appointment_id: reminder.appointment_id })
      }::jsonb)
      `;
    }

    await connection.queryArray`commit`;
  } catch (error) {
    try {
      await connection.queryArray`rollback`;
    } catch (rollbackError) {
      console.error("Rollback error", rollbackError);
    }
    console.error("rating_after_completion error", error);
    return respond(500, { error: "Beklenmeyen hata", details: `${error}` });
  } finally {
    connection.release();
  }

  for (const reminder of reminders) {
    if (reminder.customer_fcm) {
      await sendFcm(
        reminder.customer_fcm,
        `${reminder.business_name} deneyimini değerlendirin`,
        `Randevunuz hakkında yorum bırakmayı unutmayın`,
        {
          appointment_id: reminder.appointment_id,
          business_id: reminder.business_id,
        },
      );
    }

    const channel = supabase.channel(`appointments:business_${reminder.business_id}`, {
      config: { broadcast: { self: false } },
    });
    try {
      await channel.subscribe(async (status) => {
        if (status === "SUBSCRIBED") {
          await channel.send({
            type: "broadcast",
            event: "rating_reminder",
            payload: {
              appointment_id: reminder.appointment_id,
              customer_id: reminder.customer_id,
            },
          });
          await channel.unsubscribe();
        }
      });
    } catch (error) {
      console.error("Realtime publish failed", error);
    }
  }

  return respond(200, { processed: reminders.length, reminder_hours: reminderHours });
}

serve(handleRequest);
