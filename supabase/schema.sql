-- =============================================
-- SMART SHELF — Full Supabase SQL Schema
-- Run this in: Supabase Dashboard > SQL Editor
-- =============================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ── PROFILES (extends auth.users) ────────────
create table public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  full_name    text,
  avatar_url   text,
  created_at   timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert with check (auth.uid() = id);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data->>'full_name');
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ── SHELVES ───────────────────────────────────
create table public.shelves (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles(id) on delete cascade,
  name         text not null,
  location     text,
  sensor_id    text unique,
  is_online    boolean not null default false,
  last_ping    timestamptz,
  created_at   timestamptz default now()
);

alter table public.shelves enable row level security;

create policy "Owner can CRUD shelves"
  on public.shelves for all using (auth.uid() = user_id);

-- ── ITEMS ─────────────────────────────────────
create table public.items (
  id              uuid primary key default gen_random_uuid(),
  shelf_id        uuid not null references public.shelves(id) on delete cascade,
  name            text not null,
  image_url       text,
  unit_weight_g   numeric(8,2) not null default 1,
  tare_weight_g   numeric(8,2) not null default 0,
  min_threshold   int not null default 2,
  current_weight  numeric(8,2) not null default 0,
  current_qty     int generated always as
                    (greatest(0, floor((current_weight - tare_weight_g) / unit_weight_g)::int))
                    stored,
  is_active       boolean not null default true,
  slot_number     int,
  created_at      timestamptz default now()
);

create index on public.items (shelf_id, is_active);
create unique index on public.items (shelf_id, slot_number) where slot_number is not null;

alter table public.items enable row level security;

create policy "Owner can CRUD items via shelf"
  on public.items for all
  using (
    exists (
      select 1 from public.shelves s
      where s.id = shelf_id and s.user_id = auth.uid()
    )
  );

-- ── ITEM WEIGHT LOGS ──────────────────────────
create table public.item_logs (
  id           uuid primary key default gen_random_uuid(),
  item_id      uuid not null references public.items(id) on delete cascade,
  weight_g     numeric(8,2) not null,
  qty          int,
  recorded_at  timestamptz not null default now()
);

create index on public.item_logs (item_id, recorded_at desc);

alter table public.item_logs enable row level security;

create policy "Owner can read item logs"
  on public.item_logs for select
  using (
    exists (
      select 1 from public.items i
      join public.shelves s on s.id = i.shelf_id
      where i.id = item_id and s.user_id = auth.uid()
    )
  );

create policy "Service role can insert logs"
  on public.item_logs for insert
  with check (true);

-- ── NOTIFICATIONS ─────────────────────────────
create type notif_type as enum ('low_stock', 'item_removed', 'sensor_offline', 'system');

create table public.notifications (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles(id) on delete cascade,
  shelf_id     uuid references public.shelves(id) on delete set null,
  item_id      uuid references public.items(id) on delete set null,
  type         notif_type not null,
  title        text not null,
  body         text,
  is_read      boolean not null default false,
  created_at   timestamptz not null default now()
);

create index on public.notifications (user_id, is_read, created_at desc);

alter table public.notifications enable row level security;

create policy "Users see own notifications"
  on public.notifications for all using (auth.uid() = user_id);

create policy "Service role can insert notifications"
  on public.notifications for insert
  with check (true);

-- ── REALTIME PUBLICATION ──────────────────────
-- Enable Realtime for these tables in:
-- Supabase Dashboard → Database → Replication → Tables
-- Tables to enable: items, notifications, shelves
--
-- Or run:
-- alter publication supabase_realtime add table public.items;
-- alter publication supabase_realtime add table public.notifications;
-- alter publication supabase_realtime add table public.shelves;

-- ── STORAGE BUCKETS ───────────────────────────
-- Run in Supabase Dashboard → Storage:
-- 1. Create bucket: item-images (public: true)
-- 2. Create bucket: avatars (public: true)
