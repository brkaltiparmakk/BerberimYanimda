-- Enable extensions
create extension if not exists "pgcrypto";
create extension if not exists "postgis";

-- =====================================================================
-- Table definitions
-- =====================================================================

create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    role text not null default 'user',
    profile_type text not null check (profile_type in ('customer', 'business_owner', 'staff')),
    full_name text,
    phone text,
    avatar_url text,
    fcm_token text,
    default_business_id uuid,
    created_at timestamptz not null default timezone('utc'::text, now()),
    updated_at timestamptz not null default timezone('utc'::text, now()),
    deleted_at timestamptz
);

create table if not exists public.businesses (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references public.profiles(id) on delete cascade,
    name text not null,
    description text,
    address text,
    phone text,
    email text,
    latitude double precision,
    longitude double precision,
    open_hours jsonb not null default '{}'::jsonb,
    cover_image_url text,
    gallery jsonb not null default '[]'::jsonb,
    average_rating numeric(3,2) not null default 0,
    review_count integer not null default 0,
    published boolean not null default false,
    created_at timestamptz not null default timezone('utc'::text, now()),
    updated_at timestamptz not null default timezone('utc'::text, now()),
    deleted_at timestamptz
);

create table if not exists public.staff (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses(id) on delete cascade,
    profile_id uuid references public.profiles(id) on delete set null,
    full_name text not null,
    role text,
    active boolean not null default true,
    avatar_url text,
    created_at timestamptz not null default timezone('utc'::text, now()),
    updated_at timestamptz not null default timezone('utc'::text, now()),
    deleted_at timestamptz
);

create table if not exists public.service_categories (
    id uuid primary key default gen_random_uuid(),
    business_id uuid references public.businesses(id) on delete cascade,
    name text not null,
    sort_order integer not null default 0,
    created_at timestamptz not null default timezone('utc'::text, now()),
    updated_at timestamptz not null default timezone('utc'::text, now())
);

create table if not exists public.services (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses(id) on delete cascade,
    category_id uuid references public.service_categories(id) on delete set null,
    name text not null,
    description text,
    price numeric(10,2) not null,
    duration_minutes integer not null,
    active boolean not null default true,
    media_urls jsonb not null default '[]'::jsonb,
    created_at timestamptz not null default timezone('utc'::text, now()),
    updated_at timestamptz not null default timezone('utc'::text, now()),
    deleted_at timestamptz
);

create table if not exists public.service_staff (
    service_id uuid not null references public.services(id) on delete cascade,
    staff_id uuid not null references public.staff(id) on delete cascade,
    primary key (service_id, staff_id)
);

create table if not exists public.availability (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses(id) on delete cascade,
    staff_id uuid references public.staff(id) on delete cascade,
    starts_at timestamptz not null,
    ends_at timestamptz not null,
    repeat_rule text,
    notes text,
    created_at timestamptz not null default timezone('utc'::text, now()),
    updated_at timestamptz not null default timezone('utc'::text, now())
);

create table if not exists public.appointments (
    id uuid primary key default gen_random_uuid(),
    customer_id uuid not null references public.profiles(id) on delete cascade,
    business_id uuid not null references public.businesses(id) on delete cascade,
    staff_id uuid references public.staff(id) on delete set null,
    services jsonb not null,
    scheduled_at timestamptz not null,
    duration_minutes integer not null default 0,
    status text not null check (status in ('pending','approved','rejected','cancelled','completed')),
    total_amount numeric(10,2) not null,
    payment_status text not null default 'pending' check (payment_status in ('pending','paid','refunded','failed')),
    notes text,
    cancellation_reason text,
    cancelled_at timestamptz,
    created_at timestamptz not null default timezone('utc'::text, now()),
    updated_at timestamptz not null default timezone('utc'::text, now()),
    deleted_at timestamptz
);

create table if not exists public.reviews (
    id uuid primary key default gen_random_uuid(),
    appointment_id uuid not null references public.appointments(id) on delete cascade,
    business_id uuid not null references public.businesses(id) on delete cascade,
    customer_id uuid not null references public.profiles(id) on delete cascade,
    rating integer not null check (rating between 1 and 5),
    comment text,
    created_at timestamptz not null default timezone('utc'::text, now()),
    updated_at timestamptz not null default timezone('utc'::text, now())
);

