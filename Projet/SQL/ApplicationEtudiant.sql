
--============================================================================
--=                            APPLICATION ETUDIANT                          =
--============================================================================



--============================================================================
--=                     1) VISUALISER MES COURS                              =
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
    Ci-dessous, voici une visualisation pour un projet contenant 2 groupes incomplets. Le
    premier groupe incomplet (groupe numéro 4) est composé de 2 étudiants mais il reste
    encore une place. Le deuxième (groupe numéro 7) est vide ; deux places sont disponibles
    dans ce groupe.
    Numéro      Nom         Prénom      Nombre de places
    4           damas       christophe  1
    4           ferneeuw    stéphanie   1
    7           null        null        2
 */
CREATE OR REPLACE FUNCTION projet.visualiser_groupes_incomplets(nidentifiant VARCHAR(20)) RETURNS  VOID AS
$$
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
      AND p.identifiant = nidentifiant
      AND g.nb_membres < g.nb_places
    group by g.num, e.nom, e.prenom, (g.nb_places - g.nb_membres), e.id, p.identifiant;
END;
$$language plpgsql;