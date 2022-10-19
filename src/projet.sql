-- Authors @Mariam_Ajattar @Jonathan_Casier
DROP SCHEMA IF EXISTS projet CASCADE;
CREATE SCHEMA projet;

--------------------------------- CREATE TABLE ---------------------------------

CREATE TABLE projet.blocs
(
    id_bloc        INTEGER PRIMARY KEY CHECK ( id_bloc > 0 AND id_bloc < 4 ),
    nb_credits_min INTEGER,
    nb_credits_max INTEGER
);

CREATE TABLE projet.etudiants
(
    id_etudiant         SERIAL PRIMARY KEY,
    nom                 VARCHAR(30) NOT NULL CHECK ( nom <> '' ),
    prenom              VARCHAR(30) NOT NULL CHECK ( prenom <> '' ),
    email               VARCHAR(50) NOT NULL CHECK ( email <> '' ) UNIQUE,
    mdp                 VARCHAR(74) NOT NULL CHECK ( mdp <> '' ),
    pae_valide          BOOLEAN                                   DEFAULT false,
    id_bloc             INTEGER references projet.blocs (id_bloc) DEFAULT NULL,
    nb_credits_valides  INTEGER     NOT NULL                      DEFAULT 0,
    nb_credits_en_cours INTEGER     NOT NULL                      DEFAULT 0
);

CREATE TABLE projet.ues
(
    code        VARCHAR(10) PRIMARY KEY CHECK ( code ~* '^BINV[1-3].*$' ),
    nom         VARChAR(30)                               NOT NULL CHECK ( nom <> '' ),
    nb_credits  INTEGER                                   NOT NULL,
    nb_inscrits INTEGER                                   NOT NULL DEFAULT 0,
    id_bloc     INTEGER references projet.blocs (id_bloc) NOT NULL
);

CREATE TABLE projet.ues_prerequis
(
    code_ue        VARCHAR(10) NOT NULL,
    code_prerequis VARCHAR(10) NOT NULL,
    PRIMARY KEY (code_ue, code_prerequis)
);

CREATE TABLE projet.ues_etudiant
(
    code_ue     VARCHAR(10) references projet.ues (code)          NOT NULL,
    id_etudiant INTEGER references projet.etudiants (id_etudiant) NOT NULL,
    est_validee BOOLEAN DEFAULT false,
    PRIMARY KEY (code_ue, id_etudiant)
);

--------------------------------- FUNCTIONS ---------------------------------
-- AC1
CREATE OR REPLACE FUNCTION projet.ajouterUE(pcode VARCHAR(10), pnom VARCHAR(30), pnb_credits INTEGER, pid_bloc INTEGER)
    RETURNS VARCHAR(10) AS
$$
DECLARE
    id VARCHAR(10) := '';
BEGIN
    INSERT INTO projet.ues
    VALUES (pcode, pnom, pnb_credits, DEFAULT, pid_bloc)
    RETURNING code INTO id;
    RETURN id;
END;
$$ LANGUAGE plpgsql;

-- AC2
CREATE OR REPLACE FUNCTION projet.ajouterPrerequis(pcode_ue VARCHAR(10), pcode_prerequis VARCHAR(10)) RETURNS VARCHAR(10) AS
$$
DECLARE
    v_code VARCHAR(10) := '';
BEGIN
    INSERT INTO projet.ues_prerequis VALUES (pcode_ue, pcode_prerequis) RETURNING code_ue INTO v_code;
    RETURN v_code;
END;

$$ language plpgsql;

-- AC3
CREATE OR REPLACE FUNCTION projet.ajouterEtudiant(pnom VARCHAR(30), pprenom VARCHAR(30), pemail VARCHAR(50),
                                                  pmdp VARCHAR(20)) RETURNS INTEGER AS
$$
DECLARE
    id INTEGER := 0;
BEGIN
    INSERT INTO projet.etudiants
    VALUES (DEFAULT, pnom, pprenom, pemail, pmdp, DEFAULT)
    RETURNING id_etudiant INTO id;
    RETURN id;
END;
$$ LANGUAGE plpgsql;

-- AC4
CREATE OR REPLACE FUNCTION projet.ajouterUEValidee(pcode_ue VARCHAR(10), pid_etudiant INTEGER) RETURNS VOID AS
$$
BEGIN
    IF NOT EXISTS(select *
                  from projet.ues_etudiant ueet
                  where ueet.code_ue = pcode_ue
                    and ueet.id_etudiant = pid_etudiant)
    THEN
        RAISE 'L étudiant ne s est pas inscrit à cette UE.' ;
    ELSE
        update projet.ues_etudiant
        set est_validee = true
        WHERE code_ue = pcode_ue
          AND id_etudiant = pid_etudiant;

        UPDATE projet.etudiants
        SET nb_credits_valides = nb_credits_valides + ues.nb_credits
        FROM projet.ues ues
        WHERE id_etudiant = pid_etudiant
          AND ues.code = pcode_ue;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- AC5
