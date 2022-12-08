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

--============================================================================
--=                            APPLICATION CENTRALE                          =
--============================================================================

--============================================================================
--=                         1) ENCODER COURS                                 =
--============================================================================
CREATE OR REPLACE FUNCTION projet.encoder_cours(ncode CHARACTER(8), nnom VARCHAR(20), nbloc INTEGER,
                                                ncredits INTEGER) RETURNS VARCHAR(8) AS
$$
DECLARE
    ret VARCHAR(8);
BEGIN
    RAISE NOTICE 'coder cours';
    INSERT INTO projet.cours
    VALUES (ncode, nnom, nbloc, ncredits)
    RETURNING ncode INTO ret;
    RETURN ret;
END;
$$ LANGUAGE plpgsql;

--============================================================================
--=                         2) ENCODER ETUDIANT                              =
--============================================================================
CREATE OR REPLACE FUNCTION projet.encoder_etudiant(nnom VARCHAR(20), nprenom VARCHAR(20), nemail VARCHAR(50),
                                                   nmdp VARCHAR(20)) RETURNS INTEGER AS
$$
DECLARE
    ret INTEGER;
BEGIN
    RAISE NOTICE 'encoder etudiant';
    INSERT INTO projet.etudiants
    VALUES (DEFAULT, nemail, nprenom, nnom, nmdp)
    RETURNING id INTO ret;
    RETURN ret;
END;
$$ LANGUAGE plpgsql;

--============================================================================
--=                         3) INSCRIRE ETUDIANT                             =
--============================================================================
/**
    Inscrire un étudiant à un cours (en donnant l’adresse mail de l’étudiant et le code unique du
    cours) . On ne peut inscrire un étudiant à un cours si le cours contient déjà un projet.
 */
CREATE OR REPLACE PROCEDURE projet.inscrire_etudiant(nemail VARCHAR(50), ncode CHARACTER(8)) AS
$$
DECLARE
    id_etudiant INTEGER := -1;
BEGIN
    RAISE NOTICE 'Inscrire un etudiant';
    id_etudiant := (SELECT e.id FROM projet.etudiants e WHERE e.email = nemail);
    IF (id_etudiant <> -1) THEN
    ELSE
        RAISE EXCEPTION 'L''email % n''existe pas', nemail;
    END IF;
    INSERT INTO projet.inscriptions_cours
    VALUES (ncode, id_etudiant);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION projet.check_cours_existant() RETURNS TRIGGER AS
$$
BEGIN
    RAISE NOTICE 'trigger cours existant';
    IF (NOT EXISTS(SELECT 1 FROM projet.cours c WHERE c.code = new.cours))
    THEN
        RAISE EXCEPTION 'Le cours renseigné n existe pas';
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_cours_existant
    BEFORE INSERT
    ON projet.inscriptions_cours
    FOR EACH ROW
EXECUTE PROCEDURE projet.check_cours_existant();

CREATE OR REPLACE FUNCTION projet.check_cours_avec_projet() RETURNS TRIGGER AS
$$
BEGIN
    RAISE NOTICE 'trigger cours avec projet';
    IF (EXISTS(SELECT 1 FROM projet.projets p WHERE (p.cours = new.cours)))
    THEN
        RAISE EXCEPTION 'Le cours contient déjà un projet';
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_cours_avec_projet
    AFTER INSERT
    ON projet.inscriptions_cours
    FOR EACH ROW
EXECUTE PROCEDURE projet.check_cours_avec_projet();

--============================================================================
--=                         4) CREER PROJET                                  =
--============================================================================
CREATE OR REPLACE FUNCTION projet.creer_projet(nid VARCHAR(20), ncours CHARACTER(8), nnom VARCHAR(20),
                                               ndate_debut TIMESTAMP,
                                               ndate_fin TIMESTAMP) RETURNS INTEGER AS
$$
DECLARE
    ret INTEGER;
BEGIN
    RAISE NOTICE 'creer projet';
    INSERT INTO projet.projets
    VALUES (DEFAULT, nid, ncours, nnom, ndate_debut, ndate_fin, DEFAULT)
    RETURNING id INTO ret;
    RETURN ret;
END;
$$ LANGUAGE plpgsql;

