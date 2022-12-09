/* Projet de Gestion de Données : scénario de démo
Durant la semaine 13, chaque groupe proposera une démonstration de son application en réalisant un
scénario imposé sur les machines de l’école. Ce scénario vous étant donné en avance, il est inexcusable
qu’il ne s’exécute pas correctement. Prenez vos précautions et testez-le à l’avance !
Avant la démo, vous viderez la DB, */
truncate TABLE projet.inscriptions_cours restart identity CASCADE;
truncate TABLE projet.cours restart identity CASCADE;
truncate TABLE projet.membres_groupe restart identity CASCADE;
truncate TABLE projet.groupes restart identity CASCADE;
truncate TABLE projet.projets restart identity CASCADE;
truncate TABLE projet.etudiants restart identity CASCADE;
-- ensuite vous ajouterez les cours suivants : « BD2 » (code : « BINV2040 », 6 ects, bloc 2)*/
select * from projet.encoder_cours('BINV2040', 'BD 2', 2, 6);
--et « APOO » (code : « BINV1020 », 6 etcs, bloc 1).
select * from projet.encoder_cours('BINV1020', 'APOO', 1, 6);
--Il faut également ajouter deux étudiants :
--« Christophe Damas » (cd@student.vinci.be)
select * from projet.encoder_etudiant('Damas', 'Christophe', 'cd@student.vinci.be', '$2a$10$H/hwrpmkyTRwkAARnisq/uG91BvJuGNApOYqQSGjX3gAMPvMZ.jxm'); -- mdp = mdp
--et « Stéphanie Ferneeuw » (sf@student.vinci.be).
select * from projet.encoder_etudiant('Ferneeuw', 'Stéphanie', 'sf@student.vinci.be', '$2a$10$H/hwrpmkyTRwkAARnisq/uG91BvJuGNApOYqQSGjX3gAMPvMZ.jxm'); -- mdp = mdp
--Les deux étudiants sont inscrits au cours de BD2.
call projet.inscrire_etudiant('cd@student.vinci.be', 'BINV2040');
call projet.inscrire_etudiant('sf@student.vinci.be', 'BINV2040');
-- BD2 contient deux projet avec les infos suivantes :
--« projet SQL » (nom : « projet SQL », identifiant : « projSQL », date début : « 10/09/2023 », date fin : « 15/12/2023 »)
select * from projet.creer_projet( 'projSQL','BINV2040', 'projet SQL', '2023-09-10', '2023/12/15');
-- et «DSD» (nom : « DSD », identifiant : « dsd », date début : « 30/09/2023 », date fin : « 1/12/2023 ») .
select * from projet.creer_projet('dsd', 'BINV2040', 'DSD', '2023-09-30', '2023/12/1');
-- Vous ajouterez un groupe vide de 2 étudiants au projet SQL.
call projet.creer_groupes('projSQL', 1, 2);
