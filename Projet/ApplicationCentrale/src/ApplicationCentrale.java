import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Scanner;

public class ApplicationCentrale {

    public static Scanner scanner = new Scanner(System.in);
    private String url = "jdbc:postgresql://localhost:5432/postgres";

    private Connection connection = null;
    private AdminActions adminActions = null;

    public ApplicationCentrale(){
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException classNotFoundException) {
            System.out.println("Driver Postgres manquant.");
            System.exit(1);
        }

        try {
            // Username e.g : postgres, Password e.g : SQL123
            connection = DriverManager.getConnection(url, "postgres", "SQL123");
        } catch (SQLException e) {
            System.out.println("Connection au serveur échouée : " + e.getMessage());
            System.exit(1);
        }
        adminActions = new AdminActions(connection);
    }

    static void getException(Exception e) {
        String string = "Exception levée : " + e.getLocalizedMessage().split(":")[1].split("Où")[0] + "\n";
        System.out.println(string);
    }

    public static void main(String[] args) {
        boolean running = true;
        String choix = "0";
        ApplicationCentrale app = new ApplicationCentrale();

        System.out.println();
        while(running) {
            System.out.println("1 - Ajouter un cours");
            System.out.println("2 - Ajouter un étudiant");
            System.out.println("3 - Inscrire un étudiant à un cours");
            System.out.println("4 - Créer un projet pour un cours");
            System.out.println("5 - Créer des groupes pour un projet");
            System.out.println("6 - Visualiser les cours");
            System.out.println("7 - Visualiser tous les projets");
            System.out.println("8 - Visualiser toutes les compositions de groupe d’un projet");
            System.out.println("9 - Valider un groupe");
            System.out.println("10 - valider tous les groupes d'un projet");
            System.out.println("q - Fermer l'application \n");

            System.out.print("Votre choix : ");
            choix = scanner.nextLine();

            switch (choix) {
                case "1" -> app.adminActions.addCourse();
                case "2" -> app.adminActions.addStudent();
                case "3" -> app.adminActions.enrollStudentInCourse();
                case "4" -> app.adminActions.createCourseProject();
                case "5" -> app.adminActions.createProjectGroups();
                case "6" -> app.adminActions.seeCourses();
                case "7" -> app.adminActions.seeAllProjects();
                case "8" -> app.adminActions.seeProjectGroupsCompositions();
                case "9" -> app.adminActions.validateGroup();
                case "10" -> app.adminActions.validateAllProjectGroups();
                case "q" -> running = false;
                default ->
                        System.out.println("Veuillez choisir un chiffre entre 1 et 10!");
            }
            System.out.println("\n\n");
        }
        app.close();
    }

    public void close() {
        try {
            System.out.println("Tentative de déconnexion: ");
            connection.close();
            System.out.println("Déconnecté du serveur : " + url);
            System.out.println("Aurevoir !");
        } catch (SQLException e) {
            System.out.println("Problème de déconnexion !");
            getException(e);
        }
    }
}