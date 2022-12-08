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

    public void seConnecter() {
        try {
            seConnecterPreparedStatement = connection.prepareStatement("SELECT * FROM projet.seConnecter(?) " +
                    "t(id INTEGER, mdp VARCHAR(74))");
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
                        } else {
                            System.out.println("Impossible de se connecter");
                        }
                    }
                }
            } catch (SQLException e) {
                System.out.println("Erreur avec les requêtes SQL !");
                System.exit(1);
            }
        } catch (SQLException e) {
            System.out.println("L'ajout de cours a échoué ! -> prepareStatement KO !");
            ApplicationEtudiants.getException(e);
        }
    }

    public void visualiserCours() {
        try {
            visualiserCoursPreparedStatement = connection.prepareStatement("SELECT * FROM projet.visualiser_mes_cours()");
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
    }

    public void retirerDuGroupe() {
    }

    public void visualiserProjets() {
    }

    public void visualiserProjetsSansGroupes() {
    }

    public void visualiserGroupesIncomplets() {
    }
}