CREATE OR REPLACE FUNCTION projet.visualiserEtudiantsDUnBloc(pid_bloc INTEGER) RETURNS SETOF RECORD AS
$$
DECLARE
    etudiants RECORD;
BEGIN
    FOR etudiants IN
        SELECT et.id_etudiant, et.nom, et.prenom, sum(ue.nb_credits)
        FROM projet.ues ue,
             projet.etudiants et,
             projet.ues_etudiant ueet
        WHERE et.id_etudiant = ueet.id_etudiant
          AND ueet.code_ue = ue.code
          AND et.id_bloc = pid_bloc
          AND ueet.est_validee IS FALSE
        GROUP BY et.id_etudiant, et.nom, et.prenom
        LOOP
            RETURN NEXT etudiants;
        END LOOP;
END;
$$ LANGUAGE plpgsql;

-- AC8
CREATE OR REPLACE FUNCTION projet.visualiserUESDUnBloc(pid_bloc INTEGER) RETURNS SETOF RECORD AS
$$
DECLARE
    etudiants RECORD;
BEGIN
    FOR etudiants IN
        SELECT ue.code, ue.nom, ue.nb_inscrits
        FROM projet.ues ue,
             projet.blocs b
        WHERE ue.id_bloc = b.id_bloc
          AND b.id_bloc = pid_bloc
        ORDER BY ue.nb_inscrits DESC
        LOOP
            RETURN NEXT etudiants;
        END LOOP;
END;
$$ LANGUAGE plpgsql;

--------------------------------- VIEWS ---------------------------------
-- AC6
CREATE OR REPLACE VIEW projet.visualiserTousLesEtudiants AS
SELECT et.nom, et.prenom, et.id_bloc as id_bloc, COALESCE(sum(ue.nb_credits), 0) AS nb_credits
FROM projet.etudiants et
         LEFT OUTER JOIN projet.ues_etudiant ueet
                         ON et.id_etudiant = ueet.id_etudiant
         LEFT OUTER JOIN projet.ues ue
                         ON ueet.code_ue = ue.code
GROUP BY et.nom, et.prenom, et.id_bloc
ORDER BY sum(ue.nb_credits) DESC;

-- AC7
CREATE OR REPLACE VIEW projet.visaliserEtudiantsAvecPAENonValide AS
SELECT et.nom, et.prenom, sum(et.nb_credits_valides) AS credits_valides
FROM projet.etudiants et
         LEFT OUTER JOIN projet.ues_etudiant ueet
                         ON et.id_etudiant = ueet.id_etudiant
         LEFT OUTER JOIN projet.ues ue
                         ON ueet.code_ue = ue.code
WHERE et.pae_valide IS FALSE
GROUP BY et.nom, et.prenom
ORDER BY et.nom, et.prenom;

--------------------------------- TRIGGERS ---------------------------------

CREATE OR REPLACE FUNCTION projet.triggerAjouterPrerequis() RETURNS TRIGGER AS
$$
DECLARE
    id_bloc_prerequis INTEGER := 0;
BEGIN
    IF NOT EXISTS(SELECT DISTINCT * FROM projet.ues u WHERE u.code = new.code_ue)
    THEN
        RAISE 'UE inexistante.';
    ELSIF NOT EXISTS(SELECT DISTINCT * FROM projet.ues u WHERE u.code = new.code_prerequis)
    THEN
        RAISE 'prerequis inexistant.';
    END IF;
    SELECT prerequis.id_bloc FROM projet.ues prerequis WHERE prerequis.code = new.code_prerequis INTO id_bloc_prerequis;
    IF (SELECT ue.id_bloc <= id_bloc_prerequis FROM projet.ues ue WHERE ue.code = new.code_ue)
    THEN
        RAISE 'Une UE ne peut être prérequise que pour des UEs d’un bloc supérieur';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ajouterPrerequis_trigger
    BEFORE INSERT
    ON projet.ues_prerequis
    FOR EACH ROW
EXECUTE PROCEDURE projet.triggerAjouterPrerequis();

--------------------------------- APPLICATION ETUDIANT ---------------------------------

--AE seConnecter()
CREATE OR REPLACE FUNCTION projet.seConnecter(pemail VARCHAR(50)) RETURNS RECORD AS
$$
DECLARE
    etudiant RECORD;
