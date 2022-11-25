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
    id         SERIAL PRIMARY KEY,
    cours      CHARACTER(8) REFERENCES projet.cours (code) NOT NULL,
    nom        VARCHAR(20)                                 NOT NULL CHECK ( nom <> '' ),
    date_debut TIMESTAMP                                   NOT NULL,
    date_fin   TIMESTAMP                                   NOT NULL,
    nb_groupes INTEGER                                     NOT NULL DEFAULT 0
);

CREATE TABLE projet.groupes
(
    num        INTEGER                                NOT NULL,
    id_projet  INTEGER REFERENCES projet.projets (id) NOT NULL,
    nb_places  INTEGER                                NOT NULL,
    nb_membres INTEGER                                         DEFAULT 0,
    est_valide BOOLEAN                                NOT NULL DEFAULT false,
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
    INSERT INTO projet.cours
    VALUES (ncode, nnom, nbloc, ncredits)
    RETURNING ncode INTO ret;
    RETURN ret;
END;
$$ language plpgsql;

--============================================================================
--=                         2) ENCODER ETUDIANT                              =
--============================================================================
CREATE OR REPLACE FUNCTION projet.encoder_etudiant(nnom varchar(20), nprenom VARCHAR(20), nemail VARCHAR(50),
                                                   nmdp VARCHAR(20)) RETURNS INTEGER AS
$$
DECLARE
    ret INTEGER;
BEGIN
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
CREATE OR REPLACE FUNCTION projet.inscrire_etudiant(nid_etudiant INTEGER, ncode CHARACTER(8)) RETURNS BOOLEAN AS
$$
DECLARE
    ret BOOLEAN := false;
BEGIN
    INSERT INTO projet.inscriptions_cours
    VALUES (ncode, nid_etudiant)
    RETURNING true INTO ret;
    RETURN ret;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION projet.check_cours_existant() RETURNS trigger as
$$
BEGIN
    IF (not exists(select 1 from projet.cours c where c.code = new.cours))
    THEN
        RAISE EXCEPTION 'Le cours renseigné n existe pas';
    END IF;
    RETURN NULL;
END;
$$ language plpgsql;

CREATE TRIGGER trigger_check_cours_existant
    BEFORE INSERT
    on projet.inscriptions_cours
    FOR EACH ROW
EXECUTE PROCEDURE projet.check_cours_existant();

CREATE OR REPLACE FUNCTION projet.check_cours_avec_projet() RETURNS trigger as
$$
BEGIN
    IF (EXISTS(select 1 from projet.projets p WHERE (p.cours = new.cours)))
    THEN
        RAISE EXCEPTION 'Le cours contient déjà un projet';
    END IF;
    RETURN NULL;
END;
$$ language plpgsql;

CREATE TRIGGER trigger_check_cours_avec_projet
    AFTER INSERT
    on projet.inscriptions_cours
    FOR EACH ROW
EXECUTE PROCEDURE projet.check_cours_avec_projet();

--============================================================================
--=                         4) CREER PROJET                                  =
--============================================================================
CREATE OR REPLACE FUNCTION projet.creer_projet(ncours CHARACTER(8), nnom VARCHAR(20), ndate_debut TIMESTAMP,
                                               ndate_fin TIMESTAMP) RETURNS INTEGER AS
$$
DECLARE
    ret INTEGER;
BEGIN
    INSERT INTO projet.projets
    VALUES (DEFAULT, ncours, nnom, ndate_debut, ndate_fin, DEFAULT)
    RETURNING id INTO ret;
    RETURN ret;
END;
$$ LANGUAGE plpgsql;

--============================================================================
--=                         5) CREER GROUPES                                 =
--============================================================================
/**
    Créer des groupes pour un projet. Pour cela, le professeur devra encoder l’identifiant du projet,
    le nombre de groupes à créer et le nombre de places par groupe. S’il veut créer desgroupes de tailles différentes,
    il devra faire appel plusieurs fois à la fonctionnalité. La création
    échouera si le nombre de places dans les groupes du projet dépassent le nombre d’inscrits au
    cours. Dans ce cas, aucun groupe ne sera créé.
 */
CREATE OR REPLACE FUNCTION projet.creer_groupes(nprojet INTEGER, nnb_groupes INTEGER, nnb_places INTEGER) RETURNS VOID AS
$$
DECLARE
    nb_membres_max    INTEGER := 0;
    nb_membres_actuel INTEGER := 0;
    nb_groupes_actuel INTEGER := 0;
    nb_membres_crees  INTEGER := 0;
