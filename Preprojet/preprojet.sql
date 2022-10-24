DROP SCHEMA IF EXISTS preprojet CASCADE;
CREATE SCHEMA preprojet;

-- QUESTION 2

CREATE TABLE preprojet.personnes
(
    id_personne SERIAL PRIMARY KEY,
    nom         VARCHAR(100) NOT NULL CHECK (nom <> ''),
    prenom      VARCHAR(100)  NOT NULL CHECK (prenom <> '')
);

CREATE TABLE preprojet.comptes
(
    numero CHARACTER(9) PRIMARY KEY CHECK (numero SIMILAR TO '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    id_personne INTEGER REFERENCES preprojet.personnes (id_personne) NOT NULL
);

CREATE TABLE preprojet.operations
(
    id_operation       SERIAL PRIMARY KEY,
    compte_source      CHARACTER(10) REFERENCES preprojet.comptes (numero) NOT NULL,
    compte_destination CHARACTER(10) REFERENCES preprojet.comptes (numero) NOT NULL,
    montant            INTEGER                                             NOT NULL CHECK (montant > 0),
    date_op            TIMESTAMP                                           NOT NULL,
    CHECK (compte_source <> compte_destination)
);

-- QUESTION 3

INSERT INTO preprojet.personnes VALUES (DEFAULT, 'Damas', 'Christophe');
INSERT INTO preprojet.personnes VALUES (DEFAULT, 'Cambron', 'Isabelle');
INSERT INTO preprojet.personnes VALUES (DEFAULT, 'Ferneeuw', 'Stephanie');

INSERT INTO preprojet.comptes VALUES (123456789, 1);
INSERT INTO preprojet.comptes VALUES (987687654, 1);
INSERT INTO preprojet.comptes VALUES (123602364, 2);
INSERT INTO preprojet.comptes VALUES (563212564, 2);
INSERT INTO preprojet.comptes VALUES (789623565, 3);

INSERT INTO preprojet.operations VALUES (DEFAULT, 123456789, 563212564, 100, '2006-12-01');
INSERT INTO preprojet.operations VALUES (DEFAULT, 563212564, 123602364, 120, '2006-12-02');
INSERT INTO preprojet.operations VALUES (DEFAULT, 987687654, 789623565, 80, '2006-12-03');
INSERT INTO preprojet.operations VALUES (DEFAULT, 789623565, 987687654, 80, '2006-12-04');
INSERT INTO preprojet.operations VALUES (DEFAULT, 123602364, 789623565, 150, '2006-12-05');
INSERT INTO preprojet.operations VALUES (DEFAULT, 563212564, 123602364, 120, '2006-12-06');
INSERT INTO preprojet.operations VALUES (DEFAULT, 123456789, 563212564, 100, '2006-12-07');
INSERT INTO preprojet.operations VALUES (DEFAULT, 987687654, 789623565, 80, '2006-12-08');
INSERT INTO preprojet.operations VALUES (DEFAULT, 789623565, 987687654, 80, '2006-12-09');

-- QUESTION 4

select distinct pers_src.nom as "Nom source", pers_src.prenom as "Prenom source", cpt_src.numero as "Compte source",
                pers_dest.nom as "Nom destination", pers_dest.prenom as "Prenom destination", cpt_dest.numero as "Compte destination",
                o.date_op as "Date operation", o.montant as "Montant"
    from preprojet.personnes pers_src, preprojet.personnes pers_dest, preprojet.comptes cpt_src,preprojet.comptes cpt_dest , preprojet.operations o
    where pers_src.id_personne = cpt_src.id_personne and o.compte_source = cpt_src.numero
    and pers_dest.id_personne = cpt_dest.id_personne and o.compte_destination = cpt_dest.numero
    order by  o.date_op;

-- QUESTION 5

CREATE OR REPLACE FUNCTION preprojet.insererOperation(nom_source VARCHAR(100), prenom_source VARCHAR(100), compte_source CHARACTER(9),
    nom_destination VARCHAR(100), prenom_destination VARCHAR(100), compte_destination CHARACTER(9),
    date_operation TIMESTAMP, montant_operation INTEGER) RETURNS INTEGER AS $$
    DECLARE
        id INTEGER:=0;
    BEGIN
        IF NOT EXISTS(SELECT * FROM preprojet.comptes c, preprojet.personnes p
                        WHERE c.numero=compte_source
                        AND c.id_personne=p.id_personne
                        AND p.nom=nom_source
                        AND	p.prenom=prenom_source)
        THEN
            RAISE foreign_key_violation;
        END IF;
        IF NOT EXISTS(SELECT * FROM preprojet.comptes c, preprojet.personnes p
                        WHERE c.numero=compte_destination
                        AND c.id_personne=p.id_personne
                        AND p.nom=nom_destination
                        AND	p.prenom=prenom_destination)
        THEN
            RAISE foreign_key_violation;
        END IF;
        INSERT INTO preprojet.operations VALUES (DEFAULT,compte_source,compte_destination,montant_operation,date_operation)
            RETURNING id_operation INTO id;
        RETURN id;
    END;
$$ LANGUAGE plpgsql;
-- QUESTION 5
select * from preprojet.insererOperation(VARCHAR(100) 'Damas', VARCHAR(100) 'Christophe',
    CHARACTER(9) '123456789', VARCHAR(100) 'Ferneeuw', VARCHAR(100) 'Stephanie',
    CHARACTER(9) '789623565', TIMESTAMP '2022-10-22', 20);

-- QUESTION 6

CREATE OR REPLACE FUNCTION preprojet.modifierMontantOperation(nom_source VARCHAR(100), prenom_source VARCHAR(100),
    cpt_source CHARACTER(9), nom_destination VARCHAR(100), prenom_destination VARCHAR(100), cpt_destination CHARACTER(9),
    date_operation TIMESTAMP, montant_operation INTEGER) RETURNS INTEGER AS $$
    DECLARE
        operation RECORD;
    BEGIN
        /*
        IF((select count(o.id_operation)
            from preprojet.comptes cpt_src, preprojet.comptes cpt_dest, preprojet.operations o
            where o.compte_source = cpt_source and o.compte_destination = cpt_destination
            ) <> 1)
        THEN
            RAISE foreign_key_violation;
        ELSE
         */
            select distinct o.*
            from preprojet.comptes cpt_src, preprojet.comptes cpt_dest, preprojet.operations o
            where o.compte_source = cpt_source and o.compte_destination = cpt_destination and o.date_op = date_operation
            INTO operation;
            UPDATE preprojet.operations op SET montant=montant_operation where op.id_operation = operation.id_operation;
        --END IF;
    END;
$$ LANGUAGE  plpgsql;

-- verif update : ok
--UPDATE preprojet.operations op SET montant='20' where op.id_operation = 1;
-- verif timestamp in select : ok
--select * from preprojet.operations where date_op = '2006-12-01';
-- verif select question 6 : ok
--select distinct o.*
--from preprojet.comptes cpt_src, preprojet.comptes cpt_dest, preprojet.operations o
--where o.compte_source = '123456789' and o.compte_destination = '563212564' and o.date_op = '2006-12-01';

-- QUESTION 6
SELECT * FROM preprojet.modifierMontantOperation(VARCHAR(100) 'Damas',VARCHAR(100) 'Christophe',
    CHARACTER(9) '123456789',VARCHAR(100) 'Cambron',VARCHAR(100) 'Isabelle',
    CHARACTER(9) '563212564', TIMESTAMP '2006-12-01', 10);

-- QUESTION 7



-- QUESTION 8



-- QUESTION 9



-- QUESTION 10



-- TESTS

-- Personnes
--select * from preprojet.personnes;
-- Comptes
--select * from preprojet.comptes;
-- Operations
--select * from preprojet.operations;