--============================================================================
--=                         5) CREER GROUPES                                 =
--============================================================================
/**
    Créer des groupes pour un projet. Pour cela, le professeur devra encoder l’identifiant du projet,
    le nombre de groupes à créer et le nombre de places par groupe. S’il veut créer des groupes de tailles différentes,
    il devra faire appel plusieurs fois à la fonctionnalité. La création
    échouera si le nombre de places dans les groupes du projet dépassent le nombre d’inscrits au
    cours. Dans ce cas, aucun groupe ne sera créé.
 */
CREATE OR REPLACE PROCEDURE projet.creer_groupes(nidentifiant_projet VARCHAR(20), nnb_groupes INTEGER,
                                                 nnb_places INTEGER) AS
$$
DECLARE
    nb_membres_max    INTEGER := 0;
    nb_membres_actuel INTEGER := 0;
    nb_groupes_actuel INTEGER := 0;
    nb_membres_crees  INTEGER := 0;
    id_projet         INTEGER := -1;
BEGIN
    RAISE NOTICE 'Créer les groupes pour le projet %', nidentifiant_projet;
    id_projet := (SELECT p.id FROM projet.projets p WHERE p.identifiant = nidentifiant_projet);

    IF (id_projet <> -1) THEN
    ELSE
        RAISE EXCEPTION 'Le projet % est introuvable', nidentifiant_projet;
    END IF;

    nb_membres_max := (SELECT COUNT(i.etudiant)
                       FROM projet.inscriptions_cours i
                       WHERE cours =
                             (SELECT p.cours
                              FROM projet.projets p
                              WHERE p.identifiant = nidentifiant_projet));
    nb_membres_crees := nnb_groupes * nnb_places;

    IF (nb_membres_crees > nb_membres_max) THEN
        RAISE EXCEPTION 'Le nombre de places totales à créer (%) excède le nombre d''étudiants inscrits (%) au cours', nb_membres_crees, nb_membres_max;
    ELSE
        RAISE NOTICE 'Places à créer = % / Nombre d''étudiants inscrits = %', nb_membres_crees, nb_membres_max;
        IF (SELECT p.nb_groupes FROM projet.projets p WHERE p.id = id_projet) > 0
        THEN
            nb_membres_actuel := (SELECT COUNT(mg.etudiant)
                                  FROM projet.membres_groupe mg
                                  WHERE mg.projet = id_projet);
            nb_groupes_actuel := (SELECT p.nb_groupes
                                  FROM projet.projets p
                                  WHERE p.identifiant = nidentifiant_projet);
        END IF;
        FOR cnt IN 1 .. nnb_groupes
            LOOP
                nb_groupes_actuel := nb_groupes_actuel + 1;
                UPDATE projet.projets SET nb_groupes = nb_groupes_actuel WHERE id = id_projet;
                INSERT INTO projet.groupes
                VALUES (nb_groupes_actuel, id_projet, nnb_places, DEFAULT, DEFAULT);
            END LOOP;
    END IF;
END;
$$ LANGUAGE plpgsql;
/* TODO delete as works above
CREATE OR REPLACE FUNCTION projet.check_nb_membres_max() RETURNS trigger as
$$
DECLARE
    nb_membres_max INTEGER := 0;
BEGIN
    nb_membres_max := (SELECT count(i.etudiant)
                       FROM projet.inscriptions_cours i
                       WHERE cours =
                             (SELECT p.cours
                              FROM projet.projets p
                              WHERE p.id = new.id_projet));
    IF nb_membres_max = 0
    THEN
        RAISE exception 'Aucun élève inscrit au cours';
    END IF;
    RETURN new;
END;
$$ language plpgsql;

CREATE TRIGGER trigger_check_nb_membres_max
    BEFORE INSERT
    on projet.groupes
    FOR EACH ROW
EXECUTE PROCEDURE projet.check_nb_membres_max();
*/
/* TODO cade is above - transform to trigger?
CREATE OR REPLACE FUNCTION projet.check_cours_sans_projet() RETURNS trigger as
$$
BEGIN
    IF (NOT EXISTS(select 1 from projet.projets p WHERE (p.cours = new.cours)))
    THEN
        RAISE EXCEPTION 'Le cours ne contient aucun projet';
    END IF;
    RETURN OLD;
END;
$$ language plpgsql;

CREATE OR REPLACE TRIGGER trigger_check_cours_sans_projet
    AFTER INSERT
    on projet.inscriptions_cours
    FOR EACH ROW
EXECUTE PROCEDURE projet.check_cours_sans_projet();
*/
/*
-- todo : trigger
    IF nb_membres_crees + nb_membres_actuel > nb_membres_max
    THEN
        RAISE 'Pas assez de places restantes';
    END IF;
*/
/*
create or replace function projet.check_creer_groupes() returns trigger as
$$
DECLARE
    nb_places_desirees INTEGER := groupes.nb_membres * new.nb_places;
    nb_places_possibles Integer;
BEGIN
    nb_places_possibles = (select count(ic.etudiant)
                              from projet.inscriptions_cours ic,projet.projets p
                              where ic.cours = p.nom
                              and p.id = new.id_projet);
    raise notice 'new nb membres : %', new.nb_membres;
    raise notice 'new nb places : %', new.nb_places;
    raise notice 'nb_place_desirees : %', nb_places_desirees;
    raise notice 'nb_place_possibles : %', nb_places_possibles;
    if (nb_places_desirees > nb_places_possibles)
        then raise 'pas assez de places restantes';
    end if;
    return new;
END;
$$ language plpgsql;

create trigger trigger_check_creer_groupes
    before insert
    on projet.groupes
    for each row
execute procedure projet.check_creer_groupes();
*/
--============================================================================
--=                          6) VISUALISER COURS                             =
--============================================================================
/**
    Visualiser les cours. Pour chaque cours, on affichera son code unique, son nom et les
    identifiants de ses projets (sur une ligne, séparé par des virgules). Si le cours ne possède pas
    de projet, il sera noté « pas encore de projet ».
 */
