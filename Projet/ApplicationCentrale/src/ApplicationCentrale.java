import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.Scanner;

public class ApplicationCentrale {
	public static Scanner scanner = new Scanner(System.in);

	private String url = "jdbc:postgresql://localhost:5433/postgres";
	private Connection conn = null;
	private PreparedStatement ajouterUnLocal;
	private PreparedStatement ajouterUnExamen;
	private PreparedStatement examen;
	private PreparedStatement encoderHeureDebutExamen;
	private PreparedStatement reserverUnLocalPourExamen;
	private PreparedStatement visualiserToutLesExamensNonReserves;
	private PreparedStatement visualiserNombreExamenPasEncoreReserveePourChaqueBloc;
	private PreparedStatement visualiserHoraireExamenPourUnBloc;

	public ApplicationCentrale() {
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
			System.exit(1);
		}
	}

	public void ajouterUnLocal() {
		try {
			ajouterUnLocal = conn.prepareStatement("SELECT * FROM projet.ajouterLocal(?, ?, ?)");

			try {
				System.out.println();
				System.out.printf("\n%-10s %-20s", "Input", "Nombre de place :");
				String nbrPlaces = scanner.nextLine();

				System.out.println();
				System.out.printf("\n%-10s %-20s", "Input", "Nom du local :");
				String nomLocal = scanner.nextLine();

				System.out.println();
				System.out.printf("\n%-10s %-20s", "Input", "Avec machine ? (Oui -> o/O) :");
				String avecMachine = scanner.nextLine();

				System.out.println();

				ajouterUnLocal.setInt(1, Integer.parseInt(nbrPlaces));
				ajouterUnLocal.setString(2, nomLocal.toUpperCase());
				ajouterUnLocal.setBoolean(3, ((avecMachine == "o" || avecMachine == "O") ? true : false));

				System.out.printf("\n%-10s %-20s", "Output",
						ajouterUnLocal.execute() == true ? "Ajouter Local OK !\n" : "Ajouter Local KO !\n");
				System.out.println();
			} catch (SQLException e) {
				System.out.printf("\n%-10s %-20s", "Output", "Ajouter Local KO !\n");
				getException(e);
			}
		} catch (SQLException e) {
			System.out.printf("\n%-10s %-20s", "Output", "prepareStatement KO !\n");
			getException(e);
		}

	}

	public void ajouterUnExamen() {
		try {
			ajouterUnExamen = conn.prepareStatement("SELECT * FROM projet.ajouterExamen(?, ?, ?, ?, ?)");
			try {
				System.out.println();
				System.out.printf("\n%-10s %-20s", "Input", "Nom de l'examen :");
				String nomExamen = scanner.nextLine();

				System.out.println();
				System.out.printf("\n%-10s %-20s", "Input", "Code de l'examen :");
				String codeExamen = scanner.nextLine();

				System.out.println();
				System.out.printf("\n%-10s %-20s", "Input", "Bloc de l'examen :");
				String blocExamen = scanner.nextLine();

				System.out.println();
				System.out.printf("\n%-10s %-20s", "Input", "Dur�e de l'examen:");
				String dureeExamen = scanner.nextLine();

				System.out.println();
				System.out.printf("\n%-10s %-20s", "Input", "Examen sur machine ?  (Oui -> o/O) :");
				String surMachine = scanner.nextLine();

				System.out.println();

				ajouterUnExamen.setString(1, codeExamen.toUpperCase());
				ajouterUnExamen.setString(2, nomExamen.toUpperCase());
				ajouterUnExamen.setInt(3, Integer.parseInt(blocExamen));
				ajouterUnExamen.setInt(4, Integer.parseInt(dureeExamen));
				ajouterUnExamen.setBoolean(5, ((surMachine == "o" || surMachine == "O") ? true : false));
				try (ResultSet retCodeExamen = ajouterUnExamen.executeQuery()) {
					if (retCodeExamen.next())
						System.out.printf("%-10s %-20s\n", "Output",
								retCodeExamen.getString(1).equals(codeExamen)
										? "Ajouter examen OK ! ->  Code examen :" + codeExamen + "\n"
										: "Ajouter examen KO ! \n");
				}

			} catch (SQLException e) {
				System.out.printf("%-10s %-20s", "Output", "Ajouter Examen KO !\n");
				getException(e);
			}

		} catch (SQLException e) {
			System.out.printf("%-10s %-20s", "Output", "prepareStatement KO !\n");
			getException(e);
		}
	}

	public void encoderHeureDebutExamen() {
		String codeExamen = "";
		try {
			examen = conn.prepareStatement("SELECT ex.code_examen FROM projet.examen ex WHERE ex.nom_examen = ?");
			System.out.println();
			System.out.printf("\n%-10s %-20s", "Input", "Entrez le nom de l'examen :");
			String nomExamen = scanner.nextLine();
			examen.setString(1, nomExamen.toUpperCase());
			try (ResultSet rs = examen.executeQuery()) {
				if (rs.next()) {
					codeExamen = rs.getString(1);
				}
			} catch (SQLException e) {
				System.out.printf("\n%-10s %-20s", "Output", "ResultSet KO !\n");
				getException(e);
			}
		} catch (SQLException e) {
			System.out.printf("\n%-10s %-20s", "Output", "prepareStatement KO !\n");
			getException(e);
		}

		try {
			encoderHeureDebutExamen = conn.prepareStatement("SELECT * FROM projet.encoderHeureDebutExamen(?, ?)");
			try {
				System.out.println();
				System.out.printf("\n%-10s %-20s", "Input", "Entrez la date (yyyy-mm-jj) :");
				String date = scanner.nextLine();

				System.out.println();
				System.out.printf("\n%-10s %-20s", "Input", "Entrez l'heure (hh) :");
				String heure = scanner.nextLine();

				System.out.println();

				encoderHeureDebutExamen.setString(1, codeExamen.toUpperCase());
				encoderHeureDebutExamen.setTimestamp(2, Timestamp.valueOf(date + " " + heure + ":00:00"));

				System.out.printf("%-10s %-20s", "Output",
						(encoderHeureDebutExamen.execute() == true) ? "Encoder heure examen OK !\n"
								: "Encoder heure examen KO\n");

			} catch (SQLException e) {
				System.out.printf("%-10s %-20s", "Output", "Ajouter Examen KO !\n");
				getException(e);
			}

		} catch (SQLException e) {
			System.out.printf("%-10s %-20s", "Output", "prepareStatement KO !\n");
			getException(e);
		}
	}

	public void reserverUnLocalPourUnExamen() {
		String codeExamen = "";
		try {
			examen = conn.prepareStatement("SELECT ex.code_examen FROM projet.examens ex WHERE ex.nom_examen = ?");
			System.out.println();
			System.out.printf("\n%-10s %-20s", "Input", "Entrez le nom de l'examen :");
			String nomExamen = scanner.nextLine();
			examen.setString(1, nomExamen.toUpperCase());
			try (ResultSet rs = examen.executeQuery()) {
				if (rs.next()) {
					codeExamen = rs.getString(1);
				}
			}
		} catch (SQLException e) {
			System.out.printf("%-10s %-20s", "Output", "prepareStatement KO !\n");
			getException(e);
		}

		try {
			reserverUnLocalPourExamen = conn.prepareStatement("SELECT * FROM projet.reserverUnLocalPourExamen(?, ?)");

			System.out.println();
			System.out.printf("\n%-10s %-20s", "Input", "Local à reservée :");
			String localAReservee = scanner.nextLine();
			reserverUnLocalPourExamen.setString(1, codeExamen.toUpperCase());
			reserverUnLocalPourExamen.setString(2, localAReservee.toUpperCase());
			System.out.printf("%-10s %-20s\n", "Output",
					reserverUnLocalPourExamen.execute() == true ? "Reserver un local OK !\n"
							: "Reserver un local KO !\n");
		} catch (SQLException e) {
			System.out.printf("\n%-10s %-20s", "Output", "prepareStatement KO !\n");
			getException(e);
		}
	}

	public void visualiserToutLesExamensNonReserves() {
		try {
			visualiserToutLesExamensNonReserves = conn.prepareStatement(
					"SELECT DISTINCT * FROM projet.visualiserExamenPasCompletementReservee() t(date_examen TIMESTAMP, code_examen CHARACTER(6), nom_examen VARCHAR)");
			try (ResultSet rs = visualiserToutLesExamensNonReserves.executeQuery()) {
				System.out.printf("\n%-10s      %-30s | %-20s | %-20s\n", "", "Date", "Code examen", "Nom examen");
				while (rs.next()) {
					System.out.printf("%-10s ->   %-30s | %-20s | %-20s\n", "Output",
							(rs.getTimestamp(1) == null) ? "Pas fixé" : rs.getTimestamp(1), rs.getString(2),
							rs.getString(3));
				}
				System.out.println();
			}
		} catch (SQLException e) {
			System.out.printf("%-10s %-20s", "Output", "prepareStatement KO !\n");
			getException(e);
		}
	}

	public void visualiserNombreExamenPasEncoreReserveePourChaqueBloc() {
		try {
			visualiserNombreExamenPasEncoreReserveePourChaqueBloc = conn
					.prepareStatement("SELECT * FROM projet.visualiserNombreExamenPasCompletementReserveeParBloc");

			try (ResultSet rs = visualiserNombreExamenPasEncoreReserveePourChaqueBloc.executeQuery()) {
				System.out.printf("%-10s      %-20s | %-20s | %-20s| \n", "", "Id bloc", "Code Bloc",
						"Nombre d'examen");
				while (rs.next()) {
					System.out.printf("%-10s ->   %-20s | %-20s | %-20s|\n", "Output", rs.getInt(1), rs.getString(2),
							rs.getInt(3));
				}
				System.out.println();
			} catch (SQLException e) {
				System.out.printf("%-10s %-20s\n", "Output", "resultSet KO !\n");
				getException(e);
			}
		} catch (SQLException e) {
			System.out.printf("%-10s %-20s\n", "Output", "prepareStatement KO !\n");
			getException(e);
		}
	}

	public void visualiserHoraireExamenPourUnBloc() {
		try {
			visualiserHoraireExamenPourUnBloc = conn
					.prepareStatement("SELECT * FROM projet.afficherHoraireExamen WHERE \"id bloc\" = ?");
			System.out.println();
			System.out.printf("%-10s %-20s", "Input", "Entrez l'id du bloc :");
			String idBloc = scanner.nextLine();
			visualiserHoraireExamenPourUnBloc.setInt(1, Integer.parseInt(idBloc));
			try (ResultSet rs = visualiserHoraireExamenPourUnBloc.executeQuery()) {
				System.out.printf("%-10s      %-30s | %-20s | %-20s | %-25s |\n", "", "Heure début examen",
						"Code examen", "Nom examen", "Nombre Locaux Reservée");
				while (rs.next()) {
					System.out.printf("%-10s ->   %-30s | %-20s | %-20s | %-25s |\n", "Output",
							rs.getTimestamp(1) == null ? "Pas fixé" : rs.getTimestamp(1), rs.getString(2),
							rs.getString(3), rs.getInt(4));
				}
				System.out.println();
			} catch (SQLException e) {
				System.out.printf("%-10s %-20s", "Output", "resultSet KO !\n");
				getException(e);
			}
		} catch (SQLException e) {
			System.out.printf("%-10s %-20s", "Output", "prepareStatement KO !\n");
			getException(e);
		}
	}

	public void visualiserReservationExamenDUnLocal() {

		try {
			visualiserHoraireExamenPourUnBloc = conn.prepareStatement(
					"		SELECT * FROM projet.visualiserReservationExamenPourUnLocal WHERE nom_local = ?");
			System.out.println();
			System.out.printf("\n%-10s %-20s", "Input", "Entrez le nom du local :");
			String nomLocal = scanner.nextLine();
			visualiserHoraireExamenPourUnBloc.setString(1, nomLocal.toUpperCase());
			try (ResultSet rs = visualiserHoraireExamenPourUnBloc.executeQuery()) {
				System.out.printf("%-10s      %-20s | %-20s | %-20s |\n", "", "Heure de début", "Code examen",
						"Nom examen");
				while (rs.next()) {
					System.out.printf("%-10s ->   %-20s | %-20s | %-20s |\n", "Output",
							rs.getTimestamp(1) == null ? "Pas fixé" : rs.getTimestamp(1), rs.getString(2),
							rs.getString(3));
				}
				System.out.println();
			} catch (SQLException e) {
				System.out.printf("%-10s %-20s\n", "Output", "resultSet KO !\n");
				getException(e);
			}
		} catch (SQLException e) {
			System.out.printf("%-10s %-20s\n", "Output", "prepareStatement KO !\n");
			getException(e);
		}
	}

	public void close() {
		try {
			System.out.println("Tentative de déconnexion: ");
			conn.close();
			System.out.println("Deconnecté du serveur : " + url);
		} catch (SQLException e) {
			System.out.println("Problème de déconnexion !");
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
		while (running) {
			System.out.println();
			System.out.printf("%10s %20s %10s\n", "***********", "Application Centrale", "***********");
			System.out.println();
			System.out.printf(FORMAT_MENU, "1  ->", "Ajouter un local", "2  ->", "Ajouter un examen", "3  ->",
					"Encoder une heure de début pour un examen");
			System.out.printf("%-10s  %-40s | %-10s %-40s \n", "4  ->", "Réservé un local pour un examen", "5  ->",
					"Visualiser tout les examens pas encore complètement réservés");
			System.out.printf("%-10s  %-40s \n", "6  ->",
					"Visualiser pour chaque bloc les examens pas encore réservés");
		
			System.out.printf("%-10s  %-40s | %-10s %-40s \n", "7  ->", "Visualiser l'horaire d'examen d'un bloc",
					"8  ->", "Visualiser le nombre d'examens pas encore complétement réservés pour chaque bloc");
			System.out.printf("%-10s  %-20s\n", "9  ->", "Visualiser toutes les réservations d'examen du local");
			System.out.printf("%-10s  %-20s\n", "10 ->", "Arrêtée l'Application Centrale");
			System.out.printf(FORMAT_INPUT, "\nInput Menu \n", " -> Entrez votre choix : ");

			choix = scanner.nextLine();

			switch (choix) {
			case "1": {
				app.ajouterUnLocal();
				break;
			}
			case "2": {
				app.ajouterUnExamen();
				break;
			}
			case "3": {
				app.encoderHeureDebutExamen();
				break;
			}
			case "4": {
				app.reserverUnLocalPourUnExamen();
				break;
			}
			case "5": {
				app.visualiserToutLesExamensNonReserves();
				break;
			}
			case "6": {
				app.visualiserNombreExamenPasEncoreReserveePourChaqueBloc();
				break;
			}
			case "7": {
				app.visualiserHoraireExamenPourUnBloc();
				break;
			}
			case "8": {
				System.out.println("salut");
				break;
			}
			case "9": {
				app.visualiserReservationExamenDUnLocal();
				break;
			}
			case "10": {
				running = false;
				System.out.printf(FORMAT_OUTPUT_MESSAGE, "Output", "Application centrale arrétée !\n");
				break;
			}

			default:
				System.out.printf(FORMAT_OUTPUT_MESSAGE, "Output", "Veuillez choisir un chiffre entre 1 et 10!\n");

				break;
			}
		}
		app.close();
	}
}
