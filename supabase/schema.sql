-- AURELIA production-ready Supabase schema
-- Run this entire file once in Supabase Dashboard → SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Reader' check (char_length(display_name) between 1 and 40),
  role text not null default 'member' check (role in ('member','librarian')),
  created_at timestamptz not null default now()
);

create table if not exists public.books (
  id text primary key,
  title text not null,
  author text not null,
  category text not null,
  publication_year integer not null default 2026,
  total_copies integer not null default 1 check (total_copies >= 0),
  available_copies integer not null default 1 check (available_copies >= 0 and available_copies <= total_copies),
  rating numeric(2,1) not null default 4.5 check (rating between 0 and 5),
  description text not null default '',
  cover_url text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.loans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  book_id text not null references public.books(id),
  borrowed_at date not null default current_date,
  due_at date not null default (current_date + 14),
  returned_at date,
  created_at timestamptz not null default now(),
  check (due_at >= borrowed_at),
  check (returned_at is null or returned_at >= borrowed_at)
);
create index if not exists loans_user_active_idx on public.loans(user_id, due_at) where returned_at is null;

create table if not exists public.book_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 100),
  author text not null check (char_length(author) between 1 and 80),
  reason text not null default '' check (char_length(reason) <= 300),
  status text not null default 'Pending' check (status in ('Pending','Approved','Declined')),
  created_at timestamptz not null default now()
);
create index if not exists requests_user_created_idx on public.book_requests(user_id, created_at desc);

create table if not exists public.saved_books (
  user_id uuid not null references public.profiles(id) on delete cascade,
  book_id text not null references public.books(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(user_id, book_id)
);

create or replace function public.is_aurelia_librarian()
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.profiles where id = auth.uid() and role = 'librarian'); $$;

create or replace function public.handle_new_aurelia_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles(id, display_name)
  values (new.id, coalesce(nullif(left(new.raw_user_meta_data->>'display_name',40),''), 'Reader'))
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_aurelia_user_created on auth.users;
create trigger on_aurelia_user_created after insert on auth.users
for each row execute procedure public.handle_new_aurelia_user();

alter table public.profiles enable row level security;
alter table public.books enable row level security;
alter table public.loans enable row level security;
alter table public.book_requests enable row level security;
alter table public.saved_books enable row level security;

drop policy if exists "profiles read own or librarian" on public.profiles;
create policy "profiles read own or librarian" on public.profiles for select to authenticated
using (id = auth.uid() or public.is_aurelia_librarian());
drop policy if exists "profiles update own display name" on public.profiles;
create policy "profiles update own display name" on public.profiles for update to authenticated
using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "books visible to authenticated" on public.books;
create policy "books visible to authenticated" on public.books for select to authenticated using (true);
drop policy if exists "librarian manages books" on public.books;
create policy "librarian manages books" on public.books for all to authenticated
using (public.is_aurelia_librarian()) with check (public.is_aurelia_librarian());

drop policy if exists "loans read own or librarian" on public.loans;
create policy "loans read own or librarian" on public.loans for select to authenticated
using (user_id = auth.uid() or public.is_aurelia_librarian());

drop policy if exists "requests read own or librarian" on public.book_requests;
create policy "requests read own or librarian" on public.book_requests for select to authenticated
using (user_id = auth.uid() or public.is_aurelia_librarian());
drop policy if exists "members create requests" on public.book_requests;
create policy "members create requests" on public.book_requests for insert to authenticated
with check (user_id = auth.uid());
drop policy if exists "librarians update requests" on public.book_requests;
create policy "librarians update requests" on public.book_requests for update to authenticated
using (public.is_aurelia_librarian()) with check (public.is_aurelia_librarian());

drop policy if exists "members manage own saved books" on public.saved_books;
create policy "members manage own saved books" on public.saved_books for all to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Prevent clients from changing privileged profile fields.
revoke update on public.profiles from authenticated;
grant update(display_name) on public.profiles to authenticated;
grant select on public.profiles, public.books, public.loans, public.book_requests, public.saved_books to authenticated;
grant insert, delete on public.saved_books to authenticated;
grant insert on public.book_requests to authenticated;
grant update(status) on public.book_requests to authenticated;
grant insert, update, delete on public.books to authenticated;