CREATE OR REPLACE VIEW projet.visualiser_cours AS
SELECT c.code                                                         AS "code cours",
       c.nom                                                          AS "nom cours",
       COALESCE(STRING_AGG(p.id::TEXT, ', '), 'pas encore de projet') AS "id projet(s)"
FROM projet.cours c
         LEFT JOIN projet.projets p ON c.code = p.cours
GROUP BY c.code;

--============================================================================
--=                          7) VISUALISER PROJETS                           =
--============================================================================
/**
    Visualiser tous les projets. Pour chaque projet, on affichera son identifiant, son nom, le code
    unique de son cours, le nombre de groupes, le nombre de groupes complets et le nombre de
    groupes validés. Si un projet n’a pas encore de groupe, il devra également apparaître.
 */
CREATE OR REPLACE VIEW projet.visualiser_projets AS
SELECT DISTINCT p.id                                                 AS "id projet",
                p.identifiant                                        AS "identifiant",
                p.nom                                                AS "nom projet",
                p.cours                                              AS "code cours",
                p.nb_groupes                                         AS "nb groupes",
                COUNT(*) FILTER ( WHERE g.nb_membres = g.nb_places ) AS "nb groupes complets",
                COUNT(*) FILTER ( WHERE g.est_valide IS TRUE )       AS "nb groupes valides"
FROM projet.projets p
         LEFT JOIN projet.groupes g ON p.id = g.id_projet
GROUP BY p.id, p.nom, p.cours, p.nb_groupes
ORDER BY p.id;

--============================================================================
--=                     8) VISUALISER COMPO PROJET                           =
--============================================================================
/**
    Visualiser toutes les compositions de groupe d’un projet (en donnant l’identifiant de projet).
    Les résultats seront affichés sur 5 colonnes. On affichera le numéro de groupe, le nom et
    prénom de l’étudiant, si le groupe est complet, et si le groupe a été validé. Tous les numéros
    de groupe doivent apparaître même si les groupes correspondants sont vides. SI un groupe est
    vide, on affichera null pour le nom et prénom de l’étudiant. Les résultats seront triés par
    numéro de groupe.
    Ci-dessous, voici une visualisation pour un projet composé de 3 groupes de 2 étudiants. Le
    premier groupe n’est pas complet et est composé d’un seul étudiant. Le deuxième est complet
    et validé. Le troisième groupe est vide.
    Numéro  Nom         Prénom          Complet ?   Validé ?
    1       damas       christophe      false       false
    2       ferneeuw    stéphanie       true        true
    2       lehmann     brigitte        true        true
    3       null        null            false       false
 */
CREATE OR REPLACE VIEW projet.visualiser_compo_projet AS
SELECT DISTINCT g.num                        AS "Numéro",
                e.nom                        AS "Nom",
                e.prenom                     AS "Prénom",
                (g.nb_places = g.nb_membres) AS "Complet ?",
                g.est_valide                 AS "Validé ?",
                g.id_projet                  AS "ProjetID",
                p.identifiant                AS "Identifiant"