BEGIN
    SELECT et.id_etudiant, et.mdp FROM projet.etudiants et WHERE et.email = pemail INTO etudiant;
    RETURN etudiant;
END;
$$ language plpgsql;

-- TODO trigger seConnecter()

--AE1
CREATE OR REPLACE FUNCTION projet.ajouterUEauPAE(pcode_ue VARCHAR(10), pid_etudiant INTEGER) RETURNS VOID AS
$$
DECLARE
BEGIN
    INSERT INTO projet.ues_etudiant VALUES (pcode_ue, pid_etudiant, false);

    UPDATE projet.etudiants
    SET nb_credits_en_cours = et.nb_credits_en_cours + ue.nb_credits
    FROM projet.ues ue,
         projet.etudiants et
    WHERE et.id_etudiant = pid_etudiant
      AND ue.code = pcode_ue;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION projet.triggerAjouterUEauPAE() RETURNS TRIGGER AS
$$
DECLARE
    v_code_prerequis VARCHAR(10) := '';
BEGIN
    IF EXISTS(SELECT * FROM projet.etudiants et WHERE et.pae_valide = TRUE AND et.id_etudiant = new.id_etudiant)
    THEN
        RAISE 'Le PAE est déjà validé';
        --TODO si ue déjà validée

    ELSEIF EXISTS(SELECT *
                  from projet.ues_etudiant
                  WHERE id_etudiant = new.id_etudiant
                    AND code_ue = new.code_ue
                    AND est_validee = TRUE) THEN
        RAISE 'UE déjà validée.';
        --TODO si nb credits < 30 et que UE pas du bloc 1
    ELSEIF EXISTS(SELECT *
                  FROM projet.etudiants et,
                       projet.ues_etudiant ueet,
                       projet.ues ue
                  WHERE et.id_etudiant = new.id_etudiant
                    AND et.id_etudiant = ueet.id_etudiant
                    AND et.nb_credits_valides < 30
                    AND ue.code = new.code_ue
                    AND ueet.code_ue = ue.code
                    AND ue.id_bloc <> 1) THEN
        RAISE 'Nombre de crédits inférieur à 30 et UE n est pas du bloc1';
    END IF;
    --TODO si prérequis non validés
    SELECT p.code_prerequis FROM projet.ues_prerequis p WHERE p.code_ue = new.code_ue INTO v_code_prerequis;
    IF EXISTS(SELECT DISTINCT ueet.*
              FROM projet.ues ue,
                   projet.ues_etudiant ueet
              WHERE ue.code = v_code_prerequis
                AND ue.code = ueet.code_ue
                AND ueet.est_validee = FALSE) THEN
        RAISE 'Prérequis non validé';
    END IF;
    RETURN NEW;
END;
$$ language plpgsql;

CREATE TRIGGER ajouterUEauPAE_trigger
    BEFORE INSERT
    ON projet.ues_etudiant
    FOR EACH ROW
EXECUTE PROCEDURE projet.triggerAjouterUEauPAE();

--AE2

create or replace function projet.enleverUEauPAE(pcode_ue varchar(10), pid_etudiant integer) returns boolean as
$$
begin
    DELETE
    FROM projet.ues_etudiant ueet
    WHERE ueet.code_ue = pcode_ue
      AND ueet.id_etudiant = pid_etudiant;
    if exists(select * from projet.ues_etudiant ueet where ueet.code_ue = pcode_ue and ueet.id_etudiant = pid_etudiant)
    then
        return false;
    else
        return true;
    end if;
end;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION projet.triggerEnleverUEauPAE() RETURNS TRIGGER AS
$$
DECLARE
BEGIN
    IF EXISTS(SELECT * FROM projet.etudiants et WHERE et.id_etudiant = old.id_etudiant AND et.pae_valide = TRUE) THEN
        RAISE 'PAE déjà validé.';
    END IF;
    return old;
END;
$$ language plpgsql;

CREATE TRIGGER enleverUEauPAE_trigger
    BEFORE DELETE
    ON projet.ues_etudiant
    FOR EACH ROW
EXECUTE PROCEDURE projet.triggerEnleverUEauPAE();


--AE3
create or replace function projet.validerPAE(pid_etudiant integer) returns boolean as
$$
declare
    total_credits   INTEGER := 0;
    credits_valides INTEGER := 0;
    credits_PAE     INTEGER := 0;
    ue              RECORD;
