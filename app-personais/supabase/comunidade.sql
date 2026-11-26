-- =====================================================================
-- COMUNIDADE (feed) + FOTO DE PERFIL
-- Como usar: Supabase > SQL Editor > New query > cole TUDO > Run.
-- Pode correr mais de uma vez. Não precisa de correr mais nada antes.
-- Regras: só alunas do espaço e equipe (dono + supervisores) leem e
-- escrevem. Nada é apagado: a equipe só pode ocultar (e voltar a mostrar).
-- O acesso aos dados é só pelas funções abaixo (as tabelas ficam fechadas).
-- =====================================================================

-- (mesma definição do supervisao.sql; só cria se ainda não existir)
create table if not exists public.supervisores (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  dono_id    uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.supervisores enable row level security;
revoke all on public.supervisores from anon, authenticated;

-- Perfil público dentro da comunidade (nome a mostrar e versão da foto)
create table if not exists public.perfis (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nome    text check (char_length(nome) <= 30),
  foto_v  bigint not null default 0
);
-- Publicações e comentários (um comentário é uma publicação com pai_id)
create table if not exists public.posts (
  id         uuid primary key default gen_random_uuid(),
  espaco_id  uuid not null references auth.users(id) on delete cascade,
  autor_id   uuid references auth.users(id) on delete set null,
  autor_nome text not null,
  equipe     boolean not null default false,
  pai_id     uuid references public.posts(id) on delete cascade,
  texto      text not null default '' check (char_length(texto) <= 1000),
  foto       text,
  editado    boolean not null default false,
  oculto     boolean not null default false,
  created_at timestamptz not null default now()
);
alter table public.posts add column if not exists foto text;
alter table public.posts alter column texto set default '';
alter table public.posts drop constraint if exists posts_texto_check;
alter table public.posts add constraint posts_texto_check check (char_length(texto) <= 1000);
alter table public.posts drop constraint if exists posts_conteudo_check;
alter table public.posts add constraint posts_conteudo_check check (char_length(texto) >= 1 or foto is not null);
create index if not exists posts_feed_idx on public.posts(espaco_id, created_at desc) where pai_id is null;
create index if not exists posts_pai_idx on public.posts(pai_id, created_at);
create table if not exists public.curtidas (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  primary key (post_id, user_id)
);
create table if not exists public.denuncias (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  primary key (post_id, user_id)
);
alter table public.perfis    enable row level security;
alter table public.posts     enable row level security;
alter table public.curtidas  enable row level security;
alter table public.denuncias enable row level security;
revoke all on public.perfis, public.posts, public.curtidas, public.denuncias from anon, authenticated;

-- A que comunidade pertence cada conta: a do dono, a do dono (supervisor) ou a do personal da aluna
create or replace function public.pt_comunidade_de(u uuid) returns uuid
language sql security definer stable set search_path = public as $$
  select coalesce(
    (select dono_id from public.supervisores where user_id = u),
    (select personal_id from public.espacos where personal_id = u),
    (select personal_id from public.alunos_docs where user_id = u limit 1)) $$;
create or replace function public.pt_comunidade() returns uuid
language sql security definer stable set search_path = public as $$ select public.pt_comunidade_de(auth.uid()) $$;
create or replace function public.pt_e_equipe_com() returns boolean
language sql security definer stable set search_path = public as $$
  select exists (select 1 from public.supervisores where user_id = auth.uid())
      or exists (select 1 from public.espacos where personal_id = auth.uid()) $$;
revoke all on function public.pt_comunidade_de(uuid) from public, anon;
revoke all on function public.pt_comunidade() from public, anon;
revoke all on function public.pt_e_equipe_com() from public, anon;
grant execute on function public.pt_comunidade_de(uuid), public.pt_comunidade(), public.pt_e_equipe_com() to authenticated;

-- Feed (cursor por data: p_antes = data da última publicação já mostrada)
drop function if exists public.pt_feed(timestamptz, int);
create or replace function public.pt_feed(p_antes timestamptz default null, p_limite int default 15)
returns table(id uuid, autor_id uuid, nome text, equipe boolean, foto_v bigint, texto text, foto text, created_at timestamptz,
              editado boolean, oculto boolean, curtidas int, comentarios int, eu_curti boolean, denuncias int)
language sql security definer stable set search_path = public as $$
  select p.id, p.autor_id, p.autor_nome, p.equipe, coalesce(pf.foto_v, 0), p.texto, p.foto, p.created_at, p.editado, p.oculto,
    (select count(*)::int from public.curtidas c where c.post_id = p.id),
    (select count(*)::int from public.posts r where r.pai_id = p.id and (public.pt_e_equipe_com() or not r.oculto)),
    exists (select 1 from public.curtidas c where c.post_id = p.id and c.user_id = auth.uid()),
    case when public.pt_e_equipe_com() then (select count(*)::int from public.denuncias d where d.post_id = p.id) else 0 end
  from public.posts p left join public.perfis pf on pf.user_id = p.autor_id
  where p.espaco_id = public.pt_comunidade() and p.pai_id is null
    and (public.pt_e_equipe_com() or not p.oculto)
    and (p_antes is null or p.created_at < p_antes)
  order by p.created_at desc
  limit least(greatest(p_limite, 1), 30) $$;

drop function if exists public.pt_comentarios(uuid);
create or replace function public.pt_comentarios(p_post uuid)
returns table(id uuid, autor_id uuid, nome text, equipe boolean, foto_v bigint, texto text, foto text, created_at timestamptz,
              editado boolean, oculto boolean, curtidas int, comentarios int, eu_curti boolean, denuncias int)
language sql security definer stable set search_path = public as $$
  select p.id, p.autor_id, p.autor_nome, p.equipe, coalesce(pf.foto_v, 0), p.texto, p.foto, p.created_at, p.editado, p.oculto,
    0, 0, false,
    case when public.pt_e_equipe_com() then (select count(*)::int from public.denuncias d where d.post_id = p.id) else 0 end
  from public.posts p left join public.perfis pf on pf.user_id = p.autor_id
  where p.pai_id = p_post and p.espaco_id = public.pt_comunidade()
    and (public.pt_e_equipe_com() or not p.oculto)
  order by p.created_at asc
  limit 100 $$;

-- Publicar ou comentar (legenda e emojis; máx. 1000 letras; foto opcional; máx. 30 por hora)
drop function if exists public.pt_publicar(text, uuid);
create or replace function public.pt_publicar(p_texto text, p_pai uuid default null, p_foto text default null) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_esp uuid := public.pt_comunidade(); v_eq boolean := public.pt_e_equipe_com();
        v_t text := btrim(coalesce(p_texto, '')); v_nome text; v_id uuid;
begin
  if v_esp is null then raise exception 'sem acesso à comunidade'; end if;
  if char_length(v_t) > 1000 then raise exception 'escreva no máximo 1000 letras'; end if;
  if p_foto is not null and (p_pai is not null or p_foto !~ ('^' || auth.uid()::text || '/[a-z0-9_-]{6,60}\.jpg$')) then
    raise exception 'foto inválida'; end if;
  if char_length(v_t) < 1 and p_foto is null then raise exception 'escreva algo ou escolha uma foto'; end if;
  if (select count(*) from public.posts x where x.autor_id = auth.uid() and x.created_at > now() - interval '1 hour') >= 30 then
    raise exception 'muitas publicações seguidas, tente daqui a pouco'; end if;
  if p_pai is not null and not exists (select 1 from public.posts x where x.id = p_pai and x.espaco_id = v_esp and x.pai_id is null) then
    raise exception 'publicação não encontrada'; end if;
  select pf.nome into v_nome from public.perfis pf where pf.user_id = auth.uid();
  if v_nome is null or btrim(v_nome) = '' then
    if v_eq then v_nome := 'Equipe';
    else select split_part(btrim(a.dados->>'nome'), ' ', 1) into v_nome from public.alunos_docs a where a.user_id = auth.uid() limit 1; end if;
  end if;
  insert into public.posts(espaco_id, autor_id, autor_nome, equipe, pai_id, texto, foto)
  values (v_esp, auth.uid(), left(coalesce(nullif(btrim(v_nome), ''), 'Aluna'), 30), v_eq, p_pai, v_t, p_foto) returning id into v_id;
  return v_id;
end $$;

-- Curtir / descurtir (devolve true se ficou curtido)
create or replace function public.pt_curtir(p_post uuid) returns boolean
language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.posts x where x.id = p_post and x.espaco_id = public.pt_comunidade()) then
    raise exception 'publicação não encontrada'; end if;
  if exists (select 1 from public.curtidas c where c.post_id = p_post and c.user_id = auth.uid()) then
    delete from public.curtidas c where c.post_id = p_post and c.user_id = auth.uid(); return false;
  end if;
  insert into public.curtidas(post_id, user_id) values (p_post, auth.uid()); return true;
