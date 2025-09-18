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

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const databaseUrl = Deno.env.get("SUPABASE_DB_URL");

if (!supabaseUrl || !serviceRoleKey) {
  console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env vars");
}

const supabase = createClient(supabaseUrl ?? "", serviceRoleKey ?? "", {
  auth: { persistSession: false },
});

const pool = databaseUrl ? new Pool(databaseUrl, 3, true) : null;

interface BookAppointmentPayload {
  customer_id?: string;
  business_id?: string;
  staff_id?: string | null;
  services?: Array<string | { id: string; quantity?: number }>;
  scheduled_at?: string;
  notes?: string;
  source?: string;
}

interface ServiceRow {
  id: string;
  name: string;
  price: number;
  duration_minutes: number;
}

const allowedStatusesForConflict = ["pending", "approved", "completed"] as const;

function respond(status: number, body: Json) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders,
    },
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

  let payload: BookAppointmentPayload;
  try {
    payload = await req.json();
  } catch (error) {
    return respond(400, { error: "Invalid JSON payload", details: `${error}` });
  }

  const customerId = payload.customer_id;
  const businessId = payload.business_id;
  const staffId = payload.staff_id ?? null;
  const scheduledAt = payload.scheduled_at;
  const rawServices = payload.services ?? [];
  const notes = payload.notes ?? null;

  if (!customerId || !businessId || !scheduledAt || rawServices.length === 0) {
    return respond(400, { error: "customer_id, business_id, scheduled_at ve services zorunludur" });
  }

  const scheduledStart = new Date(scheduledAt);
  if (Number.isNaN(scheduledStart.getTime())) {
    return respond(400, { error: "scheduled_at geçerli bir ISO tarih olmalıdır" });
  }

  const serviceIds = rawServices.map((service) => (typeof service === "string" ? service : service.id));

  const connection = await pool.connect();
  try {
    await connection.queryArray`begin`;

    const businessResult = await connection.queryObject<{ owner_id: string; published: boolean; deleted_at: Date | null }>`
      select owner_id, published, deleted_at
      from public.businesses
      where id = ${businessId} for update
    `;

    if (businessResult.rows.length === 0) {
      throw new HttpError(404, "İşletme bulunamadı");
    }

    const businessRow = businessResult.rows[0];
    if (!businessRow.published || businessRow.deleted_at !== null) {
      throw new HttpError(400, "İşletme yayında değil veya pasif");
    }

    const servicesResult = await connection.queryObject<ServiceRow>`
      select id, name, price, duration_minutes
      from public.services
      where business_id = ${businessId}
        and id = any(${serviceIds})
        and active = true
        and deleted_at is null
    `;

    if (servicesResult.rows.length !== serviceIds.length) {
      throw new HttpError(400, "Seçilen hizmetlerden bazıları bulunamadı veya pasif");
    }

    let totalAmount = 0;
    let totalDuration = 0;
    const servicesPayload = servicesResult.rows.map((service) => {
      const quantity = rawServices.find((item) => (typeof item === "string" ? item === service.id : item.id === service.id)) as
        | string
        | { id: string; quantity?: number };
      const qty = typeof quantity === "string" ? 1 : quantity.quantity ?? 1;
      totalAmount += service.price * qty;
      totalDuration += service.duration_minutes * qty;
      return {
        id: service.id,
        name: service.name,
        price: service.price,
        duration_minutes: service.duration_minutes,
        quantity: qty,
      };
    });

    if (totalDuration <= 0) {
      totalDuration = servicesResult.rows.reduce((sum, svc) => sum + svc.duration_minutes, 0);
    }
    if (totalDuration <= 0) {
      throw new HttpError(400, "Hizmet süresi hesaplanamadı");
    }

    const scheduledEnd = new Date(scheduledStart.getTime() + totalDuration * 60 * 1000);

    const staffResult = staffId
      ? await connection.queryObject<{ id: string; active: boolean }>`
          select id, active
          from public.staff
          where id = ${staffId}
            and business_id = ${businessId}
            and deleted_at is null
          for update
        `
      : { rows: [] as Array<{ id: string; active: boolean }> };

    if (staffId && staffResult.rows.length === 0) {
      throw new HttpError(400, "Personel bulunamadı veya bu işletmeye ait değil");
    }
    if (staffId && !staffResult.rows[0].active) {
      throw new HttpError(400, "Personel pasif durumdadır");
    }

    const availabilityResult = await connection.queryObject`
      select id
      from public.availability
      where business_id = ${businessId}
        and (${staffId}::uuid is null or staff_id = ${staffId})
        and starts_at <= ${scheduledStart.toISOString()}::timestamptz
        and ends_at >= ${scheduledEnd.toISOString()}::timestamptz
      order by starts_at asc
      limit 1
    `;

    if (availabilityResult.rows.length === 0) {
      throw new HttpError(400, "Seçilen tarih/saat için uygunluk bulunamadı");
    }

    const conflictResult = await connection.queryObject`
      select id
      from public.appointments
      where business_id = ${businessId}
        and status = any(${allowedStatusesForConflict}::text[])
        and deleted_at is null
        and tstzrange(scheduled_at, scheduled_at + make_interval(mins => duration_minutes), '[)') &&
            tstzrange(${scheduledStart.toISOString()}::timestamptz, ${scheduledEnd.toISOString()}::timestamptz, '[)')
        and (${staffId}::uuid is null or staff_id is null or staff_id = ${staffId})
      for share
    `;

    if (conflictResult.rows.length > 0) {
      throw new HttpError(409, "Seçilen zaman dilimi dolu görünüyor");
    }

    const insertResult = await connection.queryObject<{
      id: string;
      business_id: string;
      customer_id: string;
      staff_id: string | null;
      scheduled_at: string;
      status: string;
      total_amount: number;
      duration_minutes: number;
    }>`
      insert into public.appointments
        (customer_id, business_id, staff_id, services, scheduled_at, duration_minutes, status, total_amount, payment_status, notes)
      values
        (${customerId}::uuid, ${businessId}::uuid, ${staffId}::uuid, ${JSON.stringify(servicesPayload)}::jsonb, ${
      scheduledStart.toISOString()
    }::timestamptz, ${totalDuration}, 'pending', ${totalAmount}, 'pending', ${notes})
      returning id, business_id, customer_id, staff_id, scheduled_at, status, total_amount, duration_minutes
    `;

    const appointment = insertResult.rows[0];

    await connection.queryArray`
      insert into public.notifications (profile_id, type, payload)
      values (${businessRow.owner_id}::uuid, 'appointment_created', ${
      JSON.stringify({
        appointment_id: appointment.id,
        business_id: appointment.business_id,
        customer_id: appointment.customer_id,
        scheduled_at: appointment.scheduled_at,
        total_amount: appointment.total_amount,
      })
    }::jsonb)
    `;

    await connection.queryArray`
      insert into public.audit_logs (actor_id, business_id, action, metadata)
      values (${customerId}::uuid, ${businessId}::uuid, 'appointment_booked', ${
      JSON.stringify({ appointment_id: appointment.id })
    }::jsonb)
    `;

    if (Deno.env.get("STRIPE_SECRET_KEY")) {
      await connection.queryArray`
        insert into public.payment_intents (appointment_id, business_id, customer_id, amount, status)
        values (${appointment.id}::uuid, ${businessId}::uuid, ${customerId}::uuid, ${totalAmount}, 'pending')
        on conflict (appointment_id) do update set amount = excluded.amount, status = excluded.status, updated_at = timezone('utc', now())
      `;
    }

    await connection.queryArray`commit`;

    const channel = supabase.channel(`appointments:business_${businessId}`, {
      config: { broadcast: { self: false } },
    });

    const broadcastPayload = {
      event: "appointment_created",
      appointment_id: appointment.id,
      scheduled_at: appointment.scheduled_at,
      staff_id: appointment.staff_id,
      total_amount: appointment.total_amount,
    };

    try {
      await channel.subscribe(async (status) => {
        if (status === "SUBSCRIBED") {
          await channel.send({ type: "broadcast", event: "appointment_created", payload: broadcastPayload });
          await channel.unsubscribe();
        }
      });
    } catch (error) {
      console.error("Realtime broadcast failed", error);
    }

    return respond(200, {
      ...appointment,
      services: servicesPayload,
      duration_minutes: totalDuration,
      total_amount: totalAmount,
    });
  } catch (error) {
    try {
      await connection.queryArray`rollback`;
    } catch (rollbackError) {
      console.error("Rollback error", rollbackError);
    }

    if (error instanceof HttpError) {
      return respond(error.status, { error: error.message, details: error.details });
    }

    console.error("book_appointment error", error);
    return respond(500, { error: "Beklenmeyen hata", details: `${error}` });
  } finally {
    connection.release();
  }
}

serve(handleRequest);
