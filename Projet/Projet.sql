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
    nb_credits INTEGER     NOT NULL
);

CREATE TABLE projet.etudiants
(
    email  VARCHAR(50) NOT NULL PRIMARY KEY CHECK ( email SIMILAR TO '%[@student.vinci.be]' ),
    nom    VARCHAR(20) NOT NULL CHECK ( nom <> '' ),
    prenom VARCHAR(20) NOT NULL CHECK ( prenom <> '' ),
    mdp    VARCHAR(60) NOT NULL CHECK ( mdp <> '' ) /*crypté sur 60 caractères*/
);

CREATE TABLE projet.inscriptions_cours
(
    cours    CHARACTER(8) REFERENCES projet.cours (code)     NOT NULL,
    etudiant VARCHAR(50) REFERENCES projet.etudiants (email) NOT NULL,
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
    nb_membres INTEGER                                NOT NULL DEFAULT 0,
    est_valide BOOLEAN                                NOT NULL DEFAULT false,
    PRIMARY KEY (num, id_projet)
);

CREATE TABLE projet.membres_groupe
(
    etudiant VARCHAR(50) REFERENCES projet.etudiants (email) NOT NULL,
    projet   INTEGER REFERENCES projet.projets (id)          NOT NULL,
    PRIMARY KEY (etudiant, projet)
);
--============================================================================
--=                            APPLICATION CENTRALE                          =
--============================================================================

-- 1) Encoder cours
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

-- 2) Encoder étudiant
CREATE OR REPLACE FUNCTION projet.encoder_etudiant(nnom varchar(20), nprenom VARCHAR(20), nemail VARCHAR(50),
                                                   nmdp VARCHAR(20)) RETURNS VARCHAR(50) AS
$$
DECLARE
    ret VARCHAR(50);
BEGIN
    INSERT INTO projet.etudiants
    VALUES (nemail, nprenom, nnom, nmdp)
    RETURNING nemail INTO ret;
    RETURN ret;
END;
$$ LANGUAGE plpgsql;

-- 3) Inscrire un étudiant à un cours
/**
    Inscrire un étudiant à un cours (en donnant l’adresse mail de l’étudiant et le code unique du
    cours) . On ne peut inscrire un étudiant à un cours si le cours contient déjà un projet.
 */
CREATE OR REPLACE FUNCTION projet.inscrire_etudiant(nemail VARCHAR(50), ncode CHARACTER(8)) RETURNS BOOLEAN AS
$$
DECLARE
    ret BOOLEAN := false;
BEGIN
    IF (EXISTS(select 1 from projet.projets p WHERE (p.cours = ncode)))
    THEN
        RAISE EXCEPTION 'Le cours contient déjà un projet';
    END IF;
    INSERT INTO projet.inscriptions_cours
    VALUES (ncode, nemail)
    RETURNING true INTO ret;
    RETURN ret;
END;
$$ LANGUAGE plpgsql;

-- 4) Créer un projet pour un cours
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

-- 5) Créer groupe(s)
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

    --TODO : export in trigger
    IF nb_membres_max = 0
    THEN
        RAISE 'Aucun élève inscrit au cours';
    END IF;

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

    --TODO : correct + export in trigger
    IF nb_membres_crees + nb_membres_actuel > nb_membres_max
    THEN
        RAISE 'Pas assez de places restantes';
    END IF;

    FOR cnt IN 1 .. nnb_groupes
        LOOP
            nb_groupes_actuel := nb_groupes_actuel + 1;
            UPDATE projet.projets SET nb_groupes = nb_groupes_actuel WHERE id = nprojet;
            INSERT INTO projet.groupes
            VALUES (nb_groupes_actuel, nprojet, nnb_places, DEFAULT, DEFAULT);
        END LOOP;