BEGIN
    nb_membres_max := (SELECT count(i.etudiant)
                       FROM projet.inscriptions_cours i
                       WHERE cours =
                             (SELECT p.cours
                              FROM projet.projets p
                              WHERE p.id = nprojet));
    IF (SELECT p.nb_groupes FROM projet.projets p WHERE p.id = nprojet) > 0
    THEN
        nb_membres_actuel := (SELECT count(mg.etudiant)
                              FROM projet.membres_groupe mg
                              WHERE mg.projet = nprojet);
        nb_groupes_actuel := (SELECT p.nb_groupes
                              FROM projet.projets p
                              WHERE p.id = nprojet);
    END IF;
    nb_membres_crees := nnb_groupes * nnb_places;
    FOR cnt IN 1 .. nnb_groupes
        LOOP
            nb_groupes_actuel := nb_groupes_actuel + 1;
            UPDATE projet.projets SET nb_groupes = nb_groupes_actuel WHERE id = nprojet;
            INSERT INTO projet.groupes
            VALUES (nb_groupes_actuel, nprojet, nnb_places, DEFAULT, DEFAULT);
        END LOOP;
END;
$$ LANGUAGE plpgsql;
/*
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
CREATE OR REPLACE FUNCTION projet.check_cours_sans_projet() RETURNS trigger as
$$
BEGIN
    IF (NOT EXISTS(select 1 from projet.projets p WHERE (p.cours = new.cours)))
    THEN
        RAISE EXCEPTION 'Le cours ne contient aucun projet';
    END IF;
    RETURN new;
END;
$$ language plpgsql;

CREATE OR REPLACE TRIGGER trigger_check_cours_sans_projet
    AFTER INSERT
    on projet.inscriptions_cours
    FOR EACH ROW
EXECUTE PROCEDURE projet.check_cours_sans_projet();

/*
-- todo : trigger
    IF nb_membres_crees + nb_membres_actuel > nb_membres_max
    THEN
        RAISE 'Pas assez de places restantes';
    END IF;
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
       coalesce(string_agg(p.id::text, ', '), 'pas encore de projet') AS "id projet(s)"
FROM projet.cours c
         LEFT JOIN projet.projets p ON c.code = p.cours
GROUP BY c.code;

--============================================================================
--=                          7) VISUALISER PROJET                            =
--============================================================================
/**
    Visualiser tous les projets. Pour chaque projet, on affichera son identifiant, son nom, le code
    unique de son cours, le nombre de groupes, le nombre de groupes complets et le nombre de
    groupes validés. Si un projet n’a pas encore de groupe, il devra également apparaître.
 */
CREATE OR REPLACE VIEW projet.visualiser_projets AS
select distinct p.id                                                 as "id projet",
                p.nom                                                as "nom projet",
                p.cours                                              as "code cours",
                p.nb_groupes                                         as "nb groupes",
                count(*) filter ( where g.nb_membres = g.nb_places ) as "nb groupes complets",
                count(*) filter ( where g.est_valide is true )       as "nb groupes valides"
from projet.projets p
         left join projet.groupes g on p.id = g.id_projet
group by p.id, p.nom, p.cours, p.nb_groupes
order by p.id;

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
select distinct g.num                        as "Numéro",
                e.nom                        as "Nom",
                e.prenom                     as "Prénom",
                (g.nb_places = g.nb_membres) as "Complet ?",
                g.est_valide                 as "Validé ?",
                g.id_projet                  as "ProjetID"
from projet.groupes g
         left join projet.membres_groupe mg on g.num = mg.groupe and g.id_projet = mg.projet
         left join projet.etudiants e on mg.etudiant = e.id
group by g.num, e.nom, e.prenom, g.nb_places, g.nb_membres, g.est_valide, g.id_projet
order by g.num;

--============================================================================
--=                         9) VALIDER GROUPE                                =
--============================================================================
/**
    Valider un groupe. Pour cela, le professeur devra encoder l’identifiant du projet et le numéro
    de groupe. La validation échouera si le groupe n’est pas complet.
*/
CREATE OR REPLACE FUNCTION projet.valider_groupe(nid_projet INTEGER, nnum_groupe INTEGER) RETURNS INTEGER AS
$$
DECLARE
    ret INTEGER := 0;
BEGIN
    UPDATE projet.groupes g
    SET est_valide = true
    WHERE g.id_projet = nid_projet
      AND g.num = nnum_groupe
    RETURNING g.num INTO ret;
    RETURN ret;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION projet.check_groupe_complet() RETURNS trigger as
$$
BEGIN
    IF (false)
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

--============================================================================
--=                        10) VALIDER GROUPES                               =
--============================================================================
/**
    Valider tous les groupes d’un projet. Si un des groupes n’est pas complet, alors aucun groupe
    ne sera validé.
 */
CREATE OR REPLACE FUNCTION projet.valider_groupes() RETURNS void AS
$$
DECLARE
    record RECORD;
