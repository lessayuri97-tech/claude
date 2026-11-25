-- =====================================================================
-- PT example: base de dados no Supabase
-- Como usar: Supabase > SQL Editor > New query > cole TUDO isto > Run.
-- Pode correr mais de uma vez sem estragar nada.
-- =====================================================================

-- 1) Espaço de cada personal (exercícios, modelos, marca, limites...)
create table if not exists public.espacos (
  personal_id uuid primary key references auth.users(id) on delete cascade,
  dados       jsonb not null default '{}'::jsonb,
  rev         integer not null default 1,
  updated_at  timestamptz not null default now()
);

-- 2) Um registo por aluno (plano, sessões, nutrição, comentários...)
create table if not exists public.alunos_docs (
  id          text primary key,
  personal_id uuid not null references auth.users(id) on delete cascade,
  user_id     uuid references auth.users(id) on delete set null, -- a conta do próprio aluno, depois de aceitar o convite
  dados       jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);
create index if not exists alunos_docs_personal_idx on public.alunos_docs(personal_id);
create index if not exists alunos_docs_user_idx on public.alunos_docs(user_id);

-- 3) Convites (link que o personal envia ao aluno)
create table if not exists public.convites (
  token       text primary key,
  aluno_id    text not null references public.alunos_docs(id) on delete cascade,
  personal_id uuid not null references auth.users(id) on delete cascade,
  usado       boolean not null default false,
  created_at  timestamptz not null default now()
);

-- atualiza updated_at sozinho
create or replace function public.pt_toca() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;
drop trigger if exists pt_espacos_toca on public.espacos;
create trigger pt_espacos_toca before update on public.espacos for each row execute function public.pt_toca();
drop trigger if exists pt_alunos_toca on public.alunos_docs;
create trigger pt_alunos_toca before update on public.alunos_docs for each row execute function public.pt_toca();

-- =====================================================================
-- SEGURANÇA (Row Level Security): cada personal só vê os seus alunos,
-- cada aluno só vê o seu próprio registo.
-- =====================================================================
alter table public.espacos     enable row level security;
alter table public.alunos_docs enable row level security;
alter table public.convites    enable row level security;

-- espacos: o personal faz tudo no seu; o aluno só lê o do seu personal
drop policy if exists espacos_dono on public.espacos;
create policy espacos_dono on public.espacos for all to authenticated
  using (personal_id = auth.uid()) with check (personal_id = auth.uid());
drop policy if exists espacos_aluno_le on public.espacos;
create policy espacos_aluno_le on public.espacos for select to authenticated
  using (exists (select 1 from public.alunos_docs a where a.personal_id = espacos.personal_id and a.user_id = auth.uid()));

-- alunos_docs: o personal faz tudo nos seus; o aluno lê e atualiza só o seu
drop policy if exists alunos_dono on public.alunos_docs;
create policy alunos_dono on public.alunos_docs for all to authenticated
  using (personal_id = auth.uid()) with check (personal_id = auth.uid());
drop policy if exists alunos_proprio_le on public.alunos_docs;
create policy alunos_proprio_le on public.alunos_docs for select to authenticated
  using (user_id = auth.uid());
drop policy if exists alunos_proprio_atualiza on public.alunos_docs;
create policy alunos_proprio_atualiza on public.alunos_docs for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- o aluno só pode mudar a coluna "dados" (nunca trocar de personal nem de dono)
revoke update on public.alunos_docs from authenticated;
grant update (dados) on public.alunos_docs to authenticated;
grant select, insert, delete on public.alunos_docs to authenticated;
grant select, insert, update, delete on public.espacos to authenticated;
-- (o personal precisa de atualizar mais colunas: usa a função abaixo)
-- Para o personal poder gravar personal_id/user_id sem abrir brechas ao aluno, a escrita
-- do personal passa por esta função (corre com os direitos do dono da base de dados).
create or replace function public.pt_gravar_aluno(p_id text, p_dados jsonb) returns void
language plpgsql security definer set search_path = public as $$
begin
  insert into public.alunos_docs(id, personal_id, dados) values (p_id, auth.uid(), p_dados)
  on conflict (id) do update set dados = excluded.dados
    where public.alunos_docs.personal_id = auth.uid();
end $$;
revoke all on function public.pt_gravar_aluno(text, jsonb) from public, anon;
grant execute on function public.pt_gravar_aluno(text, jsonb) to authenticated;

-- convites: só o personal dono vê/cria os seus
grant select, insert, delete on public.convites to authenticated;
drop policy if exists convites_dono on public.convites;
create policy convites_dono on public.convites for all to authenticated
  using (personal_id = auth.uid()) with check (personal_id = auth.uid());

-- O aluno aceita o convite: liga a sua conta ao registo (uma única vez)
create or replace function public.aceitar_convite(p_token text) returns text
language plpgsql security definer set search_path = public as $$
declare c public.convites%rowtype;
begin
  if auth.uid() is null then raise exception 'precisa de entrar primeiro'; end if;
  select * into c from public.convites where token = p_token and usado = false for update;
  if not found then raise exception 'convite inválido ou já usado'; end if;
  update public.alunos_docs set user_id = auth.uid() where id = c.aluno_id and personal_id = c.personal_id;
  update public.convites set usado = true where token = p_token;
  return c.aluno_id;
end $$;
revoke all on function public.aceitar_convite(text) from public, anon;
grant execute on function public.aceitar_convite(text) to authenticated;

-- =====================================================================
-- Diagnóstico da página inicial: pessoas interessadas (leads)
-- =====================================================================
create table if not exists public.leads (
  id          uuid primary key default gen_random_uuid(),
  personal_id uuid not null references auth.users(id) on delete cascade,
  nome        text not null check (char_length(nome) <= 120),
  whatsapp    text not null check (char_length(whatsapp) <= 30),
  respostas   jsonb not null default '{}'::jsonb check (pg_column_size(respostas) < 4000),
  contactado  boolean not null default false,
  created_at  timestamptz not null default now()
);
create index if not exists leads_personal_idx on public.leads(personal_id, created_at desc);
alter table public.leads enable row level security;
drop policy if exists leads_inserir on public.leads;
create policy leads_inserir on public.leads for insert to anon, authenticated
  with check (exists (select 1 from public.espacos e where e.personal_id = leads.personal_id));
drop policy if exists leads_dono on public.leads;
create policy leads_dono on public.leads for all to authenticated
  using (personal_id = auth.uid()) with check (personal_id = auth.uid());
revoke all on public.leads from anon, authenticated;
grant insert on public.leads to anon, authenticated;
grant select, delete on public.leads to authenticated;
grant update (contactado) on public.leads to authenticated;

-- Fim. Nunca coloque a "service_role key" na app nem no GitHub.