create table if not exists public.favorites (
    id uuid primary key default gen_random_uuid(),
    customer_id uuid not null references public.profiles(id) on delete cascade,
    business_id uuid not null references public.businesses(id) on delete cascade,
    created_at timestamptz not null default timezone('utc'::text, now()),
    unique (customer_id, business_id)
);

create table if not exists public.promotions (
    id uuid primary key default gen_random_uuid(),
    business_id uuid not null references public.businesses(id) on delete cascade,
    title text not null,
    description text,
    discount_rate numeric(5,2) not null,
    start_date date not null,
    end_date date not null,
    active boolean not null default true,
    created_at timestamptz not null default timezone('utc'::text, now()),
    updated_at timestamptz not null default timezone('utc'::text, now())
);

create table if not exists public.notifications (
    id uuid primary key default gen_random_uuid(),
    profile_id uuid not null references public.profiles(id) on delete cascade,
    type text not null,
    payload jsonb not null,
    read_at timestamptz,
    sent_at timestamptz not null default timezone('utc'::text, now()),
    created_at timestamptz not null default timezone('utc'::text, now())
);

create table if not exists public.audit_logs (
    id uuid primary key default gen_random_uuid(),
    actor_id uuid references public.profiles(id) on delete set null,
    business_id uuid references public.businesses(id) on delete cascade,
    action text not null,
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default timezone('utc'::text, now())
);

create table if not exists public.payment_intents (
    id uuid primary key default gen_random_uuid(),
    appointment_id uuid references public.appointments(id) on delete cascade,
    business_id uuid references public.businesses(id) on delete cascade,
    customer_id uuid references public.profiles(id) on delete cascade,
    provider text not null default 'stripe',
    provider_intent_id text,
    status text not null default 'pending',
    amount numeric(10,2) not null,
    currency text not null default 'TRY',
    client_secret text,
    created_at timestamptz not null default timezone('utc'::text, now()),
    updated_at timestamptz not null default timezone('utc'::text, now())
);

create table if not exists public.media_assets (
    id uuid primary key default gen_random_uuid(),
    bucket text not null,
    path text not null,
    business_id uuid references public.businesses(id) on delete cascade,
    profile_id uuid references public.profiles(id) on delete cascade,
    metadata jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default timezone('utc'::text, now())
);

do $$
begin
    if not exists (
        select 1 from pg_constraint where conname = 'profiles_default_business_fk'
    ) then
        alter table public.profiles
            add constraint profiles_default_business_fk
            foreign key (default_business_id) references public.businesses(id) on delete set null;
    end if;
exception when others then
    raise notice 'Constraint creation skipped: %', sqlerrm;
end$$;

create or replace function public.business_dashboard_metrics(p_business_id uuid)
returns jsonb
language sql
security definer
as $$
  select jsonb_build_object(
    'upcoming_count', (
      select count(*) from public.appointments
      where business_id = p_business_id and status in ('pending','approved')
        and scheduled_at >= timezone('utc', now())
    ),
    'completed_count', (
      select count(*) from public.appointments
      where business_id = p_business_id and status = 'completed'
        and scheduled_at >= timezone('utc', now()) - interval '30 days'
    ),
    'total_revenue', (
      select coalesce(sum(total_amount), 0)
      from public.appointments
      where business_id = p_business_id and status = 'completed'
    ),
    'popular_services', (
      select coalesce(jsonb_agg(row_to_json(t)), '[]'::jsonb)
      from (
        select coalesce(elem->>'name', 'Bilinmeyen') as name, count(*)::int as usage_count
        from public.appointments a
             cross join lateral jsonb_array_elements(a.services) as elem
        where a.business_id = p_business_id
        group by elem->>'name'
        order by usage_count desc
        limit 5
      ) as t
    )
  );
$$;

-- =====================================================================
-- Indexes
-- =====================================================================