BEGIN
    FOR record IN (SELECT * FROM projet.groupes)
        LOOP
            UPDATE projet.groupes g SET est_valide = TRUE WHERE g.id_projet = record.id_projet AND g.num = record.num;
        END LOOP;
END;
$$ language plpgsql;

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
       coalesce(string_agg(p.id::text, ', '), 'pas encore de projet') AS "id projet(s)",
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
CREATE OR REPLACE FUNCTION projet.inscription_groupe(nid_etudiant INTEGER, nid_projet INTEGER, nnum_groupe INTEGER) RETURNS projet.membres_groupe AS
$$
DECLARE
    new_member projet.membres_groupe%rowtype;
BEGIN
    INSERT INTO projet.membres_groupe(etudiant, groupe, projet)
    VALUES (nid_etudiant, nnum_groupe, nid_projet)
    RETURNING * INTO new_member;
    RETURN new_member;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION projet.increment_membres_groupe() RETURNS trigger as
$$
declare
    groupe_to_update projet.groupes%rowtype;
BEGIN
    select * from projet.groupes g where g.num = new.groupe and g.id_projet = new.projet into groupe_to_update;
    if not FOUND then
        RAISE exception 'Le groupe % du projet % ne se trouve pas dans la table', new.groupe, new.projet;
    else
        if groupe_to_update.nb_membres < groupe_to_update.nb_places then
            UPDATE projet.groupes
            SET nb_membres = nb_membres + 1
            WHERE num = new.groupe
              and id_projet = new.projet;
        else
            RAISE exception 'Le groupe est complet';
        end if;
    end if;
    RETURN new;
END
$$ language plpgsql;

CREATE TRIGGER trigger_increment_membre_groupe
    BEFORE INSERT
    on projet.membres_groupe
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
--TODO : function
CREATE OR REPLACE FUNCTION projet.retirer_du_groupe(nid_etudiant INTEGER, nid_projet INTEGER, nnum_groupe INTEGER) RETURNS VOID AS
$$
BEGIN
    DELETE
    FROM projet.membres_groupe
    WHERE etudiant = nid_etudiant
      AND projet = nid_projet
      AND groupe = nnum_groupe;
END;
$$ language plpgsql;


--TODO : trigger decrementer nb_membres
CREATE OR REPLACE FUNCTION projet.decrementer_nb_membres() RETURNS TRIGGER AS
$$
declare
    groupe_to_update projet.groupes%rowtype;
BEGIN
    select *
    from projet.groupes g
    where g.num = OLD.groupe
      and g.id_projet = OLD.projet
    into groupe_to_update;
    if not FOUND then
        RAISE exception 'Le groupe % du projet % ne se trouve pas dans la table', OLD.groupe, OLD.projet;
    else
        UPDATE projet.groupes
        SET nb_membres = nb_membres - 1
        WHERE num = OLD.groupe
          and id_projet = OLD.projet;
    end if;
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_decrementer_nb_membres
    BEFORE DELETE
    on projet.membres_groupe
    FOR EACH ROW
EXECUTE FUNCTION projet.decrementer_nb_membres();

--TODO : trigger groupe déjà validé + étudiant n'est pas dans le groupe
CREATE OR REPLACE FUNCTION projet.check_groupe_deja_valide() RETURNS TRIGGER AS
$$
BEGIN
    if (select g.est_valide from projet.groupes g where g.num = old.groupe and g.id_projet = old.projet) then
        raise exception 'groupe déjà validé';
    end if;
    return old;
END;
$$ language plpgsql;

CREATE TRIGGER trigger_check_groupe_deja_valide
    AFTER DELETE
    ON projet.membres_groupe
    FOR EACH ROW
EXECUTE FUNCTION projet.check_groupe_deja_valide();


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
         left join projet.projets p on g.id_projet = p.id
         left join projet.cours c on p.cours = c.code
         left join projet.inscriptions_cours ic on c.code = ic.cours;

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
       p.nom        as "Nom",
       p.date_debut as "Début",
       p.date_fin   as "Fin",
       ic.etudiant  as "Etudiant"
FROM projet.projets p,
     projet.cours c,
     projet.inscriptions_cours ic
where p.cours = c.code
  and c.code = ic.cours
  and p.nb_groupes = 0;


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
SELECT g.num                        as "Numéro",
       e.nom                        as "Nom",
       e.prenom                     as "Prénom",
       (g.nb_places - g.nb_membres) as "Nombre de places",
       e.id                         as "Etudiant"
FROM projet.groupes g,
     projet.membres_groupe mg,
     projet.etudiants e
WHERE g.num = mg.groupe
  and g.id_projet = mg.projet
  and mg.etudiant = e.id
  and g.nb_membres < g.nb_places;
