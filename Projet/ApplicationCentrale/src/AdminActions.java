import java.sql.*;
import java.util.Scanner;

public class AdminActions {

    public static Scanner scanner = new Scanner(System.in);
    private Connection connection = null;
    private PreparedStatement encoderCoursPreparedStatement, encoderEtudiantPreparedStatement,
            inscrireEtudiantPreparedStatement, creerProjetPreparedStatement, creerGroupesPreparedStatement,
            visualiserCoursPreparedStatement, visualiserProjetsPreparedStatement, visualiserCompoProjetPreparedStatement,
            validerGroupePreparedStatement, validerGroupesPreparedStatement;

    public AdminActions(Connection connection) {
        this.connection = connection;
    }

    public void encoderCours() {
        try {
            encoderCoursPreparedStatement = connection.prepareStatement("SELECT * FROM projet.encoder_cours(?, ?, ?, ?)");
            try {

                System.out.print("\nNom du cours : ");
                String nom = scanner.nextLine();

                System.out.print("\nCode du cours : ");
                String code = scanner.nextLine();

                System.out.print("\nNombre de ects : ");
                String nbCredits = scanner.nextLine();

                System.out.print("\nBloc : ");
                String bloc = scanner.nextLine();

                encoderCoursPreparedStatement.setString(1, code.toUpperCase());
                encoderCoursPreparedStatement.setString(2, nom);
                encoderCoursPreparedStatement.setInt(3, Integer.parseInt(bloc));
                encoderCoursPreparedStatement.setInt(4, Integer.parseInt(nbCredits));

                System.out.println();
                System.out.println(encoderCoursPreparedStatement.execute() ? "Cours ajouté !\n" : "L'ajout de cours a échoué !\n");

            } catch (SQLException e) {
                System.out.println("L'ajout de cours a échoué !");
                ApplicationCentrale.getException(e);
            }
        } catch (SQLException e) {
            System.out.println("L'ajout de cours a échoué ! -> prepareStatement KO !");
            ApplicationCentrale.getException(e);
        }
    }

    public void encoderEtudiant() {
        try {
            encoderEtudiantPreparedStatement = connection.prepareStatement("SELECT * FROM projet.encoder_etudiant(?, ?, ?, ?)");
            try {
                System.out.print("\nPrénom de l'étudiant : ");
                String prenom = scanner.nextLine();

                System.out.print("\nNom de l'étudiant : ");
                String nom = scanner.nextLine();

                System.out.print("\nEmail : ");
                String email = scanner.nextLine();

                System.out.print("\nMot de passe : ");
                String salt = BCrypt.gensalt(10);
                String motDePasseNonCrypte = scanner.nextLine();
                String motDePasseCrypte = BCrypt.hashpw(motDePasseNonCrypte, salt);
                System.out.println();

                encoderEtudiantPreparedStatement.setString(1, nom);
                encoderEtudiantPreparedStatement.setString(2, prenom);
                encoderEtudiantPreparedStatement.setString(3, email);
                encoderEtudiantPreparedStatement.setString(4, motDePasseCrypte);

                System.out.println();
                System.out.println(encoderEtudiantPreparedStatement.execute() ? "Etudiant ajouté !\n" : "L'ajout de l'étudiant a échoué !\n");

            } catch (SQLException e) {
                System.out.println("L'ajout de l'étudiant a échoué !");
                ApplicationCentrale.getException(e);
            }
        } catch (SQLException e) {
            System.out.println("L'ajout de l'étudiant a échoué ! -> prepareStatement KO !");
            ApplicationCentrale.getException(e);
        }
    }

    public void inscrireEtudiant() {
        try {
            inscrireEtudiantPreparedStatement = connection.prepareCall("CALL projet.inscrire_etudiant(?, ?)");
            try {
                System.out.print("\nEmail de l'étudiant : ");
                String emailEtudiant = scanner.nextLine();

                System.out.print("\nCode du cours : ");
                String code = scanner.nextLine();

                inscrireEtudiantPreparedStatement.setString(1, emailEtudiant);
                inscrireEtudiantPreparedStatement.setString(2, code.toUpperCase());

                //inscrireEtudiantPreparedStatement.executeQuery();
                System.out.printf("%-10s %-20s", "Output",
                        (inscrireEtudiantPreparedStatement.executeUpdate() == 0)
                                ? "Etudiant inscrit"
                                : "Echec de l'inscription");
            } catch (SQLException e) {
                System.out.println("Impossible d'inscrire l'étudiant : " + e);
                ApplicationCentrale.getException(e);
            }
        } catch (SQLException e) {
            System.out.println("Impossible d'inscrire l'étudiant -> prepareStatement KO !");
            ApplicationCentrale.getException(e);
        }
    }