FROM projet.groupes g
         LEFT JOIN projet.membres_groupe mg ON g.num = mg.groupe AND g.id_projet = mg.projet
         LEFT JOIN projet.etudiants e ON mg.etudiant = e.id
         LEFT JOIN projet.projets p ON p.id = g.id_projet
GROUP BY g.num, e.nom, e.prenom, g.nb_places, g.nb_membres, g.est_valide, g.id_projet, p.identifiant
ORDER BY g.num;

--============================================================================
--=                         9) VALIDER GROUPE                                =
--============================================================================
/**
    Valider un groupe. Pour cela, le professeur devra encoder l’identifiant du projet et le numéro
    de groupe. La validation échouera si le groupe n’est pas complet.
*/
CREATE OR REPLACE PROCEDURE projet.valider_groupe(nidentifiant VARCHAR(20), nnum_groupe INTEGER) AS
$$
DECLARE
    projetid        INTEGER;
    groupeRecherche projet.groupes%ROWTYPE;
BEGIN
    RAISE NOTICE 'valider groupe';
    projetiD := (SELECT P.id FROM projet.projets p WHERE p.identifiant = nidentifiant);
    groupeRecherche := (SELECT * FROM projet.groupes g WHERE g.num = nnum_groupe AND g.id_projet = projetId);

    IF (groupeRecherche.nb_membres < groupeRecherche.nb_places)
    THEN
        RAISE EXCEPTION 'groupe incomplet';
    END IF;

    UPDATE projet.groupes g
    SET est_valide = TRUE
    WHERE g.id_projet = projetId
      AND g.num = nnum_groupe;
END;
$$ LANGUAGE plpgsql;
/*
CREATE OR REPLACE FUNCTION projet.check_groupe_complet() RETURNS trigger as
$$
DECLARE

BEGIN
    raise notice 'trigger groupe complet';
    IF (new.nb_membres < new.nb_places)
    THEN
        RAISE EXCEPTION 'Le groupe n est pas complet';
    END IF;
    RETURN NEW;
END
$$ language plpgsql;

CREATE TRIGGER trigger_check_groupe_complet
    BEFORE UPDATE
    on projet.groupes
    FOR EACH ROW
EXECUTE PROCEDURE projet.check_groupe_complet();
*/
--============================================================================
--=                        10) VALIDER GROUPES                               =
--============================================================================
/**
    Valider tous les groupes d’un projet. Si un des groupes n’est pas complet, alors aucun groupe
    ne sera validé.
 */
CREATE OR REPLACE PROCEDURE projet.valider_groupes(nidentifiant VARCHAR(20)) AS
$$
DECLARE
    record              RECORD;
    id_projet_recherche INTEGER := 0;
BEGIN
    RAISE NOTICE 'valider groupes';
    id_projet_recherche := (SELECT p.id FROM projet.projets p WHERE p.identifiant = nidentifiant);
    FOR record IN (SELECT * FROM projet.groupes)
        LOOP
            UPDATE projet.groupes
            SET est_valide = TRUE
            WHERE id_projet = record.id_projet
              AND id_projet = id_projet_recherche
              AND num = record.num;
        END LOOP;
END;
$$ LANGUAGE plpgsql;

--TODO : trigger si 1 groupe n'est pas complet, aucun groupe ne sera validé (trigger function précédente ?)

--============================================================================
--=                            APPLICATION ETUDIANT                          =
--============================================================================

--============================================================================
--=                     1) VISUALISER MES COURS                              =
--============================================================================
/**
    Visualiser les cours auxquels il participe. Pour chaque cours, on affichera son code unique, son
    nom et les identifiants de ses projets (sur une ligne, séparé par des virgules). Si le cours ne
    possède pas de projet, il sera noté « pas encore de projet ».
 */
CREATE OR REPLACE VIEW projet.visualiser_mes_cours AS
SELECT c.code                                                         AS "code cours",
       c.nom                                                          AS "nom cours",
       COALESCE(STRING_AGG(p.id::TEXT, ', '), 'pas encore de projet') AS "id projet(s)",
       ic.etudiant                                                    AS "etudiant"
FROM projet.inscriptions_cours ic
         LEFT JOIN projet.cours c ON c.code = ic.cours
         LEFT JOIN projet.projets p ON p.cours = c.code
