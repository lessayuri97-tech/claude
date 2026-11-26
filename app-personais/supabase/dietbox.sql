-- =====================================================================
-- DIETBOX: biblioteca de refeições soltas (com foto do prato e modo de preparo)
-- A equipe cria, edita e publica na Central; todas as alunas veem as publicadas.
-- Precisa do comunidade.sql já rodado (usa as mesmas regras de comunidade).
-- É seguro rodar de novo. Cole no SQL Editor do Supabase e clique em Run.
-- =====================================================================
create table if not exists public.dietbox (
  id          uuid primary key default gen_random_uuid(),
  espaco_id   uuid not null references auth.users(id) on delete cascade,
  nome        text not null check (char_length(nome) between 1 and 80),
  emoji       text not null default '🍽️' check (char_length(emoji) <= 8),
  categoria   text not null default 'outro' check (categoria in ('cafe','lanche','almoco','jantar','doce','outro')),
  tempo       int check (tempo is null or tempo between 0 and 600),
  kcal        int check (kcal is null or kcal between 0 and 5000),
  prot        numeric check (prot is null or prot between 0 and 500),
  carb        numeric check (carb is null or carb between 0 and 800),
  gord        numeric check (gord is null or gord between 0 and 500),
  ingredientes text not null default '' check (char_length(ingredientes) <= 2000),
  preparo     text not null default '' check (char_length(preparo) <= 4000),
  foto        text,
  publicado   boolean not null default false,
  created_at  timestamptz not null default now(),
  atualizado  timestamptz not null default now()
);
create index if not exists dietbox_idx on public.dietbox(espaco_id, created_at desc);
alter table public.dietbox enable row level security;
revoke all on public.dietbox from anon, authenticated;

drop function if exists public.pt_db_lista();
create or replace function public.pt_db_lista()
returns table(id uuid, nome text, emoji text, categoria text, tempo int, kcal int, prot numeric, carb numeric, gord numeric,
              ingredientes text, preparo text, foto text, publicado boolean, atualizado timestamptz)
language sql security definer stable set search_path = public as $$
  select d.id, d.nome, d.emoji, d.categoria, d.tempo, d.kcal, d.prot, d.carb, d.gord, d.ingredientes, d.preparo, d.foto, d.publicado, d.atualizado
  from public.dietbox d
  where d.espaco_id = public.pt_comunidade() and (d.publicado or public.pt_e_equipe_com())
  order by d.created_at desc limit 300 $$;

create or replace function public.pt_db_guardar(p_id uuid, p_nome text, p_emoji text, p_cat text, p_tempo int, p_kcal int,
  p_prot numeric, p_carb numeric, p_gord numeric, p_ing text, p_prep text, p_foto text, p_pub boolean) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_esp uuid := public.pt_comunidade(); v_id uuid;
begin
  if v_esp is null or not public.pt_e_equipe_com() then raise exception 'só a equipe pode editar o Dietbox'; end if;
  if btrim(coalesce(p_nome, '')) = '' then raise exception 'escreva o nome da refeição'; end if;
  if p_foto is not null and p_foto <> '' and p_foto !~ ('^' || auth.uid()::text || '/[a-z0-9_-]{6,60}\.jpg$') then raise exception 'foto inválida'; end if;
  if p_id is null then
    insert into public.dietbox(espaco_id, nome, emoji, categoria, tempo, kcal, prot, carb, gord, ingredientes, preparo, foto, publicado)
    values (v_esp, left(btrim(p_nome), 80), coalesce(nullif(btrim(p_emoji), ''), '🍽️'), coalesce(p_cat, 'outro'), p_tempo, p_kcal, p_prot, p_carb, p_gord,
            coalesce(p_ing, ''), coalesce(p_prep, ''), nullif(p_foto, ''), coalesce(p_pub, false)) returning id into v_id;
  else
    update public.dietbox set nome = left(btrim(p_nome), 80), emoji = coalesce(nullif(btrim(p_emoji), ''), '🍽️'), categoria = coalesce(p_cat, 'outro'),
      tempo = p_tempo, kcal = p_kcal, prot = p_prot, carb = p_carb, gord = p_gord, ingredientes = coalesce(p_ing, ''), preparo = coalesce(p_prep, ''),
      foto = case when p_foto is null then foto else nullif(p_foto, '') end, publicado = coalesce(p_pub, publicado), atualizado = now()
     where id = p_id and espaco_id = v_esp returning id into v_id;
    if v_id is null then raise exception 'refeição não encontrada'; end if;
  end if;
  return v_id;
end $$;

create or replace function public.pt_db_publicar(p_id uuid, p_pub boolean) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.pt_e_equipe_com() then raise exception 'só a equipe pode publicar'; end if;
  update public.dietbox set publicado = p_pub, atualizado = now() where id = p_id and espaco_id = public.pt_comunidade();
  if not found then raise exception 'refeição não encontrada'; end if;
end $$;

create or replace function public.pt_db_apagar(p_id uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.pt_e_equipe_com() then raise exception 'só a equipe pode apagar'; end if;
  delete from public.dietbox where id = p_id and espaco_id = public.pt_comunidade();
end $$;

revoke all on function public.pt_db_lista(), public.pt_db_guardar(uuid, text, text, text, int, int, numeric, numeric, numeric, text, text, text, boolean),
  public.pt_db_publicar(uuid, boolean), public.pt_db_apagar(uuid) from public, anon;
grant execute on function public.pt_db_lista(), public.pt_db_guardar(uuid, text, text, text, int, int, numeric, numeric, numeric, text, text, text, boolean),
  public.pt_db_publicar(uuid, boolean), public.pt_db_apagar(uuid) to authenticated;

-- Fotos dos pratos: bucket privado "dietbox-fotos" (máx. 600 KB). Só a equipe grava, na própria pasta; lê quem é da mesma comunidade.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('dietbox-fotos', 'dietbox-fotos', false, 614400, array['image/jpeg'])
on conflict (id) do update set public = false, file_size_limit = 614400, allowed_mime_types = array['image/jpeg'];
drop policy if exists dietbox_fotos_ler on storage.objects;
create policy dietbox_fotos_ler on storage.objects for select to authenticated
  using (bucket_id = 'dietbox-fotos' and public.pt_comunidade() is not null
         and public.pt_comunidade_de(((storage.foldername(name))[1])::uuid) = public.pt_comunidade());
drop policy if exists dietbox_fotos_criar on storage.objects;
create policy dietbox_fotos_criar on storage.objects for insert to authenticated
  with check (bucket_id = 'dietbox-fotos' and (storage.foldername(name))[1] = auth.uid()::text and public.pt_e_equipe_com());