create index if not exists idx_profiles_default_business on public.profiles(default_business_id);
create index if not exists idx_businesses_owner on public.businesses(owner_id);
create index if not exists idx_businesses_published on public.businesses(published) where deleted_at is null;
create index if not exists idx_staff_business on public.staff(business_id);
create index if not exists idx_services_business on public.services(business_id) where deleted_at is null;
create index if not exists idx_services_active on public.services(active);
create index if not exists idx_availability_business_staff on public.availability(business_id, staff_id, starts_at);
create index if not exists idx_appointments_business_date on public.appointments(business_id, scheduled_at);
create index if not exists idx_appointments_customer on public.appointments(customer_id);
create index if not exists idx_reviews_business on public.reviews(business_id);
create index if not exists idx_promotions_business on public.promotions(business_id, active);
create index if not exists idx_notifications_profile on public.notifications(profile_id, read_at);
create index if not exists idx_audit_logs_business on public.audit_logs(business_id);
create index if not exists idx_payment_intents_appointment on public.payment_intents(appointment_id);

-- =====================================================================
-- Seed Data
-- =====================================================================

insert into auth.users (id, email, encrypted_password, email_confirmed_at, last_sign_in_at, created_at, updated_at)
values
    ('11111111-1111-1111-1111-111111111111', 'customer@example.com', crypt('password', gen_salt('bf')), now(), now(), now(), now()),
    ('22222222-2222-2222-2222-222222222222', 'owner@example.com', crypt('password', gen_salt('bf')), now(), now(), now(), now()),
    ('33333333-3333-3333-3333-333333333333', 'ahmet@blueblade.com', crypt('password', gen_salt('bf')), now(), now(), now(), now()),
    ('44444444-4444-4444-4444-444444444444', 'burak@blueblade.com', crypt('password', gen_salt('bf')), now(), now(), now(), now()),
    ('55555555-5555-5555-5555-555555555555', 'cem@urbanfade.com', crypt('password', gen_salt('bf')), now(), now(), now(), now())
on conflict (id) do nothing;

insert into public.profiles (id, role, profile_type, full_name, phone, avatar_url)
values
    ('11111111-1111-1111-1111-111111111111', 'user', 'customer', 'Mert Kaya', '+905550001111', null),
    ('22222222-2222-2222-2222-222222222222', 'user', 'business_owner', 'Selim Arslan', '+905550002222', null),
    ('33333333-3333-3333-3333-333333333333', 'user', 'staff', 'Ahmet Yılmaz', '+905550003333', null),
    ('44444444-4444-4444-4444-444444444444', 'user', 'staff', 'Burak Demir', '+905550004444', null),
    ('55555555-5555-5555-5555-555555555555', 'user', 'staff', 'Cem Korkmaz', '+905550005555', null)
on conflict (id) do update set profile_type = excluded.profile_type;

insert into public.businesses (id, owner_id, name, description, address, phone, email, latitude, longitude, open_hours, cover_image_url, average_rating, review_count, published)
values
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', 'BlueBlade Barber', 'Modern erkek bakım salonu', 'İstiklal Cd. No:45, Beyoğlu, İstanbul', '+902122223344', 'info@blueblade.com', 41.0369, 28.985, '{"Mon":["09:00-19:00"],"Tue":["09:00-19:00"],"Wed":["09:00-19:00"],"Thu":["09:00-19:00"],"Fri":["09:00-20:00"],"Sat":["10:00-18:00"],"Sun":[]}'::jsonb, null, 4.7, 12, true),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 'Urban Fade Studio', 'Şehrin merkezinde premium bakım', 'Bağdat Cd. No:12, Kadıköy, İstanbul', '+902162223355', 'info@urbanfade.com', 40.989, 29.027, '{"Mon":["10:00-20:00"],"Tue":["10:00-20:00"],"Wed":["10:00-20:00"],"Thu":["10:00-20:00"],"Fri":["10:00-21:00"],"Sat":["09:00-19:00"],"Sun":["11:00-17:00"],"notes":"Resmi tatillerde kapalı"}'::jsonb, null, 4.5, 8, true)
    on conflict (id) do nothing;

update public.profiles set default_business_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' where id = '22222222-2222-2222-2222-222222222222';

