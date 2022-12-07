import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Scanner;

public class ApplicationUtilisateur {
	public static Scanner scanner = new Scanner(System.in);
	// Le serveur �coute sur le port 5433
	private String url = "jdbc:postgresql://localhost:5433/postgres";
	private Connection conn = null;
	public int ID_USER = 0;
	private PreparedStatement sAuthentifier;
	private PreparedStatement visualiserLesExamens;
	private PreparedStatement sInscrireATousLesExamensDeMonBloc;
	private PreparedStatement sInscrireAUnExamen;
	private PreparedStatement voirMonHoraire;

	public ApplicationUtilisateur() {
		try {
			Class.forName("org.postgresql.Driver");
		} catch (ClassNotFoundException e) {
			System.out.println("Driver PostgreSQL manquant !");
			System.exit(1);
		}
		try {
			/**
			 * Username e.g : postgres, Password e.g : SQL123
			 */
			conn = DriverManager.getConnection(url, "postgres", "SQL123");
		} catch (SQLException e) {
			System.out.println("Impossible de joindre le server !");
			getException(e);
			System.exit(1);
		}
		/*
		 * try { // ici les requetes } catch (SQLException e) {
		 * System.out.println("Erreur avec les requ�tes SQL !"); System.exit(1); }
		 */
	}

	public void sAuthentifier() {
		try {
			sAuthentifier = conn
					.prepareStatement("SELECT * FROM projet.connexionUtilisateur u WHERE u.nom_utilisateur = ?");

			System.out.print("Veuillez entrez votre nom : ");
			String nom = scanner.nextLine();
			System.out.print("Veuillez entrez votre mot de passe : ");
			String password = scanner.nextLine();

			sAuthentifier.setString(1, nom);

			try (ResultSet rs = sAuthentifier.executeQuery()) {
				if (rs.next()) {
					if (nom.equals(rs.getString(2))) {
						if (BCrypt.checkpw(password, rs.getString(3))) {
							System.out.printf("%-10s %-20s\n\n", "Authentification ", rs.getString(2));
							System.out.printf("%-10s %-20s\n\n", "Authentification ",
									rs.getString(2) + " est connect�e! ");
							ID_USER = rs.getInt(1);
						} else {
							System.out.printf("%-10s %-20s\n\n", "Authentification ->",
									"Nom ou Mot de passe incorrecte !");
						}
					} else {
						System.out.printf("%-10s %-20s\n\n", "Authentification ->", "Nom ou Mot de passe incorrecte !");
					}
				} else {
					System.out.printf("%-10s %-20s\n\n", "Authentification ->", "Nom ou Mot de passe incorrecte !");
				}
			} catch (SQLException e) {
				System.out.printf("%-10s %-20s\n\n", "Execution Query ->", "KO");
				getException(e);
			}
		} catch (SQLException e) {
			System.out.printf("%-10s %-20s\n\n", "PrepareStatement ->", "KO");
			getException(e);
		}
	}

	public void visualiserLesExamens() {
		try {
			visualiserLesExamens = conn.prepareStatement("SELECT * FROM projet.visualiserLesExamens ex");
			try (ResultSet rs = visualiserLesExamens.executeQuery()) {
				System.out.printf("\n%-18s      %-20s | %-20s | %-20s | %-20s\n", "", "Code examen", "Nom examen",
						"Bloc", "Durée examen");
				while (rs.next()) {
					System.out.printf("%-10s ->		%-20s | %-20s | %-20s | %-20s\n", "Output", rs.getString(1),
							rs.getString(2), rs.getString(3), rs.getString(4));
				}
			} catch (Exception e) {
				System.out.printf("%-10s %-20s\n\n", "Output", "resultSet KO !\\n");
				getException(e);
			}
		} catch (SQLException e) {
			System.out.printf("%-10s %-20s\n\n", "Output", "prepareStatement KO !\\n");
			getException(e);
		}

	}

	public void sInscrireAUnExamen() {
		try {
			sInscrireAUnExamen = conn.prepareStatement("SELECT * FROM projet.sInscrireAUnExamen(?, ?)");
			try {
				System.out.println();
				System.out.printf("\n%-10s %-20s", "Input", "Code de l'examen :");
				String codeExamen = scanner.nextLine();

				System.out.println();

				sInscrireAUnExamen.setInt(1, ID_USER);
				sInscrireAUnExamen.setString(2, codeExamen);

				try {
					System.out.printf("\n%-10s %-20s", "Output",
							sInscrireAUnExamen.execute() == true ? "Inscription à un examen OK !\n"
									: "Inscription à un examen KO !\n");
				} catch (Exception e) {
					getException(e);
				}
			} catch (Exception e) {
				System.out.printf("%-10s %-20s\n\n", "Output", "resultSet KO !\\n");
				getException(e);
			}
		} catch (SQLException e) {
			System.out.printf("%-10s %-20s\n\n", "Output", "prepareStatement KO !\\n");
			getException(e);
		}
	}

