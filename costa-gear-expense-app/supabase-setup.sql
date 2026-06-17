
-- ═══════════════════════════════════════════════════════════════════════
-- COSTA GEAR, Business Expenses + Assets CCA Tracker
-- Run this entire script in Supabase → SQL Editor → New query
-- ═══════════════════════════════════════════════════════════════════════

create extension if not exists pgcrypto;

-- 1. EXPENSES
create table if not exists expenses (
  id                uuid primary key default gen_random_uuid(),
  expense_date      date not null,
  vendor            text not null,
  description       text not null,
  category          text not null,
  total_amount      numeric(12,2) not null default 0,
  business_use_pct  numeric(5,2) not null default 100,
  deductible_amount numeric(12,2) generated always as (round(total_amount * business_use_pct / 100, 2)) stored,
  payment_method    text,
  payment_reference text,
  receipt_url       text,
  receipt_status    text default 'Missing',
  notes             text,
  tax_year          integer not null,
  is_asset_purchase boolean default false,
  linked_asset_id   uuid,
  tax_ready         boolean default false,
  created_at        timestamptz default now()
);

-- 2. ASSETS FOR CCA
create table if not exists assets (
  id                  uuid primary key default gen_random_uuid(),
  asset_code          text not null,
  asset_name          text not null,
  purchase_date       date not null,
  vendor              text,
  cost                numeric(12,2) not null default 0,
  cca_class           text,
  cca_rate            numeric(6,2) not null default 0,
  business_use_pct    numeric(5,2) not null default 100,
  business_cost       numeric(12,2) generated always as (round(cost * business_use_pct / 100, 2)) stored,
  estimated_cca_claim numeric(12,2) generated always as (round((cost * business_use_pct / 100) * (cca_rate / 100) * 0.5, 2)) stored,
  receipt_url         text,
  notes               text,
  tax_year            integer not null,
  status              text default 'Active',
  linked_expense_id   uuid references expenses(id) on delete set null,
  created_at          timestamptz default now()
);

do $$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where constraint_name = 'expenses_business_use_pct_range'
  ) then
    alter table expenses
      add constraint expenses_business_use_pct_range check (business_use_pct >= 0 and business_use_pct <= 100);
  end if;

  if not exists (
    select 1 from information_schema.table_constraints
    where constraint_name = 'assets_business_use_pct_range'
  ) then
    alter table assets
      add constraint assets_business_use_pct_range check (business_use_pct >= 0 and business_use_pct <= 100);
  end if;
end $$;

-- Add foreign key after both tables exist
do $$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where constraint_name = 'expenses_linked_asset_id_fkey'
  ) then
    alter table expenses
      add constraint expenses_linked_asset_id_fkey
      foreign key (linked_asset_id) references assets(id) on delete set null;
  end if;
end $$;

create index if not exists idx_expenses_tax_year on expenses(tax_year);
create index if not exists idx_expenses_date on expenses(expense_date);
create index if not exists idx_expenses_category on expenses(category);
create index if not exists idx_assets_tax_year on assets(tax_year);
create index if not exists idx_assets_purchase_date on assets(purchase_date);

-- ── Enable public read/write, matching the simple setup used in the original app.
-- For private business records, add authentication before sharing the link publicly.
alter table expenses enable row level security;
alter table assets enable row level security;

drop policy if exists "public all expenses" on expenses;
drop policy if exists "public all assets" on assets;

create policy "public all expenses" on expenses for all using (true) with check (true);
create policy "public all assets" on assets for all using (true) with check (true);

-- ═══════════════════════════════════════════════════════════════════════
-- SEED DATA, based on the starter Excel file
-- ═══════════════════════════════════════════════════════════════════════

insert into expenses (
  expense_date, vendor, description, category, total_amount, business_use_pct,
  payment_method, payment_reference, receipt_url, receipt_status, notes,
  tax_year, is_asset_purchase, tax_ready
) values
  ('2025-02-06', 'OpenAI, LLC', 'ChatGPT subscription', 'Software & Subscriptions', 353.66, 100, 'Credit Card', null, 'Link', 'Saved', '11 months of monthly subscription', 2025, false, true),
  ('2025-12-19', 'GoDaddy Domains Canada, Inc', 'MS 365 Email Essentials with Security', 'Website & Hosting', 147.71, 100, 'Credit Card', null, 'Link', 'Saved', '12-month subscription', 2025, false, true),
  ('2025-10-28', 'Costco.ca', 'Laptop MS Surface 13in', 'Equipment (CCA)', 2184.49, 100, 'Credit Card', null, null, 'Missing', null, 2025, true, false),
  ('2025-12-07', 'Microsoft Canada Inc.', 'Microsoft 365 Premium', 'Software & Subscriptions', 144.48, 100, 'Credit Card', null, 'Link', 'Saved', '12-month subscription', 2025, false, true),
  ('2025-05-27', 'Grammarly, Inc.', 'Grammarly Premium', 'Software & Subscriptions', 204.67, 100, 'Credit Card', null, 'Link', 'Saved', '12-month subscription', 2025, false, true),
  ('2026-04-27', 'Intuit TurboTax', 'TurboTax Self-Employed software', 'Professional Services', 168.00, 50, 'Credit Card', null, 'Link', 'Saved', null, 2026, false, true)
on conflict do nothing;

insert into assets (
  asset_code, asset_name, purchase_date, vendor, cost, cca_class, cca_rate,
  business_use_pct, receipt_url, notes, tax_year, status
) values
  ('A-001', 'Laptop MS Surface 13in', '2025-10-28', 'Costco.ca', 2184.49, 'Class 50', 55, 100, 'Link', 'Primary business device', 2025, 'Active')
on conflict do nothing;