END;
$$ LANGUAGE plpgsql;
-- TODO : trigger check_num_groupe
/*
CREATE OR REPLACE FUNCTION projet.check_num_groupe() RETURNS trigger as
$$
BEGIN
    IF (NEW.num < 1 OR NEW.num > (select p.nb_groupes from projet.projets p))
    THEN
        RAISE EXCEPTION 'Mauvais numéro de groupe';
    END IF;
    RETURN NULL;
END;
$$ language plpgsql;

CREATE TRIGGER trigger_check_num_groupe
    AFTER INSERT OR UPDATE
    on projet.groupes
    FOR EACH ROW
EXECUTE PROCEDURE check_num_groupe();
*/

-- 6) Visualiser cours
/**
    Visualiser les cours. Pour chaque cours, on affichera son code unique, son nom et les
    identifiants de ses projets (sur une ligne, séparé par des virgules). Si le cours ne possède pas
    de projet, il sera noté « pas encore de projet ».
 */
CREATE OR REPLACE VIEW projet.visualiser_cours AS
SELECT  c.code AS "code cours",
        c.nom  AS "nom cours",
        coalesce(string_agg(p.id::text, ', '), 'pas encore de projet') AS "id projet(s)"
FROM projet.cours c LEFT JOIN projet.projets p ON c.code = p.cours
GROUP BY c.code;

-- 7) Visualiser projets
/**
    Visualiser tous les projets. Pour chaque projet, on affichera son identifiant, son nom, le code
    unique de son cours, le nombre de groupes, le nombre de groupes complets et le nombre de
    groupes validés. Si un projet n’a pas encore de groupe, il devra également apparaître.
 */
CREATE OR REPLACE VIEW projet.visualiser_projets AS
select distinct p.id as "id projet",
       p.nom as "nom projet",
       p.cours as "code cours",
       p.nb_groupes as "nombre groupes",
       count(*) filter ( where g.nb_membres = g.nb_places ) as "nb complete",
       count(*) filter ( where g.est_valide is true ) as "nb valide"
from projet.projets p left join projet.groupes g on p.id = g.id_projet
group by p.id, p.nom, p.cours, p.nb_groupes;

/**
       --TODO : calculer nb groupes complets g.nb_membres==g.nb_places
       COALESCE(to_char(count(g.nb_membres=g.nb_places), '0'), 'pas encore de groupe') as "groupes complets",
       --TODO : calculer nb groupes valides
       count(g.est_valide IS TRUE) as "groupes valides"
 */

-- 8) Visualiser compo pour un projet
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
--TODO
CREATE OR REPLACE FUNCTION projet.visualiser_compo_projet(nprojet INTEGER) RETURNS SETOF RECORD AS $$
    DECLARE
        record RECORD;
        rec RECORD;
    BEGIN
        FOR record IN SELECT p.id, e.nom, e.prenom, g.est_valide
                FROM projet.groupes g, projet.projets p, projet.membres_groupe mg, projet.etudiants e
                WHERE p.id = g.id_projet AND p.id = mg.projet AND mg.etudiant = e.email AND mg.projet = nprojet
            LOOP
                SELECT record.id, record.nom, record.prenom, record.est_valide INTO rec;
                RETURN NEXT rec;
            END LOOP;
        RETURN;
    END
$$ language plpgsql;

-- 9) Valider un groupe
/**
    alider un groupe. Pour cela, le professeur devra encoder l’identifiant du projet et le numéro
    de groupe. La validation échouera si le groupe n’est pas complet.
*/
--TODO

-- 10) Valider tous groupes
/**
    Valider tous les groupes d’un projet. Si un des groupes n’est pas complet, alors aucun groupe
    ne sera validé.
 */
--TODO

--============================================================================
--=                            APPLICATION ETUDIANT                          =
--============================================================================

-- 1) Visualiser mes cours
/**
    Visualiser les cours auxquels il participe. Pour chaque cours, on affichera son code unique, son
    nom et les identifiants de ses projets (sur une ligne, séparé par des virgules). Si le cours ne
    possède pas de projet, il sera noté « pas encore de projet ».
 */
--TODO

-- 2) S'inscrire à un groupe
/**
    Se rajouter dans un groupe en donnant l’identifiant de projet et le numéro de groupe.
    L’inscription échouera si le groupe est déjà complet ou si l’étudiant n’est pas inscrit au cours
    relatif à ce projet.
 */