    public void creerProjet() {
        try {
            creerProjetPreparedStatement = connection.prepareCall("SELECT * FROM projet.creer_projet(?, ?, ?, ?, ?)");
            try {

                System.out.println("\nCode du cours : ");
                String nomCours = scanner.nextLine();

                System.out.println("\nNom du projet : ");
                String nomProjet = scanner.nextLine();

                System.out.println("\nIdentifiant du projet :");
                String identifiant = scanner.nextLine();

                System.out.println("\nDate début (YYYY-MM-DD) : ");
                String dateDebut = scanner.nextLine();

                System.out.println("\nDate fin (YYYY-MM-DD) : ");
                String dateFin = scanner.nextLine();

                creerProjetPreparedStatement.setString(1, identifiant);
                creerProjetPreparedStatement.setString(2, nomCours);
                creerProjetPreparedStatement.setString(3, nomProjet);
                creerProjetPreparedStatement.setTimestamp(4, Timestamp.valueOf(dateDebut + " 00:00:00"));
                creerProjetPreparedStatement.setTimestamp(5, Timestamp.valueOf(dateFin + " 00:00:00"));

                System.out.printf("%-10s %-20s", "Output", (creerProjetPreparedStatement.execute())
                        ? "Projet créé"
                        : "Echec de la création du projet");

            } catch (SQLException e) {
                System.out.println("Impossible de créer le projet : " + e);
                ApplicationCentrale.getException(e);
            }
        } catch (SQLException e) {
            System.out.println("Impossible de créer le groupe -> prepareStatement KO !");
            ApplicationCentrale.getException(e);
        }
    }

    public void creerGroupes() {
        try {
            creerGroupesPreparedStatement = connection.prepareStatement("CALL projet.creer_groupes(?, ?, ?)");
            try {
                System.out.println("\nIdentifiant : ");
                String identifiant = scanner.nextLine();

                System.out.println("\nNombre de groupes : ");
                String nbGroupes = scanner.nextLine();

                System.out.println("\nNombre de places : ");
                String nbPlaces = scanner.nextLine();

                creerGroupesPreparedStatement.setString(1, identifiant);
                creerGroupesPreparedStatement.setInt(2, Integer.parseInt(nbGroupes));
                creerGroupesPreparedStatement.setInt(3, Integer.parseInt(nbPlaces));

                System.out.printf("%-10s %-20s", "Output", (creerGroupesPreparedStatement.executeUpdate() == 0)
                        ? "Groupe créé"
                        : "Echec de la création du groupe");

            } catch (SQLException e) {
                System.out.println("Impossible de créer le groupe : " + e);
                ApplicationCentrale.getException(e);
            }
        } catch (SQLException e) {
            System.out.println("Impossible de créer le groupe -> prepareStatement KO !");
            ApplicationCentrale.getException(e);
        }
    }

