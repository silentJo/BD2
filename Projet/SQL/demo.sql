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
/* Vous pouvez par exemple créer une procédure stockée, ou bien avoir les quelques lignes de SQL prêtes
à être exécutées quelque part. Il est inutile de remettre à zéro les séquences, ni de recréer tout le
schéma de la BD, mais vous pouvez le faire si vous le souhaitez.
Le scénario se déroule sur 2 PC en parallèle. L’application centrale est ouverte sur le premier et
l’application utilisateur est ouverte sur le deuxième.
Le scénario se déroule dans eclipse ou intelliJ. On ouvrira plusieurs consoles en parallèle.
Les étapes à effectuer sont les suivantes (les étapes commençant par __ ne devraient pas fonctionner) :*/

 /*  1. Sur l’application centrale :*/
--a. Ajouter le cours « SD2 » (code : « BINV2140 », 3 ects, bloc 2)
select * from projet.encoder_cours('BINV2140', 'SD 2', 2, 3);
--b. Ajouter l’étudiante « Isabelle Cambron » (ic@student.vinci.be)
select * from projet.encoder_etudiant('Cambron', 'Isabelle', 'ic@student.vinci.be', '$2a$10$H/hwrpmkyTRwkAARnisq/uG91BvJuGNApOYqQSGjX3gAMPvMZ.jxm'); -- mdp = mdp
--c. __Inscrire l’étudiante Isabelle Cambron à « BINV2040 »
--call projet.inscrire_etudiant(3, 'BINV2040');
--d. Inscrire l’étudiante Isabelle Cambron à « BINV2140 »
call projet.inscrire_etudiant('ic@student.vinci.be', 'BINV2140');
--e. Inscrire l’étudiante Stéphanie Ferneeuw à « BINV2140 »
call projet.inscrire_etudiant('sf@student.vinci.be', 'BINV2140');
--f. Inscrire l’étudiante Christophe Damas à « BINV2140 »
call projet.inscrire_etudiant('cd@student.vinci.be', 'BINV2140');
--g. Créer le projet suivant pour BINV2140 : « projet SD2 » (nom), « projSD »(identifiant),
--« 1/03/2023 » (date début), « 1/4/2023 »(date fin).
select * from projet.creer_projet('projSD', 'BINV2140','projet SD2','2023/03/01','2023/04/01');
--h. __Créer 2 groupes de 2 pour le projet projSD
--call projet.creer_groupes('projSD', 2, 2);
--i. Créer 1 groupe de 1 pour le projet projSD
call projet.creer_groupes('projSD', 1, 1);
--j. __Créer 3 groupes de 1 pour le projet projSD
--call projet.creer_groupes('projSD', 3, 1);
--k. Créer 1 groupe de 2 pour le projet projSD
call projet.creer_groupes('projSD', 1, 2);
select * from projet.groupes;
--l. __Créer 2 groupes de 2 pour le projet Javascript
--call projet.creer_groupes('Javascript', 2, 2);
--m. Visualiser les cours
select * from projet.visualiser_cours;
--n. Visualiser tous les projets
select * from projet.visualiser_projets;
--o. Visualiser toutes les compositions de groupes du projet projSD
select * from projet.visualiser_compo_projet where "Identifiant" = 'projSD';
--2. Authentifier Damas
--a. Visualiser les cours auxquels il participe
select * from projet.visualiser_mes_cours where "etudiant" = 1;
--b. Se rajouter au groupe 1 du projet projSD
select * from projet.inscription_groupe(1, 'projSD', 1);
--c. __Se rajouter au groupe 2 du projet projSD
--select * from projet.inscription_groupe(1, 'projSD', 2);
--d. Se retirer du projet projSD
call projet.retirer_du_groupe(1, 1, 'projSD');
--e. Se rajouter au groupe 2 du projet projSD
select * from projet.inscription_groupe(1, 'projSD', 2);
--f. __Se retirer du projet projSQL
--call projet.retirer_du_groupe(1, 1, 'projSD');
--g. Visualiser tous les projets des cours auxquels il est inscrit
select * from projet.visualiser_mes_projets where "Etudiant" = 1;
--h. Visualiser tous les projets pour lesquels il n’a pas encore de groupe
select * from projet.visualiser_mes_projets_sans_groupes where "Etudiant" = 1;
--i. Visualiser toutes les compositions de groupes incomplets du projet projSD
select * from projet.visualiser_groupes_incomplets (VARCHAR(20) 'projSD') where "Etudiant" = 1;
--3. Retour sur l’application centrale
--a. __Valider le groupe 2 du projet projSD
--call projet.valider_groupe('projSD', 2);
--b. __Valider le groupe 3 du projet projSD
--
--c. Visualiser toutes les compositions du groupe du projet projSD
select * from projet.visualiser_compo_projet where "Identifiant" = 'projSD';
--4. Authentifier Ferneeuw
--a. Se rajouter au groupe 2 du projet projSD
select * from projet.inscription_groupe(2, 'projSD', 2);
--b. Visualiser toutes les compositions de groupes incomplets du projet projSD
select * from projet.visualiser_compo_projet where "Identifiant" = 'projSD';
--5. Retour à l’application centrale
--a. __Valider tous les groupes du projSD
--call projet.valider_groupes('projSD');
--b. Visualiser toutes les compositions du groupe du projet projSD
select * from projet.visualiser_compo_projet where "Identifiant" = 'projSD';
--6. Authentifier Cambron
--a. __Se rajouter au groupe 1 du projet projSQL
--
--b. __Se rajouter au groupe 2 du projet projSD
--
--c. Se rajouter au groupe 1 du projet projSD
select * from projet.inscription_groupe(3, 'projSD', 1);
--7. Retour à l’application centrale
--a. Visualiser tous les projets
select * from projet.visualiser_projets;
--b. Visualiser toutes les compositions de groupe du projet projSD
select * from projet.visualiser_compo_projet where "Identifiant" = 'projSD';
--c. Valider le groupe 2 du projet projSD
call projet.valider_groupe('projSD', 2);
--d. Visualiser toutes les compositions du groupe du projet projSD
select * from projet.visualiser_compo_projet where "Identifiant" = 'projSD';
--e. Valider tous les groupes du projSD
call projet.valider_groupes('projSD');
--f. Visualiser tous les projets
select * from projet.visualiser_projets;
--8. Retour à Damas
---a. __Se retirer du projSD
--
