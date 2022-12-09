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
    id_etudiant := (SELECT e.id FROM projet.etudiants e WHERE e.email = nemail);
    RAISE NOTICE 'Inscrire l''étudiant % au cours %', id_etudiant, ncode;
    IF (id_etudiant <> -1) THEN
    ELSE
        RAISE EXCEPTION 'L''email % n''existe pas', nemail;
    END IF;
    INSERT INTO projet.inscriptions_cours
    VALUES (ncode, id_etudiant);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION projet.check_inscription_valide() RETURNS TRIGGER AS
$$
BEGIN
    RAISE NOTICE 'Vérification des données fournies ...';
    IF (NOT EXISTS(SELECT 1 FROM projet.cours c WHERE c.code = new.cours)) THEN
        RAISE EXCEPTION 'Le cours % n''existe pas', new.cours;
    ELSEIF (NOT EXISTS(SELECT 1 FROM projet.etudiants e WHERE e.id = new.etudiant)) THEN
        RAISE EXCEPTION 'L''étudiant % n''existe pas', new.etudiant;
    ELSEIF (EXISTS(SELECT 1 FROM projet.projets p WHERE p.cours = new.cours)) THEN
        RAISE EXCEPTION 'Inscription impossible car le cours % contient déjà un projet', new.cours;
    END IF;
    RETURN new;
END ;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_check_inscription_valide
    BEFORE INSERT
    ON projet.inscriptions_cours
    FOR EACH ROW
EXECUTE PROCEDURE projet.check_inscription_valide();

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

CREATE OR REPLACE FUNCTION projet.check_projet_valide() RETURNS TRIGGER AS
$$
BEGIN
    RAISE NOTICE 'Vérification des données fournies ...';
    IF (NOT EXISTS(SELECT 1 FROM projet.cours c WHERE c.code = new.cours)) THEN
        RAISE EXCEPTION 'Le cours % n''existe pas', new.cours;
    END IF;
    RETURN new;
END ;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_check_projet_valide
    BEFORE INSERT OR UPDATE
    ON projet.projets
    FOR EACH ROW
EXECUTE PROCEDURE projet.check_projet_valide();

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
                INSERT INTO projet.groupes VALUES (nb_groupes_actuel, id_projet, nnb_places, DEFAULT, DEFAULT);
            END LOOP;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION projet.check_groupe_valide() RETURNS TRIGGER AS
$$
BEGIN
    RAISE NOTICE 'Vérification des données fournies ...';
    IF (NOT EXISTS(SELECT 1 FROM projet.projets p WHERE p.id = new.id_projet)) THEN
        RAISE EXCEPTION 'Le projet % n''existe pas', new.id_projet;
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_check_groupe_valide
    BEFORE INSERT OR UPDATE
    ON projet.groupes
    FOR EACH ROW
EXECUTE PROCEDURE projet.check_groupe_valide();

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
    projetID INTEGER;
BEGIN
    projetID := (SELECT p.id FROM projet.projets p WHERE p.identifiant = nidentifiant);

    UPDATE projet.groupes g
    SET est_valide = TRUE
    WHERE g.id_projet = projetID
      AND g.num = nnum_groupe;
    RAISE NOTICE 'Groupe % du projet % validé!', nnum_groupe, nidentifiant;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION projet.check_groupe_complet() RETURNS TRIGGER AS
$$
BEGIN
    RAISE NOTICE 'Vérification du groupe ...';
    /* quand on essaie de valider un groupe incomplet */
    IF (new.est_valide AND old.nb_membres < old.nb_places) THEN
        RAISE EXCEPTION 'Le groupe est incomplet et ne peut pas être validé';
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_check_groupe_complet
    BEFORE UPDATE
    ON projet.groupes
    FOR EACH ROW
EXECUTE PROCEDURE projet.check_groupe_complet();

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




--============================================================================
--=                            APPLICATION ETUDIANT                          =
--============================================================================
--=                              0) SE CONNECTER                             =
--============================================================================
create or replace function projet.seConnecter(nemail VARCHAR(50)) RETURNS RECORD AS
$$
    DECLARE
        ETUDIANT record;
    BEGIN
        SELECT id, mdp FROM projet.etudiants WHERE email = nemail INTO etudiant;
        RETURN etudiant;
    END;
$$ language plpgsql;

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
--=                 2) INSCRIPTION AU GROUPE D'UN PROJET                     =
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
    RAISE NOTICE 'Inscription de l''étudiant % au groupe % du projet %', nid_etudiant, nnum_groupe, nidentifiant;
    id_projet := (SELECT p.id FROM projet.projets p WHERE p.identifiant = nidentifiant);

    INSERT INTO projet.membres_groupe(etudiant, groupe, projet)
    VALUES (nid_etudiant, nnum_groupe, id_projet)
    RETURNING * INTO new_member;
    RETURN new_member;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION projet.valider_inscription_groupe() RETURNS TRIGGER AS
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

CREATE OR REPLACE TRIGGER trigger_valider_inscription_groupe
    BEFORE INSERT
    ON projet.membres_groupe
    FOR EACH ROW
EXECUTE FUNCTION projet.valider_inscription_groupe();
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

CREATE OR REPLACE TRIGGER trigger_check_etudiant_inscrit_au_cours
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


CREATE OR REPLACE TRIGGER trigger_decrementer_nb_membres
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
       g.num       AS "Num groupe", /*groupe DONT IL FAIT PARTIE ou <null>*/
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
SELECT p.identifiant         AS "Identifiant",
       p.nom        AS "Nom",
       c.code      as "Cours",
       p.date_debut AS "Début",
       p.date_fin   AS "Fin",
       ic.etudiant  AS "Etudiant"
FROM projet.projets p
         LEFT JOIN projet.cours c ON p.cours = c.code
         LEFT JOIN projet.inscriptions_cours ic ON c.code = ic.cours
WHERE p.nb_groupes = 0
group by p.identifiant, p.nom, c.code, p.date_debut, p.date_fin, ic.etudiant;


--============================================================================
--=                    6) VISUALISER GROUPES INCOMPLETS                      =
--============================================================================
/**
    Visualiser toutes les compositions de groupes incomplets d’un projet (en donnant
    l’identifiant du projet). On affichera le numéro de groupe, le nom et prénom de l’étudiant et
    le nombre de places restantes dans le groupe. Les résultats seront triés par numéro de
    groupe.
 */
CREATE OR REPLACE FUNCTION projet.visualiser_groupes_incomplets(netudiant integer, nidentifiant VARCHAR(20)) RETURNS SETOF RECORD AS
$$
DECLARE
    record record;
BEGIN
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
      and e.id = netudiant
      AND p.identifiant = nidentifiant
      AND g.nb_membres < g.nb_places
    group by g.num, e.nom, e.prenom, (g.nb_places - g.nb_membres), e.id, p.identifiant
    into record;
    return next record;
END;
$$language plpgsql;
