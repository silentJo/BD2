import java.sql.*;
import java.util.Scanner;

public class ApplicationEtudiants {
    public static Scanner scanner = new Scanner(System.in);
    private String url = "jdbc:postgresql://localhost:5432/postgres";

    private Connection connection = null;
    private StudentActions studentActions = null;

    public ApplicationEtudiants(){
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
        studentActions = new StudentActions(connection);
    }

    static void getException(Exception e) {
        String string = "Exception levée : " + e.getLocalizedMessage().split(":")[1].split("Où")[0] + "\n";
        System.out.println(string);
    }

    public static void main(String[] args) {
        boolean running = true;
        String choix = "0";
        ApplicationEtudiants app = new ApplicationEtudiants();

        System.out.println("Veuillez vous connecter\n");
        if(app.studentActions.seConnecter()) {
            while(running) {
                System.out.println("1 - visualiserCours");
                System.out.println("2 - inscriptionAuGroupe");
                System.out.println("3 - retirerDuGroupe");
                System.out.println("4 - visualiserProjets");
                System.out.println("5 - visualiserProjetsSansGroupes");
                System.out.println("6 - visualiserGroupesIncomplets");
                System.out.println("q - Fermer l'application \n");

                System.out.print("Votre choix : ");
                choix = scanner.nextLine();

                switch (choix) {
                    case "1" -> app.studentActions.visualiserCours();
                    case "2" -> app.studentActions.inscriptionAuGroupe();
                    case "3" -> app.studentActions.retirerDuGroupe();
                    case "4" -> app.studentActions.visualiserProjets();
                    case "5" -> app.studentActions.visualiserProjetsSansGroupes();
                    case "6" -> app.studentActions.visualiserGroupesIncomplets();
                    case "q" -> running = false;
                    default ->
                            System.out.println("Veuillez choisir un chiffre entre 1 et 10!");
                }
                System.out.println("\n\n");
            }
        }
        else {
            System.out.println("Mauvais identifiants");
            app.close();
        }
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