-- =====================================================================
-- SUPERVISÃO: outra pessoa da equipe com o mesmo acesso do dono
-- (vê e edita as MESMAS alunas, leads, treinos, nutrição e Central).
-- Como usar: Supabase > SQL Editor > New query > cole TUDO > Run.
-- Pode correr mais de uma vez. Depois, em Definições > Equipe da app,
-- gere o convite de supervisor.
-- =====================================================================

-- Quem é supervisor de quem
create table if not exists public.supervisores (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  dono_id    uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.supervisores enable row level security;
revoke all on public.supervisores from anon, authenticated;

-- Convites de supervisor (um uso, válidos por 7 dias)
create table if not exists public.convites_equipe (
  token      text primary key,
  dono_id    uuid not null references auth.users(id) on delete cascade,
  usado      boolean not null default false,
  created_at timestamptz not null default now()
);
alter table public.convites_equipe enable row level security;
revoke all on public.convites_equipe from anon, authenticated;

-- O "espaço" que esta conta usa: o do dono (se for supervisor) ou o seu próprio
create or replace function public.pt_espaco() returns uuid
language sql security definer stable set search_path = public as $$
  select coalesce((select dono_id from public.supervisores where user_id = auth.uid()), auth.uid()) $$;
revoke all on function public.pt_espaco() from public, anon;
grant execute on function public.pt_espaco() to authenticated;

-- O dono gera um convite
create or replace function public.pt_convite_equipe() returns text
language plpgsql security definer set search_path = public as $$
declare t text;
begin
  if auth.uid() is null then raise exception 'precisa de entrar primeiro'; end if;
  if exists (select 1 from public.supervisores where user_id = auth.uid()) then raise exception 'só o dono pode convidar'; end if;
  if not exists (select 1 from public.espacos where personal_id = auth.uid()) then raise exception 'só o dono pode convidar'; end if;
  t := replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', '');
  insert into public.convites_equipe(token, dono_id) values (t, auth.uid());
  return t;
end $$;
revoke all on function public.pt_convite_equipe() from public, anon;
grant execute on function public.pt_convite_equipe() to authenticated;

-- A pessoa convidada aceita (depois de criar a conta com e-mail e senha)
create or replace function public.aceitar_convite_equipe(p_token text) returns uuid
language plpgsql security definer set search_path = public as $$
declare c public.convites_equipe%rowtype;
begin
  if auth.uid() is null then raise exception 'precisa de entrar primeiro'; end if;
  select * into c from public.convites_equipe
    where token = p_token and usado = false and created_at > now() - interval '7 days' for update;
  if not found then raise exception 'convite inválido ou já usado'; end if;
  if exists (select 1 from public.espacos where personal_id = auth.uid()) then raise exception 'esta conta já é de um dono'; end if;
  if exists (select 1 from public.alunos_docs where user_id = auth.uid()) then raise exception 'esta conta já é de uma aluna'; end if;
  insert into public.supervisores(user_id, dono_id) values (auth.uid(), c.dono_id)
    on conflict (user_id) do update set dono_id = excluded.dono_id;
  update public.convites_equipe set usado = true where token = p_token;
  return c.dono_id;
end $$;
revoke all on function public.aceitar_convite_equipe(text) from public, anon;
grant execute on function public.aceitar_convite_equipe(text) to authenticated;

-- O dono vê e remove os seus supervisores
create or replace function public.pt_listar_supervisores() returns table(user_id uuid, email text, desde timestamptz)
language sql security definer stable set search_path = public as $$
  select s.user_id, u.email::text, s.created_at from public.supervisores s
  join auth.users u on u.id = s.user_id where s.dono_id = auth.uid() order by s.created_at $$;
revoke all on function public.pt_listar_supervisores() from public, anon;
grant execute on function public.pt_listar_supervisores() to authenticated;

create or replace function public.pt_remover_supervisor(p_user uuid) returns void
language sql security definer set search_path = public as $$
  delete from public.supervisores where user_id = p_user and dono_id = auth.uid() $$;
revoke all on function public.pt_remover_supervisor(uuid) from public, anon;
grant execute on function public.pt_remover_supervisor(uuid) to authenticated;

-- Regras de acesso: onde estava "personal_id = auth.uid()", passa a valer o espaço da conta
drop policy if exists espacos_dono_le  on public.espacos;
drop policy if exists espacos_dono_upd on public.espacos;
drop policy if exists espacos_dono_del on public.espacos;
create policy espacos_dono_le  on public.espacos for select to authenticated using (personal_id = public.pt_espaco());
create policy espacos_dono_upd on public.espacos for update to authenticated
  using (personal_id = public.pt_espaco()) with check (personal_id = public.pt_espaco());
create policy espacos_dono_del on public.espacos for delete to authenticated using (personal_id = auth.uid());

drop policy if exists alunos_dono on public.alunos_docs;
create policy alunos_dono on public.alunos_docs for all to authenticated
  using (personal_id = public.pt_espaco()) with check (personal_id = public.pt_espaco());

drop policy if exists convites_dono on public.convites;
create policy convites_dono on public.convites for all to authenticated
  using (personal_id = public.pt_espaco()) with check (personal_id = public.pt_espaco());

drop policy if exists leads_dono on public.leads;
create policy leads_dono on public.leads for all to authenticated
  using (personal_id = public.pt_espaco()) with check (personal_id = public.pt_espaco());

create or replace function public.pt_gravar_aluno(p_id text, p_dados jsonb) returns void
language plpgsql security definer set search_path = public as $$
declare e uuid := public.pt_espaco();
begin
  if not exists (select 1 from public.espacos where personal_id = e) then
    raise exception 'sem acesso de equipe';
  end if;
  insert into public.alunos_docs(id, personal_id, dados) values (p_id, e, p_dados)
  on conflict (id) do update set dados = excluded.dados
    where public.alunos_docs.personal_id = e;
end $$;
revoke all on function public.pt_gravar_aluno(text, jsonb) from public, anon;
grant execute on function public.pt_gravar_aluno(text, jsonb) to authenticated;

-- Para REMOVER um supervisor: Definições > Equipe > "Remover acesso" na app.
-- (Ou aqui: delete from public.supervisores where user_id = 'UID-DO-SUPERVISOR';)