GROUP BY c.code, c.nom, ic.etudiant;

--============================================================================
--=                        2) INSCRIPTION AU GROUPE                          =
--============================================================================
/**
    Se rajouter dans un groupe en donnant l’identifiant de projet et le numéro de groupe.
    L’inscription échouera si le groupe est déjà complet ou si l’étudiant n’est pas inscrit au cours
    relatif à ce projet.
 */
--TODO
CREATE OR REPLACE FUNCTION projet.inscription_groupe(nid_etudiant INTEGER, nidentifiant VARCHAR(20), nnum_groupe INTEGER) RETURNS projet.membres_groupe AS
$$
DECLARE
    new_member projet.membres_groupe%ROWTYPE;
    id_projet  INTEGER := -1;
BEGIN
    RAISE NOTICE 'inscription groupe';
    id_projet := (SELECT p.id FROM projet.projets p WHERE p.identifiant = nidentifiant);
    INSERT INTO projet.membres_groupe(etudiant, groupe, projet)
    VALUES (nid_etudiant, nnum_groupe, id_projet)
    RETURNING * INTO new_member;
    RETURN new_member;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION projet.increment_membres_groupe() RETURNS TRIGGER AS
$$
DECLARE
    groupe_to_update projet.groupes%ROWTYPE;
BEGIN
    RAISE NOTICE 'increment membres groupe';
    SELECT * FROM projet.groupes g WHERE g.num = new.groupe AND g.id_projet = new.projet INTO groupe_to_update;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Le groupe % du projet % ne se trouve pas dans la table', new.groupe, new.projet;
    ELSE
        IF groupe_to_update.nb_membres < groupe_to_update.nb_places THEN
            UPDATE projet.groupes
            SET nb_membres = nb_membres + 1
            WHERE num = new.groupe
              AND id_projet = new.projet;
        ELSE
            RAISE EXCEPTION 'Le groupe est complet';
        END IF;
    END IF;
    RETURN new;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_increment_membre_groupe
    BEFORE INSERT
    ON projet.membres_groupe
    FOR EACH ROW
EXECUTE FUNCTION projet.increment_membres_groupe();
/*
CREATE OR REPLACE FUNCTION projet.check_etudiant_inscrit_au_cours() RETURNS TRIGGER AS
$$
    DECLARE
        cours integer := 0;
    BEGIN
        select c.code from projet.cours c, projet.inscriptions_cours ic where ic.etudiant = new.etudiant into cours;
        if (new.etudiant
                not in
                    (select ic.etudiant
                     from projet.inscriptions_cours ic
                     where ic.cours = cours
                       and ic.etudiant = new.etudiant))
            then
                raise exception 'Etudiant non inscrit à ce cours';
        end if;
        return new;
    END;
$$ language plpgsql;

CREATE TRIGGER trigger_check_etudiant_inscrit_au_cours
    BEFORE INSERT
    ON projet.membres_groupe
    FOR EACH ROW
EXECUTE FUNCTION projet.check_etudiant_inscrit_au_cours();
*/
--============================================================================
--=                         3) SE RETIRER DU GROUPE                          =
--============================================================================
/**
    Se retirer d’un groupe en donnant l’identifiant de projet. Le retrait échouera si le groupe a été
    validé ou si l’étudiant n’est pas encore dans un groupe.
 */
CREATE OR REPLACE PROCEDURE projet.retirer_du_groupe(nid_etudiant INTEGER, nnum_groupe INTEGER, nidentifiant VARCHAR(20)) AS
$$
DECLARE
    id_projet INTEGER := -1;
BEGIN
    id_projet := (SELECT p.id FROM projet.projets p WHERE p.identifiant = nidentifiant);
    RAISE NOTICE 'nid_etudiant : %', nid_etudiant;-- = 1
    RAISE NOTICE 'nnum_groupe : %', nnum_groupe;-- = 1
    RAISE NOTICE 'id projet : %', id_projet;-- = 3
    DELETE FROM projet.membres_groupe WHERE etudiant = nid_etudiant AND groupe = nnum_groupe AND projet = id_projet;
    RAISE NOTICE 'Le membre % du groupe % du projet % a été retiré', nid_etudiant, nnum_groupe, nidentifiant;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION projet.decrementer_nb_membres() RETURNS TRIGGER AS
$$
DECLARE
    groupe_to_update projet.groupes%ROWTYPE;