end $$;

-- Editar a própria publicação
create or replace function public.pt_editar(p_post uuid, p_texto text) returns void
language plpgsql security definer set search_path = public as $$
declare v_t text := btrim(coalesce(p_texto, ''));
begin
  if char_length(v_t) > 1000 then raise exception 'escreva no máximo 1000 letras'; end if;
  update public.posts set texto = v_t, editado = true
   where id = p_post and autor_id = auth.uid() and espaco_id = public.pt_comunidade()
     and (char_length(v_t) >= 1 or foto is not null);
  if not found then raise exception 'só pode editar as suas publicações'; end if;
end $$;

-- Equipe: ocultar / mostrar de novo (nada é apagado)
create or replace function public.pt_ocultar(p_post uuid, p_oculto boolean) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.pt_e_equipe_com() then raise exception 'só a equipe pode ocultar'; end if;
  update public.posts set oculto = p_oculto where id = p_post and espaco_id = public.pt_comunidade();
end $$;

-- Denunciar (com 3 denúncias de pessoas diferentes, oculta sozinha até a equipe rever)
create or replace function public.pt_denunciar(p_post uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.posts x where x.id = p_post and x.espaco_id = public.pt_comunidade()) then
    raise exception 'publicação não encontrada'; end if;
  insert into public.denuncias(post_id, user_id) values (p_post, auth.uid()) on conflict do nothing;
  if (select count(*) from public.denuncias d where d.post_id = p_post) >= 3 then
    update public.posts set oculto = true where id = p_post and not equipe;
  end if;
