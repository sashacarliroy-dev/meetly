-- =====================================================================
-- Meetly : rappel la veille d'une activité
-- Chaque jour à 18h (heure de Paris en hiver), envoie une notification
-- aux participants des activités du lendemain, via la fonction send-push.
--
-- À coller UNE SEULE FOIS dans Supabase > SQL Editor > New query > Run.
-- Avant de lancer : remplace COLLE_ICI_TA_CLE_SERVICE_ROLE (ligne ~22)
-- par ta clé "service_role" (Project Settings > API Keys).
-- La clé est rangée dans le coffre-fort de Supabase (Vault), pas dans le code.
-- =====================================================================

-- 1. Outils nécessaires : planificateur (pg_cron) et appels web (pg_net)
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- 2. Ranger la clé dans le coffre-fort (ne relance pas ce bloc une 2e fois)
select vault.create_secret(
  'COLLE_ICI_TA_CLE_SERVICE_ROLE',
  'meetly_service_role_key'
);

-- 3. La fonction qui envoie les rappels
create or replace function public.meetly_rappel_veille()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  demain date := ((now() at time zone 'Europe/Paris')::date + 1);
  cle text;
  a record;
  nb integer := 0;
begin
  select decrypted_secret into cle
  from vault.decrypted_secrets
  where name = 'meetly_service_role_key'
  limit 1;

  for a in
    select act.id, act.name, act.activity_time, act.location,
           array_agg(p.user_id) as joueurs
    from activities act
    join participants p on p.activity_id = act.id
    where act.activity_date::date = demain
    group by act.id, act.name, act.activity_time, act.location
  loop
    perform net.http_post(
      url := 'https://qdtvbgkykkdxkjsfcaey.supabase.co/functions/v1/send-push',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || cle
      ),
      body := jsonb_build_object(
        'userIds', to_jsonb(a.joueurs),
        'title', 'C''est demain : ' || a.name,
        'body', coalesce(left(a.activity_time::text, 5), '') || ' · ' || coalesce(a.location, '')
                || '. Un empêchement ? Préviens le groupe dans Meetly.',
        'url', 'https://sashacarliroy-dev.github.io/meetly/'
      )
    );
    nb := nb + 1;
  end loop;

  return nb;  -- nombre d'activités rappelées
end;
$$;

-- 4. Le réveil quotidien : 17:00 UTC = 18h à Paris en hiver (19h en été)
select cron.schedule(
  'meetly-rappel-veille',
  '0 17 * * *',
  $$ select public.meetly_rappel_veille(); $$
);

-- ---------------------------------------------------------------------
-- Tester tout de suite (envoie les rappels pour demain maintenant) :
--   select public.meetly_rappel_veille();
-- Arrêter le rappel quotidien :
--   select cron.unschedule('meetly-rappel-veille');
-- ---------------------------------------------------------------------