--TODO

-- 3) Se retirer d'un groupe
/**
    Se retirer d’un groupe en donnant l’identifiant de projet. Le retrait échouera si le groupe a été
    validé ou si l’étudiant n’est pas encore dans un groupe.
 */
--TODO

-- 4) Visualiser mes projets
/**
    Visualiser tous les projets des cours auxquels il est inscrit. Pour chaque projet, on affichera son
    identifiant, son nom, l’identifiant du cours et le numéro de groupe dont il fait partie. S’il n’est
    pas encore dans un groupe, ce dernier champ sera à null.
 */
--TODO

-- 5) Visualiser mes projets sans groupes
/**
    Visualiser tous les projets pour lesquels il n’a pas encore de groupe. Cela n’affichera bien sûr
    que les projets faisant partie des cours où il participe. Pour chaque projet, on affichera son
    identifiant, son nom, l’identifiant du cours, sa date de début et sa date de fin.
 */
--TODO

-- 6) Visualiser toutes les groupes incomplets pour un projet
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
--TODO


--============================================================================
--=                                    TEST                                  =
--============================================================================
-- encoder cours
select * from projet.encoder_cours(CHARACTER(8) 'BINV1345', VARCHAR(20) 'cours 1', 1, 3);
select * from projet.encoder_cours(CHARACTER(8) 'BINV2345', VARCHAR(20) 'cours 2', 2, 6);
select * from projet.encoder_cours(CHARACTER(8) 'BINV3345', VARCHAR(20) 'cours 3', 3, 9);

-- encoder etudiant
select * from projet.encoder_etudiant(varchar(20) 'nnom', VARCHAR(20) 'nprenom', VARCHAR(50) 'nemail@student.vinci.be',
                             VARCHAR(20) 'nmdp');
select * from projet.encoder_etudiant(varchar(20) 'nnom', VARCHAR(20) 'nprenom', VARCHAR(50) 'nemail2@student.vinci.be',
                             VARCHAR(20) 'nmdp');
select * from projet.encoder_etudiant(varchar(20) 'nnom', VARCHAR(20) 'nprenom', VARCHAR(50) 'nemail3@student.vinci.be',
                             VARCHAR(20) 'nmdp');

-- inscrire etudiant
select * from projet.inscrire_etudiant(VARCHAR(50) 'nemail@student.vinci.be', CHARACTER(8) 'BINV1345');
select * from projet.inscrire_etudiant(VARCHAR(50) 'nemail2@student.vinci.be', CHARACTER(8) 'BINV1345');
select * from projet.inscrire_etudiant(VARCHAR(50) 'nemail3@student.vinci.be', CHARACTER(8) 'BINV1345');

-- creer projet
select * from projet.creer_projet(CHARACTER(8) 'BINV1345', VARCHAR(20) '1p1', TIMESTAMP '2022-09-01',
                         TIMESTAMP '2023-06-30');
select * from projet.creer_projet(CHARACTER(8) 'BINV1345', VARCHAR(20) '1p2', TIMESTAMP '2022-09-01',
                         TIMESTAMP '2023-06-30');
select * from projet.creer_projet(CHARACTER(8) 'BINV2345', VARCHAR(20) '2p1', TIMESTAMP '2022-09-01',
                         TIMESTAMP '2023-06-30');

-- crer groupe
select * from projet.creer_groupes(1, 1, 1);
select * from projet.creer_groupes(2, 1, 1);
select * from projet.creer_groupes(2, 1, 1);

-- visualiser cours
select * from projet.visualiser_cours;

-- visualiser projets
select * from projet.visualiser_projets;

-- visualiser compo projet
select * from projet.visualiser_compo_projet(1) t (numero integer, nom varchar(20), prenom varchar(20), estvalide boolean);

--select * from projet.groupes;

--select distinct p.id as "project ID" from projet.projets p left join projet.groupes g on p.id = g.id_projet group by p.id
