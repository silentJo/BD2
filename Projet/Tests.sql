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

-- inscrire etudiant
select * from projet.inscrire_etudiant(1, CHARACTER(8) 'BINV1345');
select * from projet.inscrire_etudiant(2, CHARACTER(8) 'BINV1345');
select * from projet.inscrire_etudiant(3, CHARACTER(8) 'BINV1345');

-- creer projet
select * from projet.creer_projet(CHARACTER(8) 'BINV1345', VARCHAR(20) '1p1',
    TIMESTAMP '2022-09-01', TIMESTAMP '2023-06-30');
select * from projet.creer_projet(CHARACTER(8) 'BINV1345', VARCHAR(20) '1p2',
    TIMESTAMP '2022-09-01', TIMESTAMP '2023-06-30');
select * from projet.creer_projet(CHARACTER(8) 'BINV1345', VARCHAR(20) '1p3',
    TIMESTAMP '2022-09-01', TIMESTAMP '2023-06-30');

-- crer groupe
select * from projet.creer_groupes(1, 1, 3);
select * from projet.creer_groupes(2, 1, 3);
select * from projet.creer_groupes(3, 1, 3);

-- inscription au groupe
select * from projet.inscription_groupe(1, 1, 1);
select * from projet.inscription_groupe(2, 1, 1);
select * from projet.inscription_groupe(3, 1, 1);

-- valider groupe
--select * from projet.valider_groupe(1, 1);

-- se retirer du groupe
select * from projet.retirer_du_groupe(1, 1, 1);

select * from projet.groupes;
select * from projet.membres_groupe;