BEGIN
    SELECT * FROM projet.groupes g WHERE g.num = OLD.groupe AND g.id_projet = OLD.projet INTO groupe_to_update;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Le groupe % du projet % ne se trouve pas dans la table', OLD.groupe, OLD.projet;
    ELSEIF (SELECT g.est_valide FROM projet.groupes g WHERE g.num = old.groupe AND g.id_projet = old.projet) THEN
        RAISE EXCEPTION 'groupe % déjà validé', OLD.groupe;
    ELSE
        UPDATE projet.groupes
        SET nb_membres = nb_membres - 1
        WHERE num = OLD.groupe
          AND id_projet = OLD.projet;

        RAISE NOTICE 'Le nombre de membre du groupe % du projet % a été décrémenté', OLD.groupe, OLD.projet;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_decrementer_nb_membres
    AFTER DELETE
    ON projet.membres_groupe
    FOR EACH ROW
EXECUTE FUNCTION projet.decrementer_nb_membres();


--============================================================================
--=                           4) VISUALISER MES PROJETS                      =
--============================================================================
/**
    Visualiser tous les projets des cours auxquels il est inscrit. Pour chaque projet, on affichera son
    identifiant, son nom, l’identifiant du cours et le numéro de groupe dont il fait partie. S’il n’est
    pas encore dans un groupe, ce dernier champ sera à null.
 */
CREATE OR REPLACE VIEW projet.visualiser_mes_projets AS
SELECT p.id        AS "Identifiant projet",
       p.nom       AS "Nom projet",
       c.code      AS "Code cours",
       g.num       AS "Num groupe", /*groupe DONT IL FAIT PARTIE ou null*/
       ic.etudiant AS "Etudiant"
FROM projet.groupes g
         LEFT JOIN projet.projets p ON g.id_projet = p.id
         LEFT JOIN projet.cours c ON p.cours = c.code
         LEFT JOIN projet.inscriptions_cours ic ON c.code = ic.cours;

--============================================================================
--=                   5) VISUALISER MES PROJETS SANS GROUPES                 =
--============================================================================
/**
    Visualiser tous les projets pour lesquels il n’a pas encore de groupe. Cela n’affichera bien sûr
    que les projets faisant partie des cours où il participe. Pour chaque projet, on affichera son
    identifiant, son nom, l’identifiant du cours, sa date de début et sa date de fin.
 */
CREATE OR REPLACE VIEW projet.visualiser_mes_projets_sans_groupes AS
SELECT p.id         AS "Identifiant",
       p.nom        AS "Nom",
       p.date_debut AS "Début",
       p.date_fin   AS "Fin",
       ic.etudiant  AS "Etudiant"
FROM projet.projets p
         LEFT JOIN projet.cours c ON p.cours = c.code
         LEFT JOIN projet.inscriptions_cours ic ON c.code = ic.cours
WHERE p.nb_groupes = 0;


--============================================================================
--=                    6) VISUALISER GROUPES INCOMPLETS                      =
--============================================================================
/**
    Visualiser toutes les compositions de groupes incomplets d’un projet (en donnant
    l’identifiant du projet). On affichera le numéro de groupe, le nom et prénom de l’étudiant et
    le nombre de places restantes dans le groupe. Les résultats seront triés par numéro de
    groupe.
    Ci-dessous, voici une visualisation pour un projet contenant 2 groupes incomplets. Le
    premier groupe incomplet (groupe numéro 4) est composé de 2 étudiants mais il reste
    encore une place. Le deuxième (groupe numéro 7) est vide ; deux places sont disponibles
    dans ce groupe.
    Numéro      Nom         Prénom      Nombre de places
    4           damas       christophe  1
    4           ferneeuw    stéphanie   1
    7           null        null        2
 */
CREATE OR REPLACE VIEW projet.visualiser_groupes_incomplets AS
SELECT g.num                        AS "Numéro",
       e.nom                        AS "Nom",
       e.prenom                     AS "Prénom",
       (g.nb_places - g.nb_membres) AS "Nombre de places",
       e.id                         AS "Etudiant",
       p.identifiant                AS "Identifiant"
FROM projet.groupes g,
     projet.membres_groupe mg,
     projet.etudiants e,
     projet.projets p
WHERE g.num = mg.groupe
  AND g.id_projet = mg.projet
  AND mg.etudiant = e.id
  AND g.nb_membres < g.nb_places;
