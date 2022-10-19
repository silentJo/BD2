/**
 * @Authors: Mariam Ajattar, Jonathan Casier
 */

import java.sql.*;
import java.util.Scanner;

public class ApplicationEtudiant {

    private static final Scanner scanner = new Scanner(System.in);
    private final String url = "jdbc:postgresql://localhost:5432/postgres";
    private Connection conn = null;
    private static int idEtudiant = 0;

    PreparedStatement seConnecter, ajouterUEauPAE, enleverUEauPAE, validerPAE,
            afficherUEaAjouterAuPAE, visualiserSonPAE, reinitialiserPAE;

    public ApplicationEtudiant() {
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            System.out.println("Driver PostgreSQL manquant !");
            System.exit(1);
        }
        try {
            String username = "postgres", password = "SQL123";
            conn = DriverManager.getConnection(url, username, password);
        } catch (SQLException e) {
            System.out.println("Impossible de joindre le server !");
            System.exit(1);
        }
        try {
            seConnecter = conn.prepareStatement("SELECT * FROM projet.seConnecter(?) " +
                    "t(id INTEGER, mdp VARCHAR(74))");
            ajouterUEauPAE = conn.prepareStatement("SELECT * FROM projet.ajouterUEauPAE(?, ?)");
            enleverUEauPAE = conn.prepareStatement("select * from projet.enleverUEauPAE(?, ?)");
            validerPAE = conn.prepareStatement("SELECT * FROM projet.validerPAE(?) ");
            afficherUEaAjouterAuPAE = conn.prepareStatement("SELECT * FROM projet.afficherUEaAjouterAuPAE(?)" +
                    "t(code VARCHAR(10), nom VARCHAR(30), nb_credits INTEGER, id_bloc INTEGER)");
            visualiserSonPAE = conn.prepareStatement("SELECT * FROM projet.visualiserSonPAE(?)" +
                    "t(code VARCHAR(10), nom VARCHAR(30), nb_credits INTEGER, id_bloc INTEGER)");
            reinitialiserPAE = conn.prepareStatement("SELECT * FROM projet.reinitialiserPAE(?) ");
        } catch (SQLException e) {
            System.out.println("Erreur avec les requêtes SQL !");
            System.exit(1);
        }
    }

    public void seConnecter() {
        //TODO si l'user n'existe pas, géré l'exception (NullPointerException)
        System.out.println("Vous avez choisis de vous connecter,\n" +
                "pour ce faire nous avons besoin de votre email et de votre mot de passe");
        try {
            System.out.println("Email : ");
            String email = scanner.next();
            scanner.nextLine();
            System.out.println("Mot de passe : ");
            String mdp = scanner.next();
            scanner.nextLine();
            seConnecter.setString(1, email);
            try (ResultSet rs = seConnecter.executeQuery()) {
                int id = 0;
                String hashedMDP = "";
                if(rs.next()) {
                    id = rs.getInt(1);
                    hashedMDP = rs.getString(2);
                    if(BCrypt.checkpw(mdp, hashedMDP)) {
                        idEtudiant = id;
                        System.out.println("id étudiant : " + idEtudiant);
                    } else {
                        System.out.println("Impossible de se connecter");
                    }
                }
            }
        } catch (SQLException e) {
            getException(e);
        }
    }

    /* AE 1 */
    public void ajouterUEauPAE() {
        System.out.println("Vous avez choisis d'ajouter une UE à votre PAE,\n" +
                "pour ce faire nous avons besoin du code de l'ue : ");
        try {
            //Récupération des paramètres pour le prepareStatement
            System.out.println("Code UE :");
            String codeUE = scanner.next().toUpperCase();
            scanner.nextLine();
            //Attribution des paramètres au prepareStatement
            ajouterUEauPAE.setString(1, codeUE);
            ajouterUEauPAE.setInt(2, idEtudiant);
            //Exécution du prepareStatement
            if (ajouterUEauPAE.execute())
                System.out.println("UE ajoutée au PAE");
            else
                System.out.println("UE non ajoutée au PAE");
        } catch (SQLException e) {
            getException(e);
        }
    }

    /* AE 2 */
    public void enleverUEduPAE() {
        System.out.println("Vous avez choisis d'enlever une UE du PAE,\n" +
                "pour ce faire nous avons besoin du code de l'UE : ");
        try {
            //Récupération des paramètres pour le prepareStatement
            System.out.println("Code UE :");
            String codeUE = scanner.next().toUpperCase();
            scanner.nextLine();
            //Attribution des paramètres au prepareStatement
            enleverUEauPAE.setString(1, codeUE);
            enleverUEauPAE.setInt(2, idEtudiant);
            //Exécution du prepareStatement
            if (enleverUEauPAE.execute())
                System.out.println("UE enlevée du PAE");
            else
                System.out.println("UE non enlevée du PAE");
        } catch (SQLException e) {
            getException(e);
        }
    }

    /* AE 3 */
    public void validerPAE() {
        System.out.println("Vous avez choisis de valider votre PAE,\n" +
                "pour ce faire nous avons besoin du bloc : ");
        try {
            //Récupération des paramètres pour le prepareStatement
            System.out.println("Bloc :");
            int bloc = scanner.nextInt();
            scanner.nextLine();
            //Attribution des paramètres au prepareStatement
            validerPAE.setInt(1, idEtudiant);
            //Exécution du prepareStatement
            if (validerPAE.execute())
                System.out.println("PAE validé");
            else
                System.out.println("PAE non validé");
        } catch (SQLException e) {
            getException(e);
        }
    }


    /* AE 4 */
    public void afficherUEaAjouterAuPAE() {
        System.out.println("Vous avez choisis de visualiser les UEs disponnibles :");
        try {
            //Récupération des paramètres pour le prepareStatement
            //Attribution des paramètres au prepareStatement
            afficherUEaAjouterAuPAE.setInt(1, idEtudiant);
            //Exécution du prepareStatement
            try (ResultSet rs = afficherUEaAjouterAuPAE.executeQuery()) {
                System.out.printf("\n%20s %20s %10s %10s\n",
                        "code",
                        "nom",
                        "nb_credits",
                        "id_bloc");
                System.out.printf("%20s %20s %10s %10s",
                        "====",
                        "===",
                        "==========",
                        "=======");
                while (rs.next()) {
                    System.out.printf("\n%20s %20s %10s %10s",
                            rs.getString(1),
                            rs.getString(2),
                            rs.getInt(3),
                            rs.getInt(4)
                    );
                }
            }
        } catch (SQLException e) {
            getException(e);
        }
    }

    /* AE 5 */ //est-ce que ce serait pas une vue ça par hasard ?
    public void visualiserSonPAE() {
        System.out.println("Vous avez choisis de visualiser votre PAE :");
        try {
            //Récupération des paramètres pour le prepareStatement
            //Attribution des paramètres au prepareStatement
            visualiserSonPAE.setInt(1, idEtudiant);
            //Exécution du prepareStatement
            try (ResultSet rs = visualiserSonPAE.executeQuery()) {
                System.out.printf("\n%20s %20s %10s %10s\n",
                        "code",
                        "nom",
                        "nb_credits",
                        "id_bloc");
                System.out.printf("%20s %20s %10s %10s",
                        "====",
                        "===",
                        "==========",
                        "=======");
                while (rs.next()) {
                    System.out.printf("\n%20s %20s %10s %10s",
                    rs.getString(1),
                    rs.getString(2),
                    rs.getInt(3),
                    rs.getInt(4)
                    );
                }
            }
        } catch (SQLException e) {
            getException(e);
        }
    }


    /* AE 6 */
    public void reinitialiserPAE() {
        System.out.println("Vous avez choisis de visualiser votre PAE :");
        try {
            reinitialiserPAE.setInt(1, idEtudiant);
            if (reinitialiserPAE.execute())
                System.out.println("PAE réinitialisé");
            else
                System.out.println("PAE non réinitialisé");
        } catch (SQLException e) {
            getException(e);
        }
    }

    public void close() {
        try {
            System.out.println("Tentative de déconnexion");
            conn.close();
            System.out.print("Déconnecté du serveur : " + url);
        } catch (SQLException e) {
            System.out.print("Problème à la déconnexion !");
            getException(e);
        }
    }

    private static void getException(Exception e) {
        String message = "Exception levée : " + e.getLocalizedMessage().split(":")[1].split("Où")[0] + "\n";
        System.out.println(message);
    }

    public static void main(String[] args) {
        boolean running = true;
        ApplicationEtudiant app = new ApplicationEtudiant();

        while (running) {
            System.out.println("\n***********\tApplication Étudiant\t***********\n");
            System.out.println("""
                    1\t->\tSe connecter
                    2\t->\tAjouter une UE au PAE
                    3\t->\tEnlever une UE au PAE
                    4\t->\tValider mon PAE
                    5\t->\tAfficher les UE qu'il est possible d'ajouter au PAE
                    6\t->\tVisualiser mon PAE
                    7\t->\tRéinitialiser mon PAE
                                        
                    0\t->\tArrêter l'application centrale
                    """);
            System.out.println("Entrez votrez choix :");

            int choix = scanner.nextInt();

            switch (choix) {
                case 1 -> app.seConnecter();
                case 2 -> app.ajouterUEauPAE();
                case 3 -> app.enleverUEduPAE();
                case 4 -> app.validerPAE();
                case 5 -> app.afficherUEaAjouterAuPAE();
                case 6 -> app.visualiserSonPAE();
                case 7 -> app.reinitialiserPAE();
                case 0 -> {
                    running = false;
                    System.out.println("Application centrale arrêtée");
                }
                default -> System.out.println("Veuillez choisir un chiffre entre 0 et 7 !\n");
            }
        }
        app.close();
    }
}
