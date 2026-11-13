-- =====================================================================
-- Meetly : choisir les sports pour lesquels on reçoit les notifications
-- À coller UNE SEULE FOIS dans Supabase > SQL Editor > New query > Run.
-- Ajoute une colonne "notif_sports" au profil. Vide = tous les sports.
-- Tant que ce script n'est pas lancé, l'appli continue de prévenir tout le monde
-- et la carte de choix des sports reste cachée.
-- =====================================================================
alter table public.profiles
  add column if not exists notif_sports text[];
