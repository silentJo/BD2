import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Scanner;

public class StudentActions {

    private static final Scanner scanner = new Scanner(System.in);
    private Connection connection = null;
    private static int idEtudiant = 0;

    PreparedStatement seConnecterPreparedStatement, visualiserCoursPreparedStatement, inscriptionAuGroupePreparedStatement,
            retirerDuGroupePreparedStatement, visualiserProjetsPreparedStatement,
            visualiserProjetsSansGroupesPreparedStatement, visualiserGroupesIncompletsPreparedStatement;

    public StudentActions(Connection connection) {
        this.connection = connection;
    }

    public boolean seConnecter() {
        try {
            seConnecterPreparedStatement = connection.prepareStatement("SELECT * FROM projet.seConnecter(?) " +
                    "t(id INTEGER, mdp VARCHAR(60))");
            try {
                System.out.println("Email : ");
                String email = scanner.next();
                scanner.nextLine();
                System.out.println("Mot de passe : ");
                String mdp = scanner.next();
                scanner.nextLine();
                seConnecterPreparedStatement.setString(1, email);
                try (ResultSet rs = seConnecterPreparedStatement.executeQuery()) {
                    int id = 0;
                    String hashedMDP = "";
                    if (rs.next()) {
                        id = rs.getInt(1);
                        hashedMDP = rs.getString(2);
                        if (BCrypt.checkpw(mdp, hashedMDP)) {
                            idEtudiant = id;
                            System.out.println("id étudiant : " + idEtudiant);
                            return true;
                        } else {
                            System.out.println("Impossible de se connecter");
                            return false;
                        }
                    }
                }
            } catch (SQLException e) {
                System.out.println("Erreur avec les requêtes SQL !" + e);
                System.exit(1);
            }
        } catch (SQLException e) {
            System.out.println("L'ajout de cours a échoué ! -> prepareStatement KO !");
            ApplicationEtudiants.getException(e);
        }
        return false;
    }

    public void visualiserCours() {
        try {
            visualiserCoursPreparedStatement = connection.prepareStatement("SELECT * FROM projet.visualiser_mes_cours where \"etudiant\" = " + idEtudiant);
            try (ResultSet rs = visualiserCoursPreparedStatement.executeQuery()) {
                System.out.printf("%-10s     | %-10s | %-20s | %-30s| \n", "", "Code", "Nom", "Projet");
                while (rs.next()) {
                    System.out.printf("%-10s ->  | %-10s | %-20s | %-30s|\n",
                            "Cours",
                            rs.getString(1),
                            rs.getString(2),
                            rs.getString(3));
                }
            } catch (SQLException e) {
                System.out.println("Impossible de visualiser les cours.");
                ApplicationEtudiants.getException(e);
            }
        } catch (SQLException e) {
            System.out.println("Impossible de visualiser les cours -> prepareStatement KO !");
            ApplicationEtudiants.getException(e);
        }
    }

    public void inscriptionAuGroupe() {
        try {
            inscriptionAuGroupePreparedStatement = connection.prepareStatement("SELECT * FROM projet.inscription_groupe(?, ?, ?)");
            try {
                inscriptionAuGroupePreparedStatement.setInt(1, idEtudiant);

                System.out.println("\nIdentifiant du projet : ");
                String identifiant = scanner.nextLine();
                inscriptionAuGroupePreparedStatement.setString(2, identifiant);

                System.out.println("\nNuméro de groupe : ");
                int numGroupe = Integer.parseInt(scanner.nextLine());
                inscriptionAuGroupePreparedStatement.setInt(3, numGroupe);

                System.out.println(inscriptionAuGroupePreparedStatement.execute() ? "Inscrit." : "Non inscrit.");

            } catch (SQLException e) {
                System.out.println("Impossible de s'inscrire au groupe.");
                ApplicationEtudiants.getException(e);
            }
        } catch (SQLException e) {
            System.out.println("Impossible de s'inscrire au groupe -> prepareStatement KO !");
            ApplicationEtudiants.getException(e);
        }
    }

