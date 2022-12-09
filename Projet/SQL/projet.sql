DROP SCHEMA IF EXISTS projet CASCADE;
CREATE SCHEMA projet;

/**
       Une école désire développer un logiciel d’aide à la construction de groupes lors de projets.
       Avant son utilisation, le logiciel doit être initialisé par un administrateur.
       Il encodera tous les cours dans le système. Pour chaque cours, il encodera son code unique (le
       code d’un cours commence toujours par ‘BINV’ suivi de 4 chiffres), son nom, son bloc (1, 2 ou
       3) et son nombre de crédits.
       Il encodera également les étudiants dans le système. Pour chaque étudiant, il introduit son
       nom, son prénom et son email vinci (qui se termine par @student.vinci.be). Il choisira
       également un mot de passe pour cet étudiant qu’il lui communiquera par mail.
       Finalement, il encodera pour chaque cours les étudiants inscrits. Un étudiant ne peut pas être
       inscrit plusieurs fois au même cours.
       Après cette phase d’initialisation, les projets pourront être créés par les professeurs. Un projet est
       réalisé dans le cadre d’un cours et possèdera un identifiant (une chaîne de caractère), un nom, une
       date de début et une date de fin. Pour un projet, le professeur devra ensuite créer des groupes vides
       en spécifiant le nombre de groupes à créer et le nombre de place dans chaque groupe. Il pourra créer
       des groupes de tailles différentes (par exemple, 4 groupes de 4 étudiants et 3 groupes de 5 étudiants).
       Il ne pourra pas créer plus de places dans les groupes que le nombre de participants aux cours. Chaque
       groupe aura un numéro généré automatiquement. Pour un projet particulier, le premier groupe aura
       1 comme numéro, le deuxième aura 2 comme numéro, … Les numéros de groupes seront toujours
       compris entre 1 et le nombre de groupes du projet.
       Lorsque les groupes vides sont créés, les étudiants inscrits au cours peuvent se rajouter à un groupe
       ou se retirer d’un groupe. Ils ne peuvent pas se rajouter dans plusieurs groupes pour un même projet.
       Lorsqu’un groupe est complet (le nombre de membre est égal au nombre de place du groupe), le
       professeur a la possibilité de valider le groupe ce qui aura comme conséquence de rendre le groupe
       définitif : il ne sera plus possible aux membres de se retirer du groupe. On retiendra explicitement dans
       la base de données le nombre actuel de membres au sein du groupe.
       Notez que votre système ne doit être utilisé que pour une seule année académique. Pour l’année
       suivante, on vide simplement la DB.
       Le système sera découpé en deux applications java : une pour les étudiants, l’autre pour les
       administrateurs et professeurs.
    */

CREATE TABLE projet.cours
(
    code       CHARACTER(8) PRIMARY KEY CHECK ( code SIMILAR TO 'BINV[0-9][0-9][0-9][0-9]' ),
    nom        VARCHAR(20) NOT NULL CHECK ( nom <> '' ),
    bloc       INTEGER     NOT NULL CHECK (bloc IN (1, 2, 3)),
    nb_credits INTEGER     NOT NULL CHECK (nb_credits > 0)
);

CREATE TABLE projet.etudiants
(
    id     SERIAL PRIMARY KEY,
    email  VARCHAR(50) NOT NULL CHECK ( email SIMILAR TO '%[@student.vinci.be]' ),
    nom    VARCHAR(20) NOT NULL CHECK ( nom <> '' ),
    prenom VARCHAR(20) NOT NULL CHECK ( prenom <> '' ),
    mdp    VARCHAR(60) NOT NULL CHECK ( mdp <> '' ) /*crypté sur 60 caractères*/
);

CREATE TABLE projet.inscriptions_cours
(
    cours    CHARACTER(8) REFERENCES projet.cours (code) NOT NULL,
    etudiant INTEGER REFERENCES projet.etudiants (id)    NOT NULL,
    PRIMARY KEY (cours, etudiant)
);

CREATE TABLE projet.projets
(
    id          SERIAL PRIMARY KEY,
    identifiant VARCHAR(20)                                 NOT NULL,
    cours       CHARACTER(8) REFERENCES projet.cours (code) NOT NULL,
    nom         VARCHAR(20)                                 NOT NULL CHECK ( nom <> '' ),
    date_debut  TIMESTAMP                                   NOT NULL,
    date_fin    TIMESTAMP                                   NOT NULL,
    nb_groupes  INTEGER                                     NOT NULL DEFAULT 0
);

CREATE TABLE projet.groupes
(
    num        INTEGER                                NOT NULL,
    id_projet  INTEGER REFERENCES projet.projets (id) NOT NULL,
    nb_places  INTEGER                                NOT NULL,
    nb_membres INTEGER                                         DEFAULT 0,
    est_valide BOOLEAN                                NOT NULL DEFAULT FALSE,
    PRIMARY KEY (num, id_projet)
);

CREATE TABLE projet.membres_groupe
(
    etudiant INTEGER REFERENCES projet.etudiants (id) NOT NULL,
    groupe   INTEGER                                  NOT NULL,
    projet   INTEGER                                  NOT NULL,
    FOREIGN KEY (groupe, projet) REFERENCES projet.groupes (num, id_projet),
    PRIMARY KEY (etudiant, projet, groupe)
);