	// S’inscrire à tous les examens du bloc de l’étudiant. Si une des inscriptions
	// échoue, alors aucune inscription ne sera enregistrée.
	public void sInscrireATousLesExamensDeMonBloc() {
		try {
			sInscrireATousLesExamensDeMonBloc = conn
					.prepareStatement("SELECT * FROM projet.sInscrireATousLesExamens(?)");
			sInscrireATousLesExamensDeMonBloc.setInt(1, ID_USER);
			System.out.printf("%-10s %-20s", "Output",
					sInscrireATousLesExamensDeMonBloc.execute() == true ? "Inscriptions Ok\n" : "Inscriptions KO\n");
		} catch (SQLException e) {
			getException(e);
		}
	}

	/**
	 * Voir son horaire d’examen. Les examens devront être triés par ordre
	 * chronologique. Pour chaque examen, on affiche son code, son nom, son bloc,
	 * son heure de début, son heure de fin, et ses locaux séparés par des + (ex :
	 * A025+A026). Si un examen n’a pas d’heure de début ou n’a pas encore de locaux
	 * réservés, il doit quand même apparaître dans la liste
	 */
	public void voirMonHoraire() {
		try {
			voirMonHoraire = conn.prepareStatement(
					"SELECT * FROM projet.voirSonHoraireDExamen(?) t(code CHARACTER(6) ,nom_examen VARCHAR, bloc INTEGER, heure_debut TIMESTAMP, heure_fin TIMESTAMP, locaux VARCHAR)");
			voirMonHoraire.setInt(1, ID_USER);
			try (ResultSet rs = voirMonHoraire.executeQuery()) {
				System.out.printf("\n%-18s      %-20s | %-20s | %-20s | %-20s | %-20s | %-20s\n", "", "Code examen",
						"Nom examen", "Bloc", "Heure début", "Heure fin", "Locaux");
				while (rs.next()) {
					System.out.printf("%-10s ->		%-20s | %-20s | %-20s | %-20s | %-20s | %-20s\n", "Output",
							rs.getString(1), rs.getString(2), rs.getString(3), rs.getTimestamp(4) == null ? "Pas encore réservé" : rs.getTimestamp(4), rs.getTimestamp(5) == null ? "Pas encore réservé" : rs.getTimestamp(5),
							rs.getString(6).isEmpty() ? "Aucun" : rs.getString(6));
				}
			} catch (Exception e) {
				System.out.printf("%-10s %-20s\n\n", "Output", "resultSet KO !\n");
				getException(e);
			}
		} catch (SQLException e) {
			System.out.printf("%-10s %-20s\n\n", "Output", "prepareStatement KO !\n");
			getException(e);
		}
	}

	public void close() {
		try {
			conn.close();
		} catch (SQLException e) {
			getException(e);
		}
	}

	private void getException(Exception e) {
		String string = "Exception levée : " + e.getMessage().split(":")[1].split("Où")[0] + "\n";
		System.out.println(string);
	}

	public static void main(String[] args) {
		ApplicationUtilisateur app = new ApplicationUtilisateur();
		System.out.printf("%10s %20s %10s\n", "***********", "Application Utilisateur", "***********");
		boolean running = true;
		String FORMAT_MENU = "%-10s %-40s\n";
		String FORMAT_INPUT = "%-10s %-20s";
		String FORMAT_OUTPUT_MESSAGE = "%-10s %-20s\n\n";
		System.out.printf(FORMAT_OUTPUT_MESSAGE, "\nAuthentification...", "");
		app.sAuthentifier();
		System.out.println();
		String choix;

		while (running) {
			System.out.println();
			if (app.ID_USER > 0) {
				System.out.println();

				System.out.printf(FORMAT_MENU, "1  ->", "Visualiser les examens");
				System.out.printf(FORMAT_MENU, "2  ->", "S'inscrire à un examen");
				System.out.printf(FORMAT_MENU, "3  ->", "S'incrire à tous les examens de mon bloc");
				System.out.printf(FORMAT_MENU, "4  ->", "Voir mon horaire");
				System.out.printf(FORMAT_MENU, "5  ->", "Se déconnecté");
				System.out.println();
				System.out.printf(FORMAT_INPUT, "Input ", "Entrez votre choix : ");

				choix = scanner.nextLine();

				switch (choix) {
				case "1": {
					app.visualiserLesExamens();
					break;
				}
				case "2": {
					app.sInscrireAUnExamen();
					break;
				}
				case "3": {
					app.sInscrireATousLesExamensDeMonBloc();
					break;
				}
				case "4": {
					app.voirMonHoraire();
					break;
				}
				case "5": {
					running = false;
					System.out.printf(FORMAT_OUTPUT_MESSAGE, "Output", "Application centrale arr�t�e !");
					break;
				}

				default:
					System.out.printf(FORMAT_OUTPUT_MESSAGE, "Output", "Veuillez choisir un chiffre entre 1 et 10!");

					break;
				}
			} else {
				app.sAuthentifier();
			}
		}
		app.close();
	}
}