    public void retirerDuGroupe() {
        try {
            retirerDuGroupePreparedStatement = connection.prepareCall("CALL projet.retirer_du_groupe(?, ?, ?)");
            try {
                //nid_etudiant INTEGER, nnum_groupe INTEGER, nidentifiant VARCHAR(20)
                retirerDuGroupePreparedStatement.setInt(1, idEtudiant);

                System.out.println("\nIdentifiant du projet");
                String identifiant = scanner.nextLine();
                retirerDuGroupePreparedStatement.setString(3, identifiant);


                System.out.println("\nNuméro de groupe : ");
                int numGroupe = Integer.parseInt(scanner.nextLine());
                retirerDuGroupePreparedStatement.setInt(2, numGroupe);

                System.out.println(retirerDuGroupePreparedStatement.executeUpdate() == 0 ? "Retiré." : "Non retiré.");
            } catch (SQLException e) {
                System.out.println("Impossible de se retirer du groupe.");
                ApplicationEtudiants.getException(e);
            }
        } catch (SQLException e) {
            System.out.println("Impossible de se retirer du groupe -> prepareStatement KO !");
            ApplicationEtudiants.getException(e);
        }
    }

    public void visualiserProjets() {
        try {
            visualiserProjetsPreparedStatement = connection.prepareStatement("SELECT * FROM projet.visualiser_mes_projets where \"Etudiant\" = " + idEtudiant);
            try (ResultSet rs = visualiserProjetsPreparedStatement.executeQuery()) {
                System.out.printf("%-10s     | %-20s | %-20s | %-20s | %-10s | \n",
                        "", "Identifiant", "Nom", "Code", "Num");
                while (rs.next()) {
                    System.out.printf("\"%-10s     | %-20s | %-20s | %-20s | %-10s | \n",
                            "Projet",
                            rs.getString(1),
                            rs.getString(2),
                            rs.getString(3),
                            rs.getInt(4));
                }
                System.out.println();
            } catch (SQLException e) {
                System.out.println("Impossible de visualiser les projets.");
                ApplicationEtudiants.getException(e);
            }
        } catch (SQLException e) {
            System.out.println("Impossible de visualiser les projets -> prepareStatement KO !");
            ApplicationEtudiants.getException(e);
        }
    }

    public void visualiserProjetsSansGroupes() {
        try {
            visualiserProjetsSansGroupesPreparedStatement = connection.prepareStatement("select * from projet.visualiser_mes_projets_sans_groupes where \"Etudiant\" = " + idEtudiant);

            try (ResultSet rs = visualiserProjetsSansGroupesPreparedStatement.executeQuery()) {
                System.out.printf("%-10s     | %-20s | %-20s | %-20s | %-10s | %-10s | \n",
                        "", "Identifiant", "Nom", "Cours", "Debut", "Fin");
                while (rs.next()) {
                    System.out.printf("\"%-10s     | %-20s | %-20s | %-20s | %-10s | %-10s | \n",
                            "Projet",
                            rs.getString(1),
                            rs.getString(2),
                            rs.getString(3),
                            rs.getTimestamp(4),
                            rs.getTimestamp(5));
                }
                System.out.println();
            } catch (SQLException e) {
                System.out.println("Impossible de visualiser les projets sans groupes.");
                ApplicationEtudiants.getException(e);
            }
        } catch (SQLException e) {
            System.out.println("Impossible de visualiser les projets sans groupes -> prepareStatement KO !");
            ApplicationEtudiants.getException(e);
        }
    }

    public void visualiserGroupesIncomplets() {
        try {
            visualiserGroupesIncompletsPreparedStatement = connection.prepareStatement("select * from projet.visualiser_groupes_incomplets("+idEtudiant+", (?)) " +
                    "t(numero integer, nom varchar(20), prenom varchar(20), places integer, etudiant integer, identifiant varchar(20))");

            try {
                System.out.println("\nIdentifiant");
                String identifiant = scanner.nextLine();
                visualiserGroupesIncompletsPreparedStatement.setString(1, identifiant);

                ResultSet rs = visualiserGroupesIncompletsPreparedStatement.executeQuery();
                System.out.printf("%-10s     | %-10s | %-20s | %-20s | %-10s | \n",
                        "", "Numéro", "Nom", "Prenom", "Nombre de places");
                while (rs.next()) {
                    System.out.printf("\"%-10s     | %-10s | %-20s | %-20s | %-10s | \n",
                            "Projet",
                            rs.getInt(1),
                            rs.getString(2),
                            rs.getString(3),
                            rs.getInt(4));
                }
                System.out.println();
            } catch (SQLException e) {
                System.out.println("Impossible de visualiser les groupes incomplets." + e);
                ApplicationEtudiants.getException(e);
            }
        } catch (SQLException e) {
            System.out.println("Impossible de visualiser les incomplets -> prepareStatement KO !");
            ApplicationEtudiants.getException(e);
        }
    }
}