create or replace function public.borrow_aurelia_book(p_book_id text)
returns public.loans language plpgsql security definer set search_path = public
as $$
declare v_user uuid := auth.uid(); v_book public.books; v_loan public.loans;
begin
  if v_user is null then raise exception 'Please sign in first.'; end if;
  if (select count(*) from public.loans where user_id=v_user and returned_at is null) >= 4
    then raise exception 'Borrowing limit reached (4 books).'; end if;
  select * into v_book from public.books where id=p_book_id for update;
  if not found then raise exception 'Book not found.'; end if;
  if v_book.available_copies < 1 then raise exception 'No copies are currently available.'; end if;
  update public.books set available_copies=available_copies-1 where id=p_book_id;
  insert into public.loans(user_id,book_id) values(v_user,p_book_id) returning * into v_loan;
  return v_loan;
end;
$$;

create or replace function public.return_aurelia_book(p_loan_id uuid)
returns public.loans language plpgsql security definer set search_path = public
as $$
declare v_user uuid := auth.uid(); v_loan public.loans;
begin
  if v_user is null then raise exception 'Please sign in first.'; end if;
  select * into v_loan from public.loans
  where id=p_loan_id and user_id=v_user and returned_at is null for update;
  if not found then raise exception 'Active loan not found.'; end if;
  update public.loans set returned_at=current_date where id=p_loan_id returning * into v_loan;
  update public.books set available_copies=least(total_copies,available_copies+1) where id=v_loan.book_id;
  return v_loan;
end;
$$;
grant execute on function public.borrow_aurelia_book(text) to authenticated;
grant execute on function public.return_aurelia_book(uuid) to authenticated;

insert into public.books(id,title,author,category,publication_year,total_copies,available_copies,rating,description,cover_url)
values
('b001','The Alchemist','Paulo Coelho','Fiction',1988,8,8,4.8,'A fable about following your dreams and listening to your heart.','https://images.unsplash.com/photo-1543002588-bfa74002ed7e?auto=format&fit=crop&w=500&q=80'),
('b002','Atomic Habits','James Clear','Self-growth',2018,6,6,4.9,'A practical guide to building good habits through small, remarkable changes.','https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=500&q=80'),
('b003','The Great Gatsby','F. Scott Fitzgerald','Fiction',1925,5,5,4.6,'A portrait of the Jazz Age, ambition and the elusive American dream.','https://images.unsplash.com/photo-1544947950-fa07a98d237f?auto=format&fit=crop&w=500&q=80'),
('b004','Wings of Fire','A. P. J. Abdul Kalam','Biography',1999,7,7,4.9,'The inspiring journey of India’s former President, scientist and teacher.','https://images.unsplash.com/photo-1519682337058-a94d519337bc?auto=format&fit=crop&w=500&q=80'),
('b005','Sapiens','Yuval Noah Harari','Non-fiction',2011,4,4,4.7,'A sweeping exploration of humankind, from early ancestors to the modern age.','https://images.unsplash.com/photo-1516979187457-637abb4f9353?auto=format&fit=crop&w=500&q=80'),
('b006','The Hobbit','J. R. R. Tolkien','Fantasy',1937,5,5,4.9,'An unexpected journey into Middle-earth, courage and unlikely friendship.','https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=500&q=80'),
('b007','Ikigai','Héctor García & Francesc Miralles','Self-growth',2016,5,5,4.5,'Discover the Japanese philosophy of finding purpose in everyday life.','https://images.unsplash.com/photo-1511108690759-009324a90311?auto=format&fit=crop&w=500&q=80'),
('b008','The Silent Patient','Alex Michaelides','Fiction',2019,3,3,4.6,'A psychological thriller about a woman who refuses to speak.','https://images.unsplash.com/photo-1495446815901-a7297e633e8d?auto=format&fit=crop&w=500&q=80'),
('b009','A Brief History of Time','Stephen Hawking','Science',1988,4,4,4.7,'An accessible journey through space, time and the universe.','https://images.unsplash.com/photo-1507842217343-583bb7270b66?auto=format&fit=crop&w=500&q=80'),
('b010','The Diary of a Young Girl','Anne Frank','Biography',1947,4,4,4.9,'A moving diary written in hiding during one of history’s darkest periods.','https://images.unsplash.com/photo-1532012197267-da84d127e765?auto=format&fit=crop&w=500&q=80'),
('b011','1984','George Orwell','Fiction',1949,5,5,4.8,'A timeless warning about surveillance, truth and authoritarian power.','https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?auto=format&fit=crop&w=500&q=80'),
('b012','The Psychology of Money','Morgan Housel','Non-fiction',2020,4,4,4.7,'Timeless lessons on wealth, behaviour and making better financial decisions.','https://images.unsplash.com/photo-1519682337058-a94d519337bc?auto=format&fit=crop&w=500&q=80')
on conflict (id) do nothing;