end $$;

-- Quantas publicações novas de outras pessoas desde uma data (para o sino da equipe)
create or replace function public.pt_novos(p_desde timestamptz) returns table(n int, ultimo timestamptz)
language sql security definer stable set search_path = public as $$
  select count(*)::int, max(p.created_at) from public.posts p
  where p.espaco_id = public.pt_comunidade() and p.pai_id is null and not p.oculto
    and p.autor_id is distinct from auth.uid() and p.created_at > p_desde $$;

-- Perfil: nome a mostrar (só para a equipe escolher) e foto
create or replace function public.pt_meu_perfil() returns table(nome text, foto_v bigint)
language sql security definer stable set search_path = public as $$
  select pf.nome, pf.foto_v from public.perfis pf where pf.user_id = auth.uid() $$;
create or replace function public.pt_guardar_perfil(p_nome text, p_foto integer) returns bigint
language plpgsql security definer set search_path = public as $$
declare v bigint;
begin
  if public.pt_comunidade() is null then raise exception 'sem acesso à comunidade'; end if;
  insert into public.perfis(user_id) values (auth.uid()) on conflict do nothing;
  if p_nome is not null and public.pt_e_equipe_com() then
    update public.perfis set nome = nullif(left(btrim(p_nome), 30), '') where user_id = auth.uid(); end if;
  if p_foto = 1 then update public.perfis set foto_v = (extract(epoch from clock_timestamp()) * 1000)::bigint where user_id = auth.uid();
  elsif p_foto = 0 then update public.perfis set foto_v = 0 where user_id = auth.uid(); end if;
  select foto_v into v from public.perfis where user_id = auth.uid();
  return v;
end $$;

revoke all on function public.pt_feed(timestamptz, int), public.pt_comentarios(uuid), public.pt_publicar(text, uuid, text),
  public.pt_curtir(uuid), public.pt_editar(uuid, text), public.pt_ocultar(uuid, boolean), public.pt_denunciar(uuid),
  public.pt_novos(timestamptz), public.pt_meu_perfil(), public.pt_guardar_perfil(text, integer) from public, anon;
grant execute on function public.pt_feed(timestamptz, int), public.pt_comentarios(uuid), public.pt_publicar(text, uuid, text),
  public.pt_curtir(uuid), public.pt_editar(uuid, text), public.pt_ocultar(uuid, boolean), public.pt_denunciar(uuid),
  public.pt_novos(timestamptz), public.pt_meu_perfil(), public.pt_guardar_perfil(text, integer) to authenticated;

-- =====================================================================
-- FOTOS DE PERFIL (Supabase Storage): bucket privado "avatares"
-- Cada pessoa grava só em "avatares/<o seu id>/foto.jpg" (imagem pequena, máx. 150 KB).
-- Lê quem está autenticado e é da mesma comunidade.
-- =====================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatares', 'avatares', false, 153600, array['image/jpeg'])
on conflict (id) do update set public = false, file_size_limit = 153600, allowed_mime_types = array['image/jpeg'];

drop policy if exists avatares_ler on storage.objects;
create policy avatares_ler on storage.objects for select to authenticated
  using (bucket_id = 'avatares' and public.pt_comunidade() is not null
         and public.pt_comunidade_de(((storage.foldername(name))[1])::uuid) = public.pt_comunidade());
drop policy if exists avatares_criar on storage.objects;
create policy avatares_criar on storage.objects for insert to authenticated
  with check (bucket_id = 'avatares' and (storage.foldername(name))[1] = auth.uid()::text and public.pt_comunidade() is not null);
drop policy if exists avatares_atualizar on storage.objects;
create policy avatares_atualizar on storage.objects for update to authenticated
  using (bucket_id = 'avatares' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'avatares' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists avatares_apagar on storage.objects;
create policy avatares_apagar on storage.objects for delete to authenticated
  using (bucket_id = 'avatares' and (storage.foldername(name))[1] = auth.uid()::text);

-- Fotos das publicações: bucket privado "fotos-posts" (imagem reduzida, máx. 600 KB).
-- Cada pessoa grava só na sua pasta e ninguém apaga nem troca (o histórico fica).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('fotos-posts', 'fotos-posts', false, 614400, array['image/jpeg'])
on conflict (id) do update set public = false, file_size_limit = 614400, allowed_mime_types = array['image/jpeg'];
drop policy if exists fotos_posts_ler on storage.objects;
create policy fotos_posts_ler on storage.objects for select to authenticated
  using (bucket_id = 'fotos-posts' and public.pt_comunidade() is not null
         and public.pt_comunidade_de(((storage.foldername(name))[1])::uuid) = public.pt_comunidade());
drop policy if exists fotos_posts_criar on storage.objects;
create policy fotos_posts_criar on storage.objects for insert to authenticated
  with check (bucket_id = 'fotos-posts' and (storage.foldername(name))[1] = auth.uid()::text and public.pt_comunidade() is not null);
