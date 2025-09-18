import { serve } from "https://deno.land/std@0.200.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.7";
import { Pool } from "https://deno.land/x/postgres@v0.17.0/mod.ts";

type Json = Record<string, unknown> | Array<unknown> | string | number | boolean | null;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

class HttpError extends Error {
  constructor(readonly status: number, message: string, readonly details?: Json) {
    super(message);
  }
}

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const databaseUrl = Deno.env.get("SUPABASE_DB_URL");
const fcmKey = Deno.env.get("FCM_SERVER_KEY");
const cancellationLimitHours = Number(Deno.env.get("CUSTOMER_CANCELLATION_LIMIT_HOURS") ?? 2);

const supabase = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false } });
const pool = databaseUrl ? new Pool(databaseUrl, 3, true) : null;

const allowedStatuses = new Set(["approved", "rejected", "cancelled", "completed"]);

interface StatusPayload {
  appointment_id?: string;
  new_status?: string;
  actor_id?: string;
  reason?: string;
  notes?: string;
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

  if (req.method !== "POST") {
    return respond(405, { error: "Method not allowed" });
  }

  if (!pool) {
    return respond(500, { error: "Database connection is not configured" });
  }

  let payload: StatusPayload;
  try {
    payload = await req.json();
  } catch (error) {
    return respond(400, { error: "Invalid JSON payload", details: `${error}` });
  }

  const appointmentId = payload.appointment_id;
  const newStatus = payload.new_status;
  const actorId = payload.actor_id;
  const reason = payload.reason ?? null;
  const notes = payload.notes ?? null;

  if (!appointmentId || !newStatus || !actorId) {
    return respond(400, { error: "appointment_id, new_status ve actor_id zorunludur" });
  }

  if (!allowedStatuses.has(newStatus)) {
    return respond(400, { error: `Desteklenmeyen durum: ${newStatus}` });
  }

