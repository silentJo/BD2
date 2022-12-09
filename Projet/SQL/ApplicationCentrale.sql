
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
    RAISE NOTICE 'Encodage d''un nouveau cours';
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
    RAISE NOTICE 'Encodage d''un nouvel étudiant';
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
    RAISE NOTICE 'Création d''un projet';
    INSERT INTO projet.projets
    VALUES (DEFAULT, nid, ncours, nnom, ndate_debut, ndate_fin, DEFAULT)
    RETURNING id INTO ret;
    RETURN ret;
END ;
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
 */
CREATE OR REPLACE VIEW projet.visualiser_compo_projet AS
SELECT DISTINCT g.num                        AS "Numéro",
                e.nom                        AS "Nom",
                e.prenom                     AS "Prénom",
                (g.nb_places = g.nb_membres) AS "Complet ?",
                g.est_valide                 AS "Validé ?",
                p.identifiant                AS "Identifiant"
FROM projet.groupes g
         LEFT JOIN projet.membres_groupe mg ON g.num = mg.groupe AND g.id_projet = mg.projet
         LEFT JOIN projet.etudiants e ON mg.etudiant = e.id
         LEFT JOIN projet.projets p ON p.id = g.id_projet
GROUP BY g.num, e.nom, e.prenom, g.nb_places, g.nb_membres, g.est_valide, p.identifiant
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
    RAISE NOTICE 'Valider le groupe % du projet %', nnum_groupe, nidentifiant;
    projetiD := (SELECT P.id FROM projet.projets p WHERE p.identifiant = nidentifiant);
    groupeRecherche := (SELECT * FROM projet.groupes g WHERE g.num = nnum_groupe AND g.id_projet = projetId);

    IF (groupeRecherche.nb_membres < groupeRecherche.nb_places) THEN
        RAISE EXCEPTION 'Le groupe est incomplet et ne peut pas être validé';
    END IF;

    UPDATE projet.groupes g
    SET est_valide = TRUE
    WHERE g.id_projet = projetId
      AND g.num = nnum_groupe;
END;
$$ LANGUAGE plpgsql;


/* TODO rework
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
    RAISE NOTICE 'Valider tous les groupes du projet %', nidentifiant;
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
