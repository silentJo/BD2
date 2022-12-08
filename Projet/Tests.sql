truncate projet.inscriptions_cours restart identity cascade;
truncate projet.membres_groupe restart identity cascade;
truncate projet.projets restart identity cascade;
truncate projet.groupes restart identity cascade;
truncate projet.cours restart identity cascade;
truncate projet.etudiants restart identity cascade;

--============================================================================
--=                                    TEST                                  =
--============================================================================
-- encoder cours
select * from projet.encoder_cours(CHARACTER(8) 'BINV1234', VARCHAR(20) 'cours 1', 1, 3);
select * from projet.encoder_cours(CHARACTER(8) 'BINV1345', VARCHAR(20) 'cours 2', 2, 6);
select * from projet.encoder_cours(CHARACTER(8) 'BINV1456', VARCHAR(20) 'cours 3', 3, 9);

-- encoder etudiant
select * from projet.encoder_etudiant(VARCHAR(20) 'Damas', VARCHAR(20) 'Christophe',
                             VARCHAR(50) 'christophe.damas@student.vinci.be', VARCHAR(20) 'mdp_cd');
select * from projet.encoder_etudiant(VARCHAR(20) 'Ferneeuw', VARCHAR(20) 'Stéphanie',
                             VARCHAR(50) 'stephanie.ferneeuw@student.vinci.be', VARCHAR(20) 'mdp_sf');
select * from projet.encoder_etudiant(VARCHAR(20) 'Lehmann', VARCHAR(20) 'Brigitte',
                             VARCHAR(50) 'brigitte.lehmann@student.vinci.be', VARCHAR(20) 'mdp_bl');
select * from projet.etudiants;
-- inscrire etudiant
call projet.inscrire_etudiant(1, CHARACTER(8) 'BINV1345');
call projet.inscrire_etudiant(2, CHARACTER(8) 'BINV1345');
call projet.inscrire_etudiant(3, CHARACTER(8) 'BINV1345');

-- creer projet
select * from projet.creer_projet(VARCHAR(20) 'projSQL', CHARACTER(8) 'BINV1345', VARCHAR(20) '1p1',
    TIMESTAMP '2022-09-01', TIMESTAMP '2023-06-30');
select * from projet.creer_projet(VARCHAR(20) 'dsd', CHARACTER(8) 'BINV1345', VARCHAR(20) '1p2',
    TIMESTAMP '2022-09-01', TIMESTAMP '2023-06-30');

-- crer groupe
call projet.creer_groupes('projSQL', 2, 2);
call projet.creer_groupes('projSQL', 2, 2);

-- inscription au groupe
select * from projet.inscription_groupe(1, 'projSQL', 1);
select * from projet.inscription_groupe(2, 'projSQL', 1);
select * from projet.inscription_groupe(3, 'projSQL', 2);

select * from projet.visualiser_projets;

-- valider groupe
--call projet.valider_groupe('projSQL', 1);

-- se retirer du groupe
call projet.retirer_du_groupe(1, 3, VARCHAR(20) 'projSD');
delete from projet.membres_groupe where etudiant = 1 and groupe = 1 and projet = 3;

select g.est_valide from projet.groupes g where g.num = 1 and g.id_projet =1;

select * from projet.groupes;
select * from projet.membres_groupe;

select * from projet.cours;
select * from projet.etudiants;
select * from projet.inscriptions_cours;
select * from projet.projets;
select * from projet.groupes;
select * from projet.membres_groupe;
