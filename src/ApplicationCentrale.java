/**
 * @Authors: Mariam Ajattar, Jonathan Casier
 */

import java.sql.*;
import java.util.Scanner;

import static java.lang.Integer.parseInt;

public class ApplicationCentrale {

    private static final Scanner scanner = new Scanner(System.in);
    private final String url = "jdbc:postgresql://localhost:5432/postgres";
    private Connection conn = null;

    PreparedStatement ajouterUE, ajouterEtudiant, encoderUEValideePourEtudiant, visualiserEtudiantsDUnBloc,
            VisualiserCreditsDeTousLesEtudiants, visualiserEtudiantsSansPAEValide, visualiserUESDUnBloc;

    public ApplicationCentrale() {
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
            ajouterUE = conn.prepareStatement("SELECT * FROM projet.ajouterUE(?,?,?,?)");
            ajouterEtudiant = conn.prepareStatement("SELECT * FROM projet.ajouterEtudiant(?,?,?,?)");
            encoderUEValideePourEtudiant = conn.prepareStatement("select * from projet.ajouterUEValidee(?, ?)");
            visualiserEtudiantsDUnBloc = conn.prepareStatement(
                    "SELECT  ID, NOM, PRENOM, NB_CREDITS FROM projet.visualiserEtudiantsDUnBloc(?) " +
                            "t(id INTEGER, nom VARCHAR, prenom VARCHAR, nb_credits BIGINT)");
            VisualiserCreditsDeTousLesEtudiants = conn.prepareStatement(
                    "SELECT * FROM projet.visualiserTousLesEtudiants");
            visualiserEtudiantsSansPAEValide = conn.prepareStatement(
                    "SELECT * FROM projet.visaliserEtudiantsAvecPAENonValide");
            visualiserUESDUnBloc = conn.prepareStatement(
                    "SELECT DISTINCT code, nom, nb_inscrits FROM projet.visualiserUESDUnBloc(?) " +
                            "t(code VARCHAR, nom VARCHAR, nb_inscrits INTEGER)");
        } catch (SQLException e) {
            System.out.println("Erreur avec les requêtes SQL !");
            System.exit(1);
        }
    }

    /* AC 1 */
    public void ajouterUE() {
        System.out.println("Vous avez choisis d'ajouter une UE,\n" +
                "pour ce faire nous avons besoin du code de l'ue, de son nom, son nombre de crédits," +
                "du nombre d'inscrits ainsi que de l'id du bloc dans lequel l'UE sera.");
        try {
            //Récupération des paramètres pour le prepareStatement
            System.out.println("Code UE :");
            String codeUE = scanner.next().toUpperCase();
            scanner.nextLine();
            System.out.println("Nom :");
            String nomUE = scanner.nextLine().toUpperCase();
            System.out.println("Nombre de crédits :");
            int nb_credits = scanner.nextInt();
            scanner.nextLine();
            System.out.println("Id bloc :");
            int id_bloc = scanner.nextInt();
            scanner.nextLine();
            int id_bloc_C = parseInt(codeUE.substring(4, 5));
            if(id_bloc==id_bloc_C) {
                //Attribution des paramètres au prepareStatement
                ajouterUE.setString(1, codeUE);
                ajouterUE.setString(2, nomUE);
                ajouterUE.setInt(3, nb_credits);
                ajouterUE.setInt(4, id_bloc);

                //Exécution du prepareStatement
                if (ajouterUE.execute())
                    System.out.println("UE ajoutée");
                else
                    System.out.println("UE non ajoutée");
            }
            else
                System.out.println("UE non ajoutée");
        } catch (SQLException e) {
            getException(e);
        }
    }

    /* AC 2 */
    public void ajouterPrerequis() {
        System.out.println("Afin d'ajouter un prérequis à une UE, veuillez nous fournir les données suivantes : \n" +
                "* Le code de L'UE à laquelle vous désirez ajouter ce prérequis\n" +
                "* Le code du prérequis.\n");
        try {
            PreparedStatement ajouterPrerequis = conn.prepareStatement("SELECT * FROM projet.ajouterPrerequis(?, ?)");
            try {
                System.out.println("Code de l'UE :");
                String code_ue = scanner.next();
                System.out.println("Code du prérequis :");
                String code_prerequis = scanner.next();

                ajouterPrerequis.setString(1, code_ue);
                ajouterPrerequis.setString(2, code_prerequis);

                if (ajouterPrerequis.execute())
                    System.out.println("Prérequis ajouté");
                else
                    System.out.println("Prérequis non ajouté");
            } catch (SQLException e) {
                System.out.println("Prérequis non ajouté");
                getException(e);
            }
        } catch (SQLException e) {
            getException(e);
        }
    }

    /* AC 3 */
    public void ajouterEtudiant() {
        System.out.println("Vous avez choisis d'ajouter un étudiant,\n" +
                "pour ce faire nous avons besoin de son nom, prénom," +
                " email, mot de passe, ainsi que de savoir si son PAE est validé.");
        try {
            System.out.println("Nom :");
            String nomEtudiant = scanner.next();
            System.out.println();
            System.out.println("Prénom :");
            String prenomEtudiant = scanner.next();
            System.out.println();
            System.out.println("Email :");
            String emailEtudiant = scanner.next();
            System.out.println();
            System.out.println("Mot de passe :");
            String salt = BCrypt.gensalt(10);
            String mdpNonCrypte = scanner.next();
            String mdpCrypte = BCrypt.hashpw(mdpNonCrypte, salt);
            System.out.println();

            ajouterEtudiant.setString(1, nomEtudiant);
            ajouterEtudiant.setString(2, prenomEtudiant);
            ajouterEtudiant.setString(3, emailEtudiant);
            ajouterEtudiant.setString(4, mdpCrypte);

            if (ajouterEtudiant.execute())
                System.out.println("Étudiant ajouté");
            else
                System.out.println("Étudiant non ajouté");
        } catch (SQLException e) {
            getException(e);
        }
    }

    /* AC 4 */
    public void encoderUEValidee() {
        System.out.println("Vous avez choisis d'encoder une UE validée pour un étudiant,\n" +
                "pour ce faire nous avons besoin du code de l'ue, ainsi que de l'id de l'étudiant.");
        try {
            System.out.println("Code UE :");
            String code_ue = scanner.next();
            scanner.nextLine();
            System.out.println("ID Étudiant :");
            int id_etudiant = scanner.nextInt();

            encoderUEValideePourEtudiant.setString(1, code_ue.toUpperCase());
            encoderUEValideePourEtudiant.setInt(2, id_etudiant);

            if (encoderUEValideePourEtudiant.execute())
                System.out.println("UE validée encodée");
            else
                System.out.println("UE validée non encodée");
        } catch (SQLException e) {
            getException(e);
        }
    }

    /* AC 5 */
    public void visualiserTousLesEtudiantsDUnBloc() throws SQLException {
        System.out.println("Vous avez choisis de visualiser tous les étudiants d'un bloc,\n" +
                "pour ce faire nous avons besoin du code du bloc.");
        System.out.println("Bloc :");
        int bloc = scanner.nextInt();
        visualiserEtudiantsDUnBloc.setInt(1, bloc);
        try (ResultSet rs = visualiserEtudiantsDUnBloc.executeQuery()) {
            System.out.printf("\n%10s %20s %20s %30s\n",
                    "ID",
                    "Nom",
                    "Prénom",
                    "Nombre de crédits du PAE");
            System.out.printf("%10s %20s %20s %30s",
                    "==",
                    "===",
                    "======",
                    "========================");
            while (rs.next()) {
                System.out.printf("\n%10s %20s %20s %30s",
                        rs.getInt(1),
                        rs.getString(2),
                        rs.getString(3),
                        rs.getInt(4)
                );
            }
            System.out.println();
        } catch (SQLException e) {
            getException(e);
        }
    }

    /* AC 6 */
    public void VisualiserCreditsDeTousLesEtudiants() {
        System.out.println("Vous avez choisis de visualiser tous les crédits de tous les étudiants.");
        try (ResultSet rs = VisualiserCreditsDeTousLesEtudiants.executeQuery()) {
            System.out.printf("\n%20s %20s %10s %20s\n",
                    "Nom",
                    "Prénom",
                    "ID Bloc",
                    "Nombre Crédits");
            System.out.printf("%20s %20s %10s %20s",
                    "===",
                    "======",
                    "=======",
                    "==============");
            while (rs.next()) {
                System.out.printf("\n%20s %20s %10s %20s",
                        rs.getString(1),
                        rs.getString(2),
                        rs.getString(3),
                        rs.getString(4));
            }
            System.out.println();
        } catch (SQLException e) {
            getException(e);
        }
    }

    /* AC 7 */
    public void visualiserEtudiantsSansPAEValide() {
        System.out.println("Vous avez choisis de visualiser tous les étudiants sans PAE valide.");
        try (ResultSet rs = visualiserEtudiantsSansPAEValide.executeQuery()) {
            System.out.printf("\n%20s %20s %20s\n",
                    "Nom",
                    "Prénom",
                    "Crédits validés");
            System.out.printf("%20s %20s %20s",
                    "===",
                    "======",
                    "===============");
            while (rs.next())
                System.out.printf("\n%20s %20s %20s",
                        rs.getString(1),
                        rs.getString(2),
                        rs.getString(3));
            System.out.println();
        } catch (SQLException e) {
            getException(e);
        }
    }

    /* AC 8 */
    public void visualiserUESDUnBloc() throws SQLException {
        System.out.println("Vous avez choisis de visualiser toutes les UE d'un bloc, " +
                "pour ce faire nous aurons besoin de l'id du bloc.");
        System.out.println("Bloc :");
        int bloc = scanner.nextInt();
        visualiserUESDUnBloc.setInt(1, bloc);
        try (ResultSet rs = visualiserUESDUnBloc.executeQuery()) {
            System.out.printf("\n%20s %20s %20s\n",
                    "Code",
                    "Nom",
                    "Nb inscrits");
            System.out.printf("%20s %20s %20s",
                    "====",
                    "===",
                    "===========");
            while (rs.next())
                System.out.printf("\n%20s %20s %20s",
                        rs.getString(1),
                        rs.getString(2),
                        rs.getString(3));
            System.out.println();
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

    public static void main(String[] args) throws SQLException {
        boolean running = true;
        ApplicationCentrale app = new ApplicationCentrale();

        while (running) {
            System.out.println("\n***********\tApplication Centrale\t***********\n");
            System.out.println("""
                    1\t->\tAjouter UE
                    2\t->\tAjouter un prérequis à une UE
                    3\t->\tAjouter un étudiant
                    4\t->\tEncoder une UE validée pour un étudiant
                    5\t->\tVisualiser tous les étudiants d'un bloc
                    6\t->\tVisualiser le nombre de crédits de tous les étudiants
                    7\t->\tVisualiser tous les étudiants n'ayant pas validé leur PAE
                    8\t->\tVisualiser tous les UEs d'un bloc
                                        
                    0\t->\tArrêter l'application centrale
                    """);
            System.out.println("Entrez votrez choix :");

            int choix = scanner.nextInt();

            switch (choix) {
                case 1 -> app.ajouterUE();
                case 2 -> app.ajouterPrerequis();
                case 3 -> app.ajouterEtudiant();
                case 4 -> app.encoderUEValidee();
                case 5 -> app.visualiserTousLesEtudiantsDUnBloc();
                case 6 -> app.VisualiserCreditsDeTousLesEtudiants();
                case 7 -> app.visualiserEtudiantsSansPAEValide();
                case 8 -> app.visualiserUESDUnBloc();
                case 0 -> {
                    running = false;
                    System.out.println("Application centrale arrêtée");
                }
                default -> System.out.println("Veuillez choisir un chiffre entre 0 et 8 !\n");
            }
        }
        app.close();
    }
}