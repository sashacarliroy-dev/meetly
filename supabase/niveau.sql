-- Meetly : niveau de l'utilisateur (Profil) et niveau des activités.
-- À lancer une fois dans Supabase > SQL Editor. Sans risque si les colonnes existent déjà.
alter table public.activities add column if not exists level text default 'all';
alter table public.profiles   add column if not exists level text;
