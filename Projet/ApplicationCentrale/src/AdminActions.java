import java.sql.*;
import java.util.Scanner;

public class AdminActions {

    public static Scanner scanner = new Scanner(System.in);
    private Connection connection = null;
    private PreparedStatement addCoursePreparedStatement;
    private PreparedStatement addStudentPreparedStatement;

    private CallableStatement enrollStudentInCoursePreparedStatement;

    private PreparedStatement seeCoursesPreparedStatement;

    public AdminActions(Connection connection){
        this.connection = connection;
    }

    public void addCourse() {
        try {
            addCoursePreparedStatement = connection.prepareStatement("SELECT * FROM projet.encoder_cours(?, ?, ?, ?)");
            try {
                System.out.print("\nCode du cours : ");
                String code = scanner.nextLine();

                System.out.print("Nom du cours : ");
                String name = scanner.nextLine();

                System.out.print("Bloc : ");
                String bloc = scanner.nextLine();

                System.out.print("Nombre de crédits : ");
                String creditsNb = scanner.nextLine();

                addCoursePreparedStatement.setString(1, code.toUpperCase());
                addCoursePreparedStatement.setString(2, name);
                addCoursePreparedStatement.setInt(3, Integer.parseInt(bloc));
                addCoursePreparedStatement.setInt(4, Integer.parseInt(creditsNb));

                System.out.println();
                System.out.println(addCoursePreparedStatement.execute() ? "Cours ajouté !\n" : "L'ajout de cours a échoué !\n");

            } catch (SQLException e) {
                System.out.println("L'ajout de cours a échoué !");
                ApplicationCentrale.getException(e);
            }
        } catch (SQLException e) {
            System.out.println("L'ajout de cours a échoué ! -> prepareStatement KO !");
            ApplicationCentrale.getException(e);
        }
    }

    public void addStudent() {
        try {
            addCoursePreparedStatement = connection.prepareStatement("SELECT * FROM projet.encoder_etudiant(?, ?, ?, ?)");
            try {
                System.out.print("\nNom de l'étudiant : ");
                String lastname = scanner.nextLine();

                System.out.print("Prénom de l'étudiant : ");
                String firstname = scanner.nextLine();

                System.out.print("Email : ");
                String email = scanner.nextLine();

                System.out.print("Mot de passe : ");
                String password = scanner.nextLine();

                addCoursePreparedStatement.setString(1, lastname);
                addCoursePreparedStatement.setString(2, firstname);
                addCoursePreparedStatement.setString(3, email);
                addCoursePreparedStatement.setString(4, password);

                System.out.println();
                System.out.println(addCoursePreparedStatement.execute() ? "Etudiant ajouté !\n" : "L'ajout de l'étudiant a échoué !\n");

            } catch (SQLException e) {
                System.out.println("L'ajout de l'étudiant a échoué !");
                ApplicationCentrale.getException(e);
            }
        } catch (SQLException e) {
            System.out.println("L'ajout de l'étudiant a échoué ! -> prepareStatement KO !");
            ApplicationCentrale.getException(e);
        }
    }

    public void enrollStudentInCourse() {
        try {
            enrollStudentInCoursePreparedStatement = connection.prepareCall("CALL projet.inscrire_etudiant(?, ?)");
            try {
                System.out.print("\nID de l'étudiant : ");
                String studentID = scanner.nextLine();

                System.out.print("Code du cours : ");
                String code = scanner.nextLine();

                enrollStudentInCoursePreparedStatement.setInt(1, Integer.parseInt(studentID));
                enrollStudentInCoursePreparedStatement.setString(2, code.toUpperCase());
                System.out.printf("%-10s %-20s", "Output",
                        (enrollStudentInCoursePreparedStatement.execute()) ? "Etudiant inscrit"
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

    public void createCourseProject() {
        //TODO
    }

    public void createProjectGroups() {
        //TODO
    }

    public void seeCourses() {
        try {
            seeCoursesPreparedStatement = connection.prepareStatement("SELECT * FROM projet.visualiser_cours");
            try (ResultSet rs = seeCoursesPreparedStatement.executeQuery()) {
                System.out.printf("%-10s     | %-10s | %-20s | %-30s| \n", "", "Code", "Nom",
                        "Projet");
                while (rs.next()) {
                    System.out.printf("%-10s ->  | %-10s | %-20s | %-30s|\n", "Cours", rs.getString(1), rs.getString(2),
                            rs.getString(3));
                }
            } catch (SQLException e) {
                System.out.println("Impossible de visualiser les cours ...");
                ApplicationCentrale.getException(e);
            }
        } catch (SQLException e) {
            System.out.println("Impossible de visualiser les cours -> prepareStatement KO !");
            ApplicationCentrale.getException(e);
        }
    }

    public void seeAllProjects() {
        //TODO
    }

    public void seeProjectGroupsCompositions() {
        //TODO
    }

    public void validateGroup() {
        //TODO
    }

    public void validateAllProjectGroups() {
        //TODO
    }
}