    public void visualiserCours() {
        try {
            visualiserCoursPreparedStatement = connection.prepareStatement("SELECT * FROM projet.visualiser_cours");
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
                ApplicationCentrale.getException(e);
            }
        } catch (SQLException e) {
            System.out.println("Impossible de visualiser les cours -> prepareStatement KO !");
            ApplicationCentrale.getException(e);
        }
    }

    public void visualiserProjets() {
        try {
            visualiserProjetsPreparedStatement = connection.prepareStatement("SELECT * FROM projet.visualiser_projets");
            try (ResultSet rs = visualiserProjetsPreparedStatement.executeQuery()) {
                System.out.printf("%-10s     | %-20s | %-20s | %-20s | %-10s | %-10s | %-10s | \n", "",
                        "Identifiant", "Nom", "Code", "nb Groupes", "nb Complets", "nb Valides");
                while (rs.next()) {
                    System.out.printf("%-10s ->   %-20s | %-20s | %-20s | %-10s | %-10s | %-10s | \n",
                            "Projet",
                            rs.getString(2),
                            rs.getString(3),
                            rs.getString(4),
                            rs.getInt(5),
                            rs.getInt(6),
                            rs.getInt(7));
                }
                System.out.println();

            } catch (SQLException e) {
                System.out.println("Impossible de visualiser les projets ..." +e);
                ApplicationCentrale.getException(e);
            }
        } catch (SQLException e) {
            System.out.println("Impossible de visualiser les projets -> prepareStatement KO !");
            ApplicationCentrale.getException(e);
        }
    }

    public void visualiserCompoProjet() {
        /*String sql = "select * from projet.visualiser_compo_projet where \"Identifiant\" = (?)";

        System.out.println("\nIdentifiant : ");
        String identifiant = scanner.nextLine();

        sql = sql.replace("(?)", identifiant);
*/
        try {
            visualiserCompoProjetPreparedStatement = connection.prepareStatement("select * from projet.visualiser_compo_projet where \"Identifiant\" = (?)");

            System.out.println("\nIdentifiant : ");
            String identifiant = scanner.nextLine();

            visualiserCompoProjetPreparedStatement.setString(1, identifiant);

            try (ResultSet rs = visualiserCompoProjetPreparedStatement.executeQuery()) {
                System.out.printf("%-10s     | %-10s | %-20s | %-20s | %-10s | %-10s | \n",
                        "", "Numéro", "Nom", "Prénom", "Complet?", "Validé?");
                while (rs.next()) {
                    System.out.printf("%-10s ->  | %-10s | %-20s | %-20s | %-10s | %-10s | \n",
                            "Projet",
                            rs.getInt(1),
                            rs.getString(2),
                            rs.getString(3),
                            rs.getBoolean(4),
                            rs.getBoolean(5));
                }
                System.out.println();
            } catch (SQLException e) {
                System.out.println("Impossible de visualiser les projets ...");
                ApplicationCentrale.getException(e);
            }
        } catch (SQLException e) {
            System.out.println("Impossible de visualiser les projets -> prepareStatement KO !");
            ApplicationCentrale.getException(e);
        }
    }

    public void validerGroupe() {
        try {
            validerGroupePreparedStatement = connection.prepareStatement("CALL projet.valider_groupe(?, ?)");
            try {

                System.out.println("\nIdentifiant cours : ");
                String idProjet = scanner.nextLine();

                System.out.println("\nNuméro de groupe : ");
                String nbGroupe = scanner.nextLine();

                validerGroupePreparedStatement.setString(1, idProjet);
                validerGroupePreparedStatement.setInt(2, Integer.parseInt(nbGroupe));

                System.out.printf("%-10s %-20s", "Output", (validerGroupePreparedStatement.execute())
                        ? "Groupe validé"
                        : "Echec de la validation du groupe");

            } catch (SQLException e) {
                System.out.println("Impossible de valider le groupe : " + e);
                ApplicationCentrale.getException(e);
            }
        } catch (SQLException e) {
            System.out.println("Impossible de valider le groupe -> prepareStatement KO !");
            ApplicationCentrale.getException(e);
        }
    }

    public void validerGroupes() {
        try {
            validerGroupesPreparedStatement = connection.prepareStatement("CALL projet.valider_groupes(?)");
            try {

                System.out.println("\nIdentifiant cours : ");
                String idProjet = scanner.nextLine();

                validerGroupesPreparedStatement.setString(1, idProjet);

                System.out.printf("%-10s %-20s", "Output", (validerGroupesPreparedStatement.execute())
                        ? "Groupe validé"
                        : "Echec de la validation du groupe");

            } catch (SQLException e) {
                System.out.println("Impossible de valider le groupe : " + e);
                ApplicationCentrale.getException(e);
            }
        } catch (SQLException e) {
            System.out.println("Impossible de valider le groupe -> prepareStatement KO !");
            ApplicationCentrale.getException(e);
        }
    }
}
