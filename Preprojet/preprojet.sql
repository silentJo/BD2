DROP SCHEMA IF EXISTS preprojet CASCADE;
CREATE SCHEMA preprojet;

-- QUESTION 2
CREATE TABLE preprojet.personnes
(
    id_personne SERIAL PRIMARY KEY,
    nom         VARCHAR(100) NOT NULL CHECK (nom <> ''),
    prenom      VARCHAR(100) NOT NULL CHECK (prenom <> '')
);

CREATE TABLE preprojet.comptes
(
    numero        CHARACTER(9) PRIMARY KEY CHECK (numero SIMILAR TO '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    id_personne   INTEGER REFERENCES preprojet.personnes (id_personne) NOT NULL,
    balance_total INTEGER
);

CREATE TABLE preprojet.operations
(
    id_operation       SERIAL PRIMARY KEY,
    compte_source      CHARACTER(9) REFERENCES preprojet.comptes (numero) NOT NULL,
    compte_destination CHARACTER(9) REFERENCES preprojet.comptes (numero) NOT NULL,
    montant            INTEGER                                            NOT NULL CHECK (montant > 0),
    date_op            TIMESTAMP                                          NOT NULL,
    CHECK (compte_source <> compte_destination)
);

-- QUESTION 3
INSERT INTO preprojet.personnes
VALUES (DEFAULT, 'Damas', 'Christophe');
INSERT INTO preprojet.personnes
VALUES (DEFAULT, 'Cambron', 'Isabelle');
INSERT INTO preprojet.personnes
VALUES (DEFAULT, 'Ferneeuw', 'Stephanie');

INSERT INTO preprojet.comptes
VALUES (123456789, 1);
INSERT INTO preprojet.comptes
VALUES (987687654, 1);
INSERT INTO preprojet.comptes
VALUES (123602364, 2);
INSERT INTO preprojet.comptes
VALUES (563212564, 2);
INSERT INTO preprojet.comptes
VALUES (789623565, 3);

INSERT INTO preprojet.operations
VALUES (DEFAULT, 123456789, 563212564, 100, '2006-12-01');
INSERT INTO preprojet.operations
VALUES (DEFAULT, 563212564, 123602364, 120, '2006-12-02');
INSERT INTO preprojet.operations
VALUES (DEFAULT, 987687654, 789623565, 80, '2006-12-03');
INSERT INTO preprojet.operations
VALUES (DEFAULT, 789623565, 987687654, 80, '2006-12-04');
INSERT INTO preprojet.operations
VALUES (DEFAULT, 123602364, 789623565, 150, '2006-12-05');
INSERT INTO preprojet.operations
VALUES (DEFAULT, 563212564, 123602364, 120, '2006-12-06');
INSERT INTO preprojet.operations
VALUES (DEFAULT, 123456789, 563212564, 100, '2006-12-07');
INSERT INTO preprojet.operations
VALUES (DEFAULT, 987687654, 789623565, 80, '2006-12-08');
INSERT INTO preprojet.operations
VALUES (DEFAULT, 789623565, 987687654, 80, '2006-12-09');

-- QUESTION 4
create view preprojet.tout as
select distinct pers_src.nom     as "Nom source",
                pers_src.prenom  as "Prenom source",
                cpt_src.numero   as "Compte source",
                pers_dest.nom    as "Nom destination",
                pers_dest.prenom as "Prenom destination",
                cpt_dest.numero  as "Compte destination",
                o.date_op        as "Date operation",
                o.montant        as "Montant"
from preprojet.personnes pers_src,
     preprojet.personnes pers_dest,
     preprojet.comptes cpt_src,
     preprojet.comptes cpt_dest,
     preprojet.operations o
where pers_src.id_personne = cpt_src.id_personne
  and o.compte_source = cpt_src.numero
  and pers_dest.id_personne = cpt_dest.id_personne
  and o.compte_destination = cpt_dest.numero
order by o.date_op;
-- QUESTION 4 : ok
select *
from preprojet.tout;

-- QUESTION 5
CREATE OR REPLACE FUNCTION preprojet.insererOperation(nom_source VARCHAR(100),
                                                      prenom_source VARCHAR(100),
                                                      compte_source CHARACTER(9),
                                                      nom_destination VARCHAR(100),
                                                      prenom_destination VARCHAR(100),
                                                      compte_destination CHARACTER(9),
                                                      date_operation TIMESTAMP,
                                                      montant_operation INTEGER)
    RETURNS INTEGER AS
$$
DECLARE
    id INTEGER := 0;
BEGIN
    IF NOT EXISTS(SELECT *
                  FROM preprojet.comptes c,
                       preprojet.personnes p
                  WHERE c.numero = compte_source
                    AND c.id_personne = p.id_personne
                    AND p.nom = nom_source
                    AND p.prenom = prenom_source)
    THEN
        RAISE foreign_key_violation;
    END IF;
    IF NOT EXISTS(SELECT *
                  FROM preprojet.comptes c,
                       preprojet.personnes p
                  WHERE c.numero = compte_destination
                    AND c.id_personne = p.id_personne
                    AND p.nom = nom_destination
                    AND p.prenom = prenom_destination)
    THEN
        RAISE foreign_key_violation;
    END IF;
    INSERT INTO preprojet.operations
    VALUES (DEFAULT, compte_source, compte_destination, montant_operation, date_operation)
    RETURNING id_operation INTO id;
    RETURN id;
END;
$$ LANGUAGE plpgsql;
-- QUESTION 5 : ok
select *
from preprojet.insererOperation(VARCHAR(100) 'Damas', VARCHAR(100) 'Christophe',
                                CHARACTER(9) '123456789', VARCHAR(100) 'Ferneeuw', VARCHAR(100) 'Stephanie',
                                CHARACTER(9) '789623565', TIMESTAMP '2022-10-22', 20);

-- QUESTION 6
CREATE OR REPLACE FUNCTION preprojet.modifierMontantOperation(nom_source VARCHAR(100), prenom_source VARCHAR(100),
                                                              cpt_source CHARACTER(9), nom_destination VARCHAR(100),
                                                              prenom_destination VARCHAR(100),
                                                              cpt_destination CHARACTER(9),
                                                              date_operation TIMESTAMP,
                                                              montant_operation INTEGER) RETURNS RECORD AS
$$
DECLARE
    ret RECORD;
BEGIN

    IF ((SELECT count(DISTINCT o.*)
         FROM preprojet.comptes cpt_src,
              preprojet.comptes cpt_dest,
              preprojet.operations o
         WHERE o.compte_source = cpt_source
           AND o.compte_destination = cpt_destination
           AND o.date_op = date_operation) <> 1)
    THEN
        RAISE foreign_key_violation;
    ELSE
        SELECT DISTINCT o.*
        INTO ret
        FROM preprojet.comptes cpt_src,
             preprojet.comptes cpt_dest,
             preprojet.operations o
        WHERE o.compte_source = cpt_source
          AND o.compte_destination = cpt_destination
          AND o.date_op = date_operation;

        UPDATE preprojet.operations op SET montant=montant_operation WHERE op.id_operation = ret.id_operation;

        RETURN ret;
    END IF;
END;
$$ LANGUAGE plpgsql;
-- QUESTION 6
SELECT *
FROM preprojet.modifierMontantOperation(VARCHAR(100) 'Damas', VARCHAR(100) 'Christophe',
                                        CHARACTER(9) '123456789', VARCHAR(100) 'Cambron', VARCHAR(100) 'Isabelle',
                                        CHARACTER(9) '563212564', TIMESTAMP '2006-12-01', 20) t(id int,
                                                                                                src character(9),
                                                                                                dest character(9),
                                                                                                montant int,
                                                                                                date timestamp);
-- Question 6 : ok
select *
from preprojet.operations o
where o.id_operation = 1;

-- QUESTION 7
CREATE OR REPLACE FUNCTION preprojet.supprimerOperation(nom_source VARCHAR(100), prenom_source VARCHAR(100),
                                                        cpt_source CHARACTER(9), nom_destination VARCHAR(100),
                                                        prenom_destination VARCHAR(100), cpt_destination CHARACTER(9),
                                                        date_operation TIMESTAMP,
                                                        montant_operation INTEGER) RETURNS BOOLEAN AS
$$
DECLARE
    ret    BOOLEAN := false;
    record RECORD;
BEGIN
    FOR record IN SELECT * FROM preprojet.operations
        LOOP
            IF record.compte_source = cpt_source
                AND record.compte_destination = cpt_destination
                AND record.date_op = date_operation
                AND record.montant = montant_operation
            THEN
                DELETE
                FROM preprojet.operations o
                WHERE record.compte_source = o.compte_source
                  AND record.compte_destination = o.compte_destination
                  AND record.date_op = o.date_op
                  AND record.montant = o.montant;
                ret = true;
            END IF;
        END LOOP;
    return ret;
END;
$$ LANGUAGE plpgsql;
-- Question 7
select *
from preprojet.supprimerOperation(VARCHAR(100) 'Damas', VARCHAR(100) 'Christophe',
                                  CHARACTER(9) '123456789', VARCHAR(100) 'Cambron', VARCHAR(100) 'Isabelle',
                                  CHARACTER(9) '563212564', TIMESTAMP '2006-12-01', 20);
-- Question 7 : ok
select *
from preprojet.operations;

-- QUESTION 8
/*
    Créez une procédure qui affiche l’évolution d’un compte bancaire au cours du temps.
    Le paramètre de la procédure est le numéro du compte bancaire. A chaque fois qu’il y a une opération avec ce compte,
    une ligne affiche la date de l’opération, avec qui cette opération se fait et quelle est la balance du compte suite
    à cette dernière.
 */
CREATE OR REPLACE FUNCTION preprojet.balance(compte CHARACTER(9)) RETURNS SETOF RECORD AS
$$
DECLARE
    record  RECORD;
    rec     RECORD;
    balance INTEGER := 0;
BEGIN
    FOR record IN SELECT o.date_op, o.compte_source, o.compte_destination, o.montant FROM preprojet.operations o
        LOOP
            IF compte = record.compte_source THEN
                balance := balance - record.montant;
                SELECT record.date_op, record.compte_destination, balance INTO rec;
                RETURN NEXT rec;
            ELSEIF compte = record.compte_destination THEN
                balance := balance + record.montant;
                SELECT record.date_op, record.compte_source, balance INTO rec;
                RETURN NEXT rec;
            END IF;
        END LOOP;
    RETURN;
END
$$ LANGUAGE plpgsql;
-- Question 8 : ok
select *
from preprojet.balance('563212564') t(date timestamp, tiers character(9), montant integer);

-- QUESTION 9
/*
    Pour chaque compte en banque, ajoutez un champ balance_total. Ce champ contiendra la balance du compte en banque
    (somme de tous les montants dont ce compte est destinataire moins la somme de tous les montants dont ce compte est l’origine).
    Créez un trigger pour mettre ce champ à jour automatiquement.
 */
CREATE OR REPLACE FUNCTION update_balance_compte() RETURNS TRIGGER AS
$$
DECLARE

BEGIN

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_balance_compte_trigger
    AFTER INSERT OR UPDATE OR DELETE
    ON preprojet.operations
    FOR EACH ROW
EXECUTE PROCEDURE update_balance_compte();

-- QUESTION 10
/*
    Pour chaque personne, ajoutez un champ balance_utilisateur. Ce champ contiendra la somme des balances de tous ses comptes.
    Créez un trigger pour mettre ce champ à jour automatiquement.
 */
CREATE OR REPLACE FUNCTION update_balance_utilisateur() RETURNS TRIGGER AS
$$
DECLARE

BEGIN

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_balance_utilisateur_trigger
    AFTER INSERT OR UPDATE OR DELETE
    ON preprojet.operations
    FOR EACH ROW
EXECUTE PROCEDURE update_balance_utilisateur();
