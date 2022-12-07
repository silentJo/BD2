import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Scanner;

public class ApplicationCentrale {

    public static Scanner scanner = new Scanner(System.in);
    private String url = "jdbc:postgresql://localhost:5432/postgres";

    private Connection connection = null;
    private PreparedStatement example;

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
    }

    public void example() {
        try {
            example = connection.prepareStatement("SELECT * FROM projet.cours()");

            System.out.printf("\n%-10s %-20s", "Output",
                    example.execute() == true ? "example OK !\n" : "example KO !\n");
        } catch (SQLException e) {
            getException(e);
        }
    }

    private void getException(Exception e) {
        String string = "Exception levée : " + e.getLocalizedMessage().split(":")[1].split("Où")[0] + "\n";
        System.out.println(string);
    }

    public static void main(String[] args) {
        boolean running = true;
        String FORMAT_MENU = "%-10s  %-40s | %-10s %-40s | %-10s %-40s\n";
        String FORMAT_INPUT = "%-10s %-40s";
        String FORMAT_OUTPUT_MESSAGE = "%-10s %-20s\n\n";
        String choix = "0";
        ApplicationCentrale app = new ApplicationCentrale();

        System.out.println();
        while(running) {
            System.out.println("\n1 - example\n");

            choix = scanner.nextLine();

            switch (choix) {
                case "1": {
                    app.example();
                    break;
                }
                default:
                    System.out.printf(FORMAT_OUTPUT_MESSAGE, "Output", "Veuillez choisir un chiffre entre 1 et 10!\n");

                    break;
            }

        }
        app.close();
    }

    public void close() {
        try {
            System.out.println("Tentative de déconnexion: ");
            connection.close();
            System.out.println("Deconnecté du serveur : " + url);
        } catch (SQLException e) {
            System.out.println("Problème de déconnexion !");
            getException(e);
        }
    }
}