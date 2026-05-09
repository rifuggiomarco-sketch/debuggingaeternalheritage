// Italian Localization for Digital Vault Heritage v3.0
class AppLocalizations {
  const AppLocalizations();

  // App General
  static const String appName = 'Digital Vault Heritage';
  static const String appTagline = 'Proteggi il Tuo Patrimonio Digitale';
  static const String getStarted = 'Inizia';
  static const String skipForNow = 'Salta per Adesso';
  static const String continueText = 'Continua';
  static const String cancel = 'Annulla';
  static const String save = 'Salva';
  static const String delete = 'Elimina';
  static const String edit = 'Modifica';
  static const String add = 'Aggiungi';
  static const String remove = 'Rimuovi';
  static const String confirm = 'Conferma';
  static const String retry = 'Riprova';
  static const String loading = 'Caricamento...';
  static const String error = 'Errore';
  static const String hello = 'Ciao';
  static const String welcome = 'Benvenuto';
  static const String success = 'Successo';
  static const String warning = 'Avviso';
  static const String info = 'Informazioni';

  // Authentication
  static const String welcomeToDigitalVault = 'Benvenuto in Digital Vault Heritage';
  static const String createYourPin = 'Crea il Tuo PIN';
  static const String enterYourPin = 'Inserisci il Tuo PIN';
  static const String confirmPin = 'Conferma PIN';
  static const String pinHint = 'Inserisci PIN di 4-8 cifre';
  static const String pinCreated = 'PIN Creato';
  static const String pinMismatch = 'PIN non Corrispondente';
  static const String pinTooShort = 'PIN Troppo Corto';
  static const String pinTooLong = 'PIN Troppo Lungo';
  static const String invalidPin = 'PIN non Valido';
  static const String pinLocked = 'PIN Bloccato';
  static const String sessionExpired = 'Sessione Scaduta';
  static const String pleaseEnterPinAgain = 'Per favore inserisci di nuovo il PIN';
  static const String unlock = 'Sblocca';
  static const String lock = 'Blocca';

  // Biometric Authentication
  static const String enableBiometricAuth = 'Abilita Autenticazione Biometrica';
  static const String useBiometrics = 'Usa Biometrici';
  static const String biometricNotAvailable = 'Autenticazione Biometrica non Disponibile';
  static const String biometricAuthFailed = 'Autenticazione Biometrica Fallita';
  static const String biometricSetupSuccess = 'Configurazione Biometrica Riuscita';

  // Vault Management
  static const String yourDigitalVault = 'La Tua Cassaforte Digitale';
  static const String noDocumentsYet = 'Nessun Documento Ancora';
  static const String addDocument = 'Aggiungi Documento';
  static const String uploadDocument = 'Carica Documento';
  static const String documentName = 'Nome Documento';
  static const String selectFile = 'Seleziona File';
  static const String documentUploaded = 'Documento Caricato';
  static const String uploadFailed = 'Caricamento Fallito';
  static const String networkError = 'Errore di Rete';
  static const String unableToUploadFile = 'Impossibile Caricare il File';
  static const String fileSizeTooLarge = 'Dimensione File Troppo Grande';
  static const String unsupportedFileType = 'Tipo File non Supportato';

  // Document Categories
  static const String identity = 'Identità';
  static const String financial = 'Finanziario';
  static const String legal = 'Legale';
  static const String personal = 'Personale';
  static const String medical = 'Medico';
  static const String other = 'Altro';

  // Document Details
  static const String documentDetails = 'Dettagli Documento';
  static const String fileName = 'Nome File';
  static const String fileSize = 'Dimensione File';
  static const String uploadedOn = 'Caricato il';
  static const String lastModified = 'Ultima Modifica';
  static const String category = 'Categoria';
  static const String shareWithHeirs = 'Condividi con Eredi';
  static const String heirAccessLevel = 'Livello Accesso Erede';
  static const String noAccess = 'Nessun Accesso';
  static const String readOnly = 'Sola Lettura';
  static const String readWrite = 'Lettura/Scrittura';
  static const String fullAccess = 'Accesso Completo';

  // Dead Man's Switch
  static const String deadMansSwitch = 'Dead Man\'s Switch';
  static const String activateDeadMansSwitch = 'Attiva Dead Man\'s Switch';
  static const String deadMansSwitchActive = 'Dead Man\'s Switch Attivo';
  static const String deadMansSwitchInactive = 'Dead Man\'s Switch Inattivo';
  static const String checkInInterval = 'Intervallo Check-in';
  static const String maxMissedCheckIns = 'Check-in Massimi Mancati';
  static const String gracePeriod = 'Periodo di Grazia';
  static const String hours = 'Ore';
  static const String days = 'Giorni';
  static const String weeks = 'Settimane';
  static const String months = 'Mesi';
  static const String years = 'Anni';

  // Check-in System
  static const String performCheckIn = 'Esegui Check-in';
  static const String checkInSuccessful = 'Check-in Riuscito';
  static const String checkInFailed = 'Check-in Fallito';
  static const String lastCheckIn = 'Ultimo Check-in';
  static const String nextCheckInDue = 'Prossimo Check-in Previsto';
  static const String missedCheckIns = 'Check-in Mancati';
  static const String checkInChannels = 'Canali Check-in';
  static const String emailCheckIn = 'Check-in Email';
  static const String smsCheckIn = 'Check-in SMS';
  static const String pushCheckIn = 'Check-in Push';
  static const String inAppCheckIn = 'Check-in in App';

  // Grace Period
  static const String gracePeriodActive = 'Periodo di Grazia Attivo';
  static const String timeRemaining = 'Tempo Rimanente';
  static const String cancelGracePeriod = 'Annulla Periodo di Grazia';
  static const String heirsWillBeNotified = 'Gli Eredi Saranno Notificati';
  static const String gracePeriodCancelled = 'Periodo di Grazia Annullato';
  static const String emergencyProtocol = 'Protocollo di Emergenza';

  // Heir Management
  static const String heirs = 'Eredi';
  static const String addHeir = 'Aggiungi Erede';
  static const String heirConfiguration = 'Configurazione Erede';
  static const String heirName = 'Nome Erede';
  static const String heirEmail = 'Email Erede';
  static const String heirPhone = 'Telefono Erede';
  static const String heirRelationship = 'Relazione Erede';
  static const String saveHeir = 'Salva Erede';
  static const String heirAdded = 'Erede Aggiunto';
  static const String heirUpdated = 'Erede Aggiornato';
  static const String heirDeleted = 'Erede Eliminato';
  static const String noHeirsConfigured = 'Nessun Erede Configurato';
  static const String heirsConfigured = 'Eredi Configurati';

  // Settings and Support
  static const String settings = 'Impostazioni';
  static const String generalSettings = 'Impostazioni Generali';
  static const String language = 'Lingua';
  static const String theme = 'Tema';
  static const String darkTheme = 'Tema Scuro';
  static const String lightTheme = 'Tema Chiaro';
  static const String systemTheme = 'Tema di Sistema';
  static const String notifications = 'Notifiche';
  static const String about = 'Informazioni';
  static const String version = 'Versione';
  static const String privacyPolicy = 'Privacy Policy';
  static const String termsOfService = 'Termini di Servizio';
  static const String contactSupport = 'Contatta Supporto';

  // Legal and Compliance
  static const String legalPolicy = 'Policy Legale';
  static const String termsAndConditions = 'Termini e Condizioni';
  static const String dataProtection = 'Protezione Dati';
  static const String gdprCompliance = 'Conformità GDPR';
  static const String ccpaCompliance = 'Conformità CCPA';
  static const String zeroKnowledgeDefense = 'Difesa a Conoscenza Zero';
  static const String notLegalAdvice = 'Non è un Consiglio Legale';

  // Placeholders for Legal Compliance
  static const String ownerDetails = '[INSERISCI_DETTAGLIO_PROPRIETARIO]';
  static const String companyName = '[INSERISCI_NOME_COMPANY]';
  static const String supportEmail = '[INSERISCI_EMAIL_SUPPORTO]';
  static const String legalAddress = '[INSERISCI_INDIRIZZO_LEGALE]';
  static const String privacyContact = '[INSERISCI_CONTATTO_PRIVACY]';

  // Help and Support
  static const String help = 'Aiuto';
  static const String faq = 'Domande Frequenti';
  static const String tutorial = 'Tutorial';
  static const String contactUs = 'Contattaci';
  static const String feedback = 'Feedback';
  static const String reportIssue = 'Segnala Problema';

  // Statistics and Analytics
  static const String statistics = 'Statistiche';
  static const String vaultStatistics = 'Statistiche Cassaforte';
  static const String totalVaultSize = 'Dimensione Totale Cassaforte';
  static const String documentsByCategory = 'Documenti per Categoria';
  static const String heirActivity = 'Attività Eredi';
  static const String securityEvents = 'Eventi di Sicurezza';
  static const String lastLogin = 'Ultimo Accesso';
  static const String failedLogins = 'Accessi Falliti';
}
