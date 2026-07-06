-- ============================================================
-- Todo Mate 클론 · Supabase(Postgres) 스키마
-- Supabase Dashboard > SQL Editor 에 붙여넣고 Run
-- ============================================================

-- 1) 단발성 할 일
create table if not exists public.tasks (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  the_date    date not null,                 -- 'YYYY-MM-DD'
  text        text not null,
  category    text not null default 'etc',   -- work|study|health|life|etc
  done        boolean not null default false,
  created_at  timestamptz not null default now()
);
create index if not exists tasks_user_date_idx on public.tasks(user_id, the_date);

-- 2) 반복 규칙 (매일/평일 + 시작/종료일)
create table if not exists public.recurring (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  text        text not null,
  category    text not null default 'etc',
  rep         text not null,                 -- daily|weekday
  start_date  date not null,
  end_date    date,                          -- null = 무기한
  created_at  timestamptz not null default now()
);
create index if not exists recurring_user_idx on public.recurring(user_id);

-- 3) 반복 항목의 날짜별 상태 (완료체크 / 해당일 삭제)
create table if not exists public.recurring_state (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  recurring_id  uuid not null references public.recurring(id) on delete cascade,
  the_date      date not null,
  done          boolean not null default false,
  skipped       boolean not null default false,   -- 그 날짜만 삭제
  unique(recurring_id, the_date)
);
create index if not exists recstate_user_date_idx on public.recurring_state(user_id, the_date);

-- ============================================================
-- Row Level Security : 본인 데이터만 접근
-- ============================================================
alter table public.tasks           enable row level security;
alter table public.recurring       enable row level security;
alter table public.recurring_state enable row level security;

create policy "own tasks"     on public.tasks
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own recurring" on public.recurring
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own recstate"  on public.recurring_state
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