  const connection = await pool.connect();
  try {
    await connection.queryArray`begin`;

    const appointmentResult = await connection.queryObject<{
      id: string;
      status: string;
      business_id: string;
      customer_id: string;
      staff_id: string | null;
      scheduled_at: string;
      total_amount: number;
      business_owner_id: string;
      business_name: string;
      customer_name: string | null;
      customer_fcm: string | null;
      staff_profile_id: string | null;
      staff_fcm: string | null;
    }>`
      select a.id,
             a.status,
             a.business_id,
             a.customer_id,
             a.staff_id,
             a.scheduled_at,
             a.total_amount,
             b.owner_id as business_owner_id,
             b.name as business_name,
             customer.full_name as customer_name,
             customer.fcm_token as customer_fcm,
             s.profile_id as staff_profile_id,
             staff_profile.fcm_token as staff_fcm
      from public.appointments a
        join public.businesses b on b.id = a.business_id
        left join public.profiles customer on customer.id = a.customer_id
        left join public.staff s on s.id = a.staff_id
        left join public.profiles staff_profile on staff_profile.id = s.profile_id
      where a.id = ${appointmentId} for update
    `;

    if (appointmentResult.rows.length === 0) {
      throw new HttpError(404, "Randevu bulunamadı");
    }

    const appointment = appointmentResult.rows[0];

    const actorResult = await connection.queryObject`
      select 1
      from public.profiles
      where id = ${actorId}
      limit 1
    `;

    if (actorResult.rows.length === 0) {
      throw new HttpError(403, "Actor bulunamadı");
    }

    const isOwner = appointment.business_owner_id === actorId;
    const isStaff = (await connection.queryObject`
      select 1
      from public.staff
      where business_id = ${appointment.business_id}
        and active = true
        and (id = ${actorId} or profile_id = ${actorId})
      limit 1
    `).rows.length > 0;
    const isCustomer = appointment.customer_id === actorId;

    if (!isOwner && !isStaff && !(isCustomer && newStatus === "cancelled")) {
      throw new HttpError(403, "Bu işlem için yetkiniz yok");
    }

    if (isCustomer && newStatus === "cancelled") {
      const diffMs = new Date(appointment.scheduled_at).getTime() - Date.now();
      const diffHours = diffMs / 1000 / 3600;
      if (diffHours < cancellationLimitHours) {
        throw new HttpError(400, `Randevu ${cancellationLimitHours} saatten az kaldığı için iptal edilemez`);
      }
    }

    if (appointment.status === "cancelled" || appointment.status === "rejected") {
      throw new HttpError(400, "Randevu zaten kapatılmış");
    }

    if (appointment.status === newStatus) {
      throw new HttpError(400, "Randevu zaten bu durumda");
    }

    const updateResult = await connection.queryObject<{
      id: string;
      status: string;
      scheduled_at: string;
      staff_id: string | null;
      customer_id: string;
      business_id: string;
      total_amount: number;
    }>`
      update public.appointments
         set status = ${newStatus},
             cancellation_reason = ${reason},
             notes = coalesce(${notes}, notes),
             cancelled_at = case when ${newStatus} = 'cancelled' then timezone('utc', now()) else cancelled_at end,
             updated_at = timezone('utc', now())
       where id = ${appointmentId}
       returning id, status, scheduled_at, staff_id, customer_id, business_id, total_amount
    `;

    const updated = updateResult.rows[0];

    await connection.queryArray`
      insert into public.notifications (profile_id, type, payload)
      values (${appointment.customer_id}::uuid, 'appointment_status', ${
      JSON.stringify({
        appointment_id: appointment.id,
        new_status: newStatus,
        reason,
      })
    }::jsonb)
    `;

    if (appointment.staff_profile_id) {
      await connection.queryArray`
        insert into public.notifications (profile_id, type, payload)
        values (${appointment.staff_profile_id}::uuid, 'appointment_status', ${
        JSON.stringify({ appointment_id: appointment.id, new_status: newStatus })
      }::jsonb)
      `;
    }

    await connection.queryArray`
      insert into public.audit_logs (actor_id, business_id, action, metadata)
      values (${actorId}::uuid, ${appointment.business_id}::uuid, 'appointment_status_update', ${
      JSON.stringify({ appointment_id: appointment.id, new_status: newStatus, reason })
    }::jsonb)
    `;

    await connection.queryArray`commit`;

    const channel = supabase.channel(`appointments:business_${appointment.business_id}`, {
      config: { broadcast: { self: false } },
    });

    try {
      await channel.subscribe(async (status) => {
        if (status === "SUBSCRIBED") {
          await channel.send({
            type: "broadcast",
            event: "appointment_status",
            payload: {
              appointment_id: appointment.id,
              new_status: newStatus,
            },
          });
          await channel.unsubscribe();
        }
      });
    } catch (error) {
      console.error("Realtime publish failed", error);
    }

    if (appointment.customer_fcm) {
      const title = `${appointment.business_name} randevusu güncellendi`;
      const body = `Durum: ${newStatus}` + (reason ? `, Sebep: ${reason}` : "");
      await sendFcm(appointment.customer_fcm, title, body, {
        appointment_id: appointment.id,
        new_status: newStatus,
      });
    }

    if (appointment.staff_fcm) {
      await sendFcm(appointment.staff_fcm, `Randevu ${newStatus}`, `${appointment.customer_name ?? "Müşteri"} için güncellendi`, {
        appointment_id: appointment.id,
        new_status: newStatus,
      });
    }

    return respond(200, { ...updated, previous_status: appointment.status });
  } catch (error) {
    try {
      await connection.queryArray`rollback`;
    } catch (rollbackError) {
      console.error("Rollback error", rollbackError);
    }

    if (error instanceof HttpError) {
      return respond(error.status, { error: error.message, details: error.details });
    }

    console.error("appointment_status_update error", error);
    return respond(500, { error: "Beklenmeyen hata", details: `${error}` });
  } finally {
    connection.release();
  }
}

serve(handleRequest);