begin
    update projet.etudiants set pae_valide = true where id_etudiant = pid_etudiant;
    --TODO incrementer le nb d'inscrits de toutes les UE du PAE
    FOR ue IN SELECT ueet.code_ue
              FROM projet.ues_etudiant ueet
              WHERE ueet.id_etudiant = pid_etudiant
                AND ueet.est_validee = FALSE
        LOOP
            UPDATE projet.ues SET nb_inscrits = nb_inscrits + 1 WHERE code = ue.code_ue;
        END LOOP;
    if credits_valides < 30 and credits_PAE < 60 then
        update projet.etudiants set id_bloc = 1 where id_etudiant = pid_etudiant;

    elsif credits_valides < 30 and not exists(select ue.code
                                              from projet.ues ue,
                                                   projet.ues_etudiant ueet
                                              where ueet.id_etudiant = pid_etudiant
                                                and ue.code = ueet.code_ue
                                                and ue.id_bloc > 1) then
        update projet.etudiants set id_bloc = 1 where id_etudiant = pid_etudiant;

    elsif total_credits = 180 and credits_PAE <= 74 then
        update projet.etudiants set id_bloc = 3 where id_etudiant = pid_etudiant;

    elsif credits_PAE < 55 or credits_PAE > 74 then
        update projet.etudiants set id_bloc = 2 where id_etudiant = pid_etudiant;
    end if;


    if exists(select * from projet.etudiants where id_etudiant = pid_etudiant and pae_valide = true)
    then
        return true;
    else
        return false;
    end if;
end;
$$ language plpgsql;

--AE4
CREATE OR REPLACE FUNCTION projet.afficherUEaAjouterAuPAE(pid_etudiant INTEGER) RETURNS SETOF RECORD AS
$$
DECLARE
    credits_valides INTEGER := 0;
    ues             RECORD;
BEGIN
    SELECT et.nb_credits_valides FROM projet.etudiants et WHERE et.id_etudiant = 1 INTO credits_valides;
    IF credits_valides < 30 THEN
        /*
        SELECT DISTINCT ue.code, ue.nom, ue.nb_credits, ue.id_bloc
        FROM projet.ues ue
        WHERE ue.id_bloc = 1
          AND ue.code NOT IN (
            SELECT ueet.code_ue
            FROM projet.ues_etudiant ueet
            WHERE ueet.id_etudiant = pid_etudiant)
        GROUP BY ue.code, ue.nom, ue.nb_credits, ue.id_bloc
        ORDER BY ue.code
        INTO ues;
        RETURN NEXT ues;
         */
        for ues in
            SELECT DISTINCT ue.code, ue.nom, ue.nb_credits, ue.id_bloc
            FROM projet.ues ue
            WHERE ue.id_bloc = 1
              AND ue.code NOT IN (
                SELECT ueet.code_ue
                FROM projet.ues_etudiant ueet
                WHERE ueet.id_etudiant = pid_etudiant)
            GROUP BY ue.code, ue.nom, ue.nb_credits, ue.id_bloc
            ORDER BY ue.code
            loop
                return next ues;
            end loop;
    ELSE
        --SELECT TOUTES LES UES QUI NE SONT PAS DANS :
        for ues in
            SELECT ue.code, ue.nom, ue.nb_credits, ue.id_bloc
            FROM projet.ues ue
            WHERE ue.code NOT IN (
                SELECT ueet.code_ue
                FROM projet.ues_etudiant ueet
                WHERE ueet.id_etudiant = pid_etudiant)
              AND NOT EXISTS(SELECT *
                             FROM projet.ues_etudiant ueet,
                                  projet.ues_prerequis p
                             WHERE ue.code = p.code_ue
                               AND p.code_prerequis = ueet.code_ue
                               AND ueet.est_validee = FALSE)
            GROUP BY ue.code, ue.nom, ue.nb_credits, ue.id_bloc
            ORDER BY ue.code
            loop
                RETURN NEXT ues;
            end loop;
    END IF;
END;
$$ language plpgsql;

--AE5
CREATE OR REPLACE FUNCTION projet.visualiserSonPAE(pid_etudiant INTEGER) RETURNS SETOF RECORD AS
$$
DECLARE
    ue RECORD;
BEGIN
    FOR ue IN
        SELECT u.code, u.nom, u.nb_credits, u.id_bloc
        FROM projet.ues u,
             projet.ues_etudiant ueet
        WHERE ueet.code_ue = u.code
          and ueet.id_etudiant = pid_etudiant
        GROUP BY u.code, u.nom, u.nb_credits, u.id_bloc
        ORDER BY u.code
        LOOP
            RETURN NEXT ue;
        END LOOP;
END;
$$ language plpgsql;

