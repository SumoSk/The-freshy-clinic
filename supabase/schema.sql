-- Freshy Clinic scaffold: isolated from all existing SUMOWEB objects.
-- Frontend demo uses local synthetic data, not these tables.
-- No browser access or live accounts are enabled by this schema.
create schema freshy_clinic;
revoke all on schema freshy_clinic from public, anon, authenticated;

create table freshy_clinic.branches (
 id uuid primary key default gen_random_uuid(),
 name text not null check (length(trim(name)) > 0),
 address text not null default '',
 active boolean not null default true,
 created_at timestamptz not null default now()
);
create table freshy_clinic.staff (
 id uuid primary key default gen_random_uuid(),
 auth_user_id uuid unique references auth.users(id),
 branch_id uuid not null references freshy_clinic.branches(id),
 name text not null check (length(trim(name)) > 0),
 role text not null default 'sales' check (role in ('owner','manager','sales')),
 active boolean not null default true,
 created_at timestamptz not null default now()
);
create table freshy_clinic.customers (
 id uuid primary key default gen_random_uuid(),
 code text not null unique,
 name text not null check (length(trim(name)) > 0),
 nickname text not null default '',
 phone text,
 line_contact text not null default '',
 source text not null default '',
 branch_id uuid not null references freshy_clinic.branches(id),
 staff_id uuid references freshy_clinic.staff(id),
 status text not null default 'new' check (status in ('new','followup','purchased')),
 note text not null default '',
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create unique index freshy_customer_phone_unique on freshy_clinic.customers (phone) where phone is not null and phone <> '';
create table freshy_clinic.products (
 id uuid primary key default gen_random_uuid(),
 name text not null,
 category text not null default '',
 price numeric(14,2) not null default 0 check (price >= 0),
 active boolean not null default true
);
create table freshy_clinic.sales (
 id uuid primary key default gen_random_uuid(),
 code text not null unique,
 customer_id uuid not null references freshy_clinic.customers(id),
 branch_id uuid not null references freshy_clinic.branches(id),
 staff_id uuid not null references freshy_clinic.staff(id),
 sale_date date not null,
 discount numeric(14,2) not null default 0 check (discount >= 0),
 status text not null default 'active' check (status in ('active','cancelled')),
 cancel_reason text,
 note text not null default '',
 created_at timestamptz not null default now(),
 check (status <> 'cancelled' or (cancel_reason is not null and length(trim(cancel_reason)) > 0))
);
create table freshy_clinic.sale_items (
 id uuid primary key default gen_random_uuid(),
 sale_id uuid not null references freshy_clinic.sales(id),
 product_id uuid references freshy_clinic.products(id),
 product_name text not null,
 quantity integer not null check (quantity > 0),
 unit_price numeric(14,2) not null check (unit_price >= 0)
);
create table freshy_clinic.payments (
 id uuid primary key default gen_random_uuid(),
 sale_id uuid not null references freshy_clinic.sales(id),
 receiving_branch_id uuid not null references freshy_clinic.branches(id),
 payment_date date not null,
 amount numeric(14,2) not null check (amount > 0),
 type text not null check (type in ('payment','refund')),
 method text not null check (method in ('cash','transfer','card')),
 reason text not null default '',
 created_at timestamptz not null default now()
);
create table freshy_clinic.followups (
 id uuid primary key default gen_random_uuid(),
 customer_id uuid not null references freshy_clinic.customers(id),
 branch_id uuid not null references freshy_clinic.branches(id),
 staff_id uuid not null references freshy_clinic.staff(id),
 type text not null check (type in ('pitch','followup')),
 due_date date not null,
 topic text not null,
 outcome text not null default 'pending',
 note text not null default '',
 done boolean not null default false,
 created_at timestamptz not null default now()
);
create table freshy_clinic.audit_log (
 id uuid primary key default gen_random_uuid(),
 actor_id uuid references freshy_clinic.staff(id),
 action text not null,
 entity_type text not null,
 entity_id uuid,
 details jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create index freshy_staff_branch_idx on freshy_clinic.staff(branch_id);
create index freshy_customers_branch_idx on freshy_clinic.customers(branch_id);
create index freshy_customers_staff_idx on freshy_clinic.customers(staff_id);
create index freshy_sales_branch_date_idx on freshy_clinic.sales(branch_id,sale_date);
create index freshy_sales_staff_date_idx on freshy_clinic.sales(staff_id,sale_date);
create index freshy_sales_customer_idx on freshy_clinic.sales(customer_id);
create index freshy_items_sale_idx on freshy_clinic.sale_items(sale_id);
create index freshy_items_product_idx on freshy_clinic.sale_items(product_id);
create index freshy_payments_sale_idx on freshy_clinic.payments(sale_id);
create index freshy_payments_branch_date_idx on freshy_clinic.payments(receiving_branch_id,payment_date);
create index freshy_followups_branch_due_idx on freshy_clinic.followups(branch_id,due_date);
create index freshy_followups_staff_idx on freshy_clinic.followups(staff_id);
create index freshy_followups_customer_idx on freshy_clinic.followups(customer_id);
create index freshy_audit_actor_idx on freshy_clinic.audit_log(actor_id);

alter table freshy_clinic.branches enable row level security;
alter table freshy_clinic.staff enable row level security;
alter table freshy_clinic.customers enable row level security;
alter table freshy_clinic.products enable row level security;
alter table freshy_clinic.sales enable row level security;
alter table freshy_clinic.sale_items enable row level security;
alter table freshy_clinic.payments enable row level security;
alter table freshy_clinic.followups enable row level security;
alter table freshy_clinic.audit_log enable row level security;
revoke all on all tables in schema freshy_clinic from public, anon, authenticated;
revoke all on all sequences in schema freshy_clinic from public, anon, authenticated;
-- Live identity, authorized RPCs and server-side transaction validation are a later phase.
-- Keep these tables inaccessible to all browser roles until that phase is implemented.