insert into public.staff (id, business_id, profile_id, full_name, role, active)
values
    ('33333333-3333-3333-3333-333333333333', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333', 'Ahmet Yılmaz', 'Barber', true),
    ('44444444-4444-4444-4444-444444444444', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '44444444-4444-4444-4444-444444444444', 'Burak Demir', 'Stylist', true),
    ('55555555-5555-5555-5555-555555555555', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '55555555-5555-5555-5555-555555555555', 'Cem Korkmaz', 'Senior Barber', true)
    on conflict (id) do nothing;

insert into public.service_categories (id, business_id, name, sort_order)
values
    ('66666666-6666-6666-6666-666666666661', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Saç', 1),
    ('66666666-6666-6666-6666-666666666662', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Sakal', 2),
    ('66666666-6666-6666-6666-666666666663', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Premium Bakım', 1)
    on conflict (id) do nothing;

insert into public.services (id, business_id, category_id, name, description, price, duration_minutes, active)
values
    ('77777777-7777-7777-7777-777777777770', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '66666666-6666-6666-6666-666666666661', 'Klasik Saç Kesimi', 'Yıkama dahil modern saç kesimi', 250, 45, true),
    ('77777777-7777-7777-7777-777777777771', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '66666666-6666-6666-6666-666666666662', 'Sakal Tıraşı', 'Sıcak havlu ile bakım', 180, 30, true),
    ('77777777-7777-7777-7777-777777777772', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '66666666-6666-6666-6666-666666666661', 'Saç & Sakal Paket', 'Tam bakım paketi', 400, 75, true),
    ('77777777-7777-7777-7777-777777777773', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '66666666-6666-6666-6666-666666666663', 'Deluxe Saç Kesimi', 'Kişiye özel tasarım', 320, 60, true),
    ('77777777-7777-7777-7777-777777777774', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '66666666-6666-6666-6666-666666666663', 'Rahatlatıcı Bakım', 'Masaj ve bakım', 380, 70, true)
    on conflict (id) do nothing;

insert into public.service_staff (service_id, staff_id)
values
    ('77777777-7777-7777-7777-777777777770', '33333333-3333-3333-3333-333333333333'),
    ('77777777-7777-7777-7777-777777777770', '44444444-4444-4444-4444-444444444444'),
    ('77777777-7777-7777-7777-777777777771', '33333333-3333-3333-3333-333333333333'),
    ('77777777-7777-7777-7777-777777777772', '44444444-4444-4444-4444-444444444444'),
    ('77777777-7777-7777-7777-777777777773', '55555555-5555-5555-5555-555555555555'),
    ('77777777-7777-7777-7777-777777777774', '55555555-5555-5555-5555-555555555555')
    on conflict do nothing;

insert into public.availability (id, business_id, staff_id, starts_at, ends_at, repeat_rule)
values
    ('88888888-8888-8888-8888-888888888881', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333', timezone('utc', now() + interval '1 day' + interval '10 hour'), timezone('utc', now() + interval '1 day' + interval '11 hour'), 'weekly'),
    ('88888888-8888-8888-8888-888888888882', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '44444444-4444-4444-4444-444444444444', timezone('utc', now() + interval '1 day' + interval '12 hour'), timezone('utc', now() + interval '1 day' + interval '13 hour'), 'weekly'),
    ('88888888-8888-8888-8888-888888888883', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '55555555-5555-5555-5555-555555555555', timezone('utc', now() + interval '2 day' + interval '11 hour'), timezone('utc', now() + interval '2 day' + interval '12 hour'), 'weekly')
    on conflict (id) do nothing;

insert into public.promotions (id, business_id, title, description, discount_rate, start_date, end_date, active)
values
    ('99999999-9999-9999-9999-999999999991', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Hafta içi %15', 'Hafta içi randevularda geçerli %15 indirim', 15, current_date, current_date + interval '30 day', true),
    ('99999999-9999-9999-9999-999999999992', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Yeni Müşteri %20', 'İlk ziyaretinizde %20 indirim', 20, current_date, current_date + interval '45 day', true)
    on conflict (id) do nothing;

insert into public.appointments (id, customer_id, business_id, staff_id, services, scheduled_at, duration_minutes, status, total_amount, payment_status)
values
    ('aaaa1111-aaaa-1111-aaaa-1111aaaa1111', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333', '[{"service_id":"77777777-7777-7777-7777-777777777770","name":"Klasik Saç Kesimi","price":250}]'::jsonb, timezone('utc', now() + interval '1 day' + interval '10 hour'), 45, 'approved', 250, 'pending'),
    ('bbbb1111-bbbb-1111-bbbb-1111bbbb1111', '11111111-1111-1111-1111-111111111111', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '55555555-5555-5555-5555-555555555555', '[{"service_id":"77777777-7777-7777-7777-777777777774","name":"Rahatlatıcı Bakım","price":380}]'::jsonb, timezone('utc', now() - interval '3 day' + interval '12 hour'), 70, 'completed', 380, 'paid')
    on conflict (id) do nothing;

insert into public.reviews (id, appointment_id, business_id, customer_id, rating, comment)
values
    ('cccc1111-cccc-1111-cccc-1111cccc1111', 'bbbb1111-bbbb-1111-bbbb-1111bbbb1111', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', 5, 'Harika deneyim, kesinlikle tavsiye ederim!')
    on conflict (id) do nothing;

insert into public.favorites (customer_id, business_id)
values
    ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')
    on conflict do nothing;

insert into public.notifications (id, profile_id, type, payload, read_at)
values
    ('dddd1111-dddd-1111-dddd-1111dddd1111', '11111111-1111-1111-1111-111111111111', 'appointment_confirmed', '{"appointment_id":"aaaa1111-aaaa-1111-aaaa-1111aaaa1111","message":"Randevunuz onaylandı"}'::jsonb, null)
    on conflict (id) do nothing;

insert into public.audit_logs (id, actor_id, business_id, action, metadata)
values
    ('eeee1111-eeee-1111-eeee-1111eeee1111', '22222222-2222-2222-2222-222222222222', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'appointment_status_update', '{"appointment_id":"aaaa1111-aaaa-1111-aaaa-1111aaaa1111","status":"approved"}'::jsonb)
    on conflict (id) do nothing;

insert into public.payment_intents (id, appointment_id, business_id, customer_id, provider_intent_id, status, amount, currency)
values
    ('ffff1111-ffff-1111-ffff-1111ffff1111', 'bbbb1111-bbbb-1111-bbbb-1111bbbb1111', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', 'pi_test_123', 'succeeded', 380, 'TRY')
    on conflict (id) do nothing;

-- =====================================================================
-- Row Level Security Policies
-- =====================================================================

alter table public.profiles enable row level security;
create policy "Profiles select self" on public.profiles
    for select using (auth.uid() = id);
create policy "Profiles update self" on public.profiles
    for update using (auth.uid() = id);

alter table public.businesses enable row level security;
create policy "Businesses public published" on public.businesses
    for select using (published = true and deleted_at is null);
create policy "Businesses owner manage" on public.businesses
    for all using (
        auth.uid() = owner_id
    ) with check (
        auth.uid() = owner_id
    );

alter table public.staff enable row level security;
create policy "Staff public limited" on public.staff
    for select using (
        business_id in (
            select id from public.businesses where published = true and deleted_at is null
        ) and active = true
    );
create policy "Staff self view" on public.staff
    for select using (auth.uid() = profile_id);
create policy "Staff owner manage" on public.staff
    for all using (
        auth.uid() in (
            select owner_id from public.businesses where businesses.id = staff.business_id
        )
    ) with check (
        auth.uid() in (
            select owner_id from public.businesses where businesses.id = staff.business_id
        )
    );
create policy "Staff self update" on public.staff
    for update using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

alter table public.service_categories enable row level security;
create policy "Service categories public" on public.service_categories
    for select using (
        business_id is null or business_id in (select id from public.businesses where published = true and deleted_at is null)
    );
create policy "Service categories owner manage" on public.service_categories
    for all using (
        business_id in (
            select id from public.businesses where owner_id = auth.uid()
        )
    ) with check (
        business_id in (
            select id from public.businesses where owner_id = auth.uid()
        )
    );

alter table public.services enable row level security;
create policy "Services public" on public.services
    for select using (
        business_id in (
            select id from public.businesses where published = true and deleted_at is null
        ) and deleted_at is null and active = true
    );
create policy "Services owner manage" on public.services
    for all using (
        business_id in (
            select id from public.businesses where owner_id = auth.uid()
        )
    ) with check (
        business_id in (
            select id from public.businesses where owner_id = auth.uid()
        )
    );

alter table public.service_staff enable row level security;
create policy "Service staff owner manage" on public.service_staff
    for all using (
        service_id in (
            select id from public.services where business_id in (
                select id from public.businesses where owner_id = auth.uid()
            )
        )
    ) with check (
        service_id in (
            select id from public.services where business_id in (
                select id from public.businesses where owner_id = auth.uid()
            )
        )
    );

alter table public.availability enable row level security;
create policy "Availability owner staff manage" on public.availability
    for all using (
        auth.uid() in (
            select owner_id from public.businesses where businesses.id = availability.business_id
        ) or auth.uid() in (
            select profile_id from public.staff where staff.id = availability.staff_id
        )
    ) with check (
        auth.uid() in (
            select owner_id from public.businesses where businesses.id = availability.business_id
        ) or auth.uid() in (
            select profile_id from public.staff where staff.id = availability.staff_id
        )
    );

alter table public.appointments enable row level security;
create policy "Appointments customer select" on public.appointments
    for select using (auth.uid() = customer_id);
create policy "Appointments staff select" on public.appointments
    for select using (
        auth.uid() in (
            select owner_id from public.businesses where businesses.id = appointments.business_id
        ) or auth.uid() in (
            select profile_id from public.staff where staff.business_id = appointments.business_id and profile_id is not null
        )
    );
create policy "Appointments customer insert" on public.appointments
    for insert with check (auth.uid() = customer_id);
create policy "Appointments owner update status" on public.appointments
    for update using (
        auth.uid() in (
            select owner_id from public.businesses where businesses.id = appointments.business_id
        ) or auth.uid() in (
            select profile_id from public.staff where staff.business_id = appointments.business_id and profile_id is not null
        )
    );
create policy "Appointments customer cancel" on public.appointments
    for update using (
        auth.uid() = customer_id and scheduled_at > timezone('utc', now()) + interval '2 hour'
    ) with check (
        status = 'cancelled'
    );

alter table public.reviews enable row level security;
create policy "Reviews public select" on public.reviews for select using (true);
create policy "Reviews customer insert" on public.reviews
    for insert with check (
        auth.uid() = customer_id and
        exists (
            select 1 from public.appointments a
            where a.id = reviews.appointment_id
              and a.customer_id = auth.uid()
              and a.status = 'completed'
        )
    );

alter table public.promotions enable row level security;
create policy "Promotions public select" on public.promotions
    for select using (active = true);
create policy "Promotions owner manage" on public.promotions
    for all using (
        business_id in (
            select id from public.businesses where owner_id = auth.uid()
        )
    ) with check (
        business_id in (
            select id from public.businesses where owner_id = auth.uid()
        )
    );

alter table public.notifications enable row level security;
create policy "Notifications owner" on public.notifications
    for all using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

alter table public.audit_logs enable row level security;
create policy "Audit logs actor" on public.audit_logs
    for select using (
        auth.uid() = actor_id or auth.uid() in (
            select owner_id from public.businesses where businesses.id = audit_logs.business_id
        )
    );
create policy "Audit logs insert service" on public.audit_logs
    for insert with check (auth.uid() = actor_id);

alter table public.payment_intents enable row level security;
create policy "Payment intents customer" on public.payment_intents
    for select using (auth.uid() = customer_id);
create policy "Payment intents owner" on public.payment_intents
    for select using (
        auth.uid() in (
            select owner_id from public.businesses where businesses.id = payment_intents.business_id
        )
    );

alter table public.media_assets enable row level security;
create policy "Media assets owner" on public.media_assets
    for all using (
        auth.uid() = profile_id or auth.uid() in (
            select owner_id from public.businesses where businesses.id = media_assets.business_id
        )
    ) with check (
        auth.uid() = profile_id or auth.uid() in (
            select owner_id from public.businesses where businesses.id = media_assets.business_id
        )
    );

-- Allow service role to bypass RLS where needed via Edge Functions.