--AE6
CREATE OR REPLACE FUNCTION projet.reinitialiserPAE(pid_etudiant INTEGER) RETURNS VOID AS
$$
DECLARE
BEGIN
    DELETE FROM projet.ues_etudiant ueet WHERE ueet.id_etudiant = pid_etudiant;
END;
$$ language plpgsql;

--------------------------------- INSERTS ---------------------------------

INSERT INTO projet.blocs
VALUES (1, null, 60);
INSERT INTO projet.blocs
VALUES (2, 74, 55);
INSERT INTO projet.blocs
VALUES (3, null, 74);

--------------------------------- SCENARIO ---------------------------------

-- UEs
select
from projet.ajouterUE('BINV11', 'BD1', 31, 1);
select
from projet.ajouterUE('BINV12', 'APOO', 16, 1);
select
from projet.ajouterUE('BINV13', 'Algo', 13, 1);
select
from projet.ajouterUE('BINV21', 'BD2', 42, 2);
select
from projet.ajouterUE('BINV311', 'Anglais', 16, 3);
select
from projet.ajouterUE('BINV32', 'Stage', 44, 3);

-- Étudiants
select
from projet.ajouterEtudiant('Damas', 'Christophe', 'damas@email',
                            '$2a$10$J.Ly6jt.GyhcYPG3GaJk/.Z3LCTlGsDXBxjhd/7/SSfWL3jsjc.Ou');
select
from projet.ajouterEtudiant('Ferneeuw', 'Stéphanie', 'ferneeuw@email',
                            '$2a$10$iI3SYs.nQ4.9CtUyooqgM.gSIJEMjIzyiOnRF9U3NBQkMgw57.5M.');
select
from projet.ajouterEtudiant('VanderMeulen', 'José', 'vandermeulen@email',
                            '$2a$10$qwGNervWxmLGDvLteg6K8eK4OzMMwecFSskqZSXsKIsX/tMjEUa6e');
select
from projet.ajouterEtudiant('Leconte', 'Emmeline', 'leconte@email',
                            '$2a$10$qerzZy0ozMDlCcEbXTUUn.tDju1jGBtPBHaER2znOkgs77/WKWfSG');

-- Prérequis
select
from projet.ajouterPrerequis('BINV21', 'BINV11');
select
from projet.ajouterPrerequis('BINV32', 'BINV21');

-- UE validées : Damas
select
from projet.ajouterUEauPAE('BINV12', 1);
select
from projet.ajouterUEauPAE('BINV13', 1);
select
from projet.ajouterUEValidee('BINV12', 1);
select
from projet.ajouterUEValidee('BINV13', 1);

-- UE validées : Ferneeuw
select
from projet.ajouterUEauPAE('BINV11', 2);
select
from projet.ajouterUEauPAE('BINV12', 2);
select
from projet.ajouterUEValidee('BINV11', 2);
select
from projet.ajouterUEValidee('BINV12', 2);

-- UE validées : Vander Meulen
select
from projet.ajouterUEauPAE('BINV11', 3);
select
from projet.ajouterUEauPAE('BINV12', 3);
select
from projet.ajouterUEauPAE('BINV13', 3);
select
from projet.ajouterUEValidee('BINV11', 3);
select
from projet.ajouterUEValidee('BINV12', 3);
select
from projet.ajouterUEValidee('BINV13', 3);

-- UE validées : Leconte
select
from projet.ajouterUEauPAE('BINV11', 4);
select
from projet.ajouterUEauPAE('BINV12', 4);
select
from projet.ajouterUEauPAE('BINV13', 4);
select
from projet.ajouterUEValidee('BINV11', 4);
select
from projet.ajouterUEValidee('BINV12', 4);
select
from projet.ajouterUEValidee('BINV13', 4);

select
from projet.ajouterUEauPAE('BINV21', 4);
select
from projet.ajouterUEValidee('BINV21', 4);

select
from projet.ajouterUEauPAE('BINV32', 4);
select
from projet.ajouterUEValidee('BINV32', 4);

--------------------------------- TESTS ---------------------------------

--select * from projet.etudiants;
--select * from projet.ues_etudiant;
select * from projet.ues;
select * from projet.ues_prerequis;

--select from projet.ajouterEtudiant('Mo', 'jo', 'jo', 'jo');
--select * from projet.ajouterUEauPAE('BINV11', 5);
--select * from projet.ajouterUEauPAE('BINV12', 5);
--select * from projet.ajouterUEauPAE('BINV13', 5);

--SELECT * FROM projet.afficherUEaAjouterAuPAE(5) t(code VARCHAR(10), nom VARCHAR(30), nb_credits INTEGER, id_bloc INTEGER);