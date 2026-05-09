// English Localization for Digital Vault Heritage v3.0
class AppLocalizations {
  const AppLocalizations();

  // App General
  static const String appName = 'Digital Vault Heritage';
  static const String appTagline = 'Secure Your Digital Legacy';
  static const String getStarted = 'Get Started';
  static const String skipForNow = 'Skip for Now';
  static const String continueText = 'Continue';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String add = 'Add';
  static const String remove = 'Remove';
  static const String confirm = 'Confirm';
  static const String retry = 'Retry';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String hello = 'Hello';
  static const String welcome = 'Welcome';
  static const String success = 'Success';
  static const String warning = 'Warning';
  static const String info = 'Information';

  // Authentication
  static const String welcomeToDigitalVault = 'Welcome to Digital Vault Heritage';
  static const String createYourPin = 'Create Your PIN';
  static const String enterYourPin = 'Enter Your PIN';
  static const String confirmPin = 'Confirm PIN';
  static const String pinHint = 'Enter 4-8 digit PIN';
  static const String pinCreated = 'PIN Created Successfully';
  static const String pinMismatch = 'PINs do not match';
  static const String pinTooShort = 'PIN must be at least 4 digits';
  static const String pinTooLong = 'PIN cannot exceed 8 digits';
  static const String invalidPin = 'Invalid PIN format';
  static const String pinLocked = 'Too many failed attempts. Please try again later.';
  static const String sessionExpired = 'Session Expired';
  static const String pleaseEnterPinAgain = 'Please enter your PIN again';
  static const String unlock = 'Unlock';
  static const String lock = 'Lock';

  // Biometric Authentication
  static const String enableBiometricAuth = 'Enable Biometric Authentication';
  static const String useBiometrics = 'Use Biometrics';
  static const String biometricNotAvailable = 'Biometric authentication not available';
  static const String biometricAuthFailed = 'Biometric authentication failed';
  static const String biometricSetupSuccess = 'Biometric authentication enabled';

  // Vault Management
  static const String yourDigitalVault = 'Your Digital Vault';
  static const String noDocumentsYet = 'No documents yet';
  static const String addDocument = 'Add Document';
  static const String uploadDocument = 'Upload Document';
  static const String documentName = 'Document Name';
  static const String selectFile = 'Select File';
  static const String documentUploaded = 'Document uploaded successfully';
  static const String uploadFailed = 'Upload failed';
  static const String networkError = 'Network Error';
  static const String unableToUploadFile = 'Unable to upload file. Please check your connection.';
  static const String fileSizeTooLarge = 'File size too large';
  static const String unsupportedFileType = 'Unsupported file type';

  // Document Categories
  static const String identity = 'Identity';
  static const String financial = 'Financial';
  static const String legal = 'Legal';
  static const String personal = 'Personal';
  static const String medical = 'Medical';
  static const String other = 'Other';

  // Document Details
  static const String documentDetails = 'Document Details';
  static const String fileName = 'File Name';
  static const String fileSize = 'File Size';
  static const String uploadedOn = 'Uploaded On';
  static const String lastModified = 'Last Modified';
  static const String category = 'Category';
  static const String shareWithHeirs = 'Share with Heirs';
  static const String heirAccessLevel = 'Heir Access Level';
  static const String noAccess = 'No Access';
  static const String readOnly = 'Read Only';
  static const String readWrite = 'Read Write';
  static const String fullAccess = 'Full Access';

  // Dead Man's Switch
  static const String deadMansSwitch = 'Dead Man\'s Switch';
  static const String activateDeadMansSwitch = 'Activate Dead Man\'s Switch';
  static const String deadMansSwitchActive = 'Dead Man\'s Switch Active';
  static const String deadMansSwitchInactive = 'Dead Man\'s Switch Inactive';
  static const String checkInInterval = 'Check-in Interval';
  static const String maxMissedCheckIns = 'Maximum Missed Check-ins';
  static const String gracePeriod = 'Grace Period';
  static const String hours = 'hours';
  static const String days = 'days';
  static const String weeks = 'weeks';
  static const String months = 'months';
  static const String years = 'years';

  // Check-in System
  static const String performCheckIn = 'Perform Check-in';
  static const String checkInSuccessful = 'Check-in successful';
  static const String checkInFailed = 'Check-in failed';
  static const String lastCheckIn = 'Last Check-in';
  static const String nextCheckInDue = 'Next Check-in Due';
  static const String missedCheckIns = 'Missed Check-ins';
  static const String checkInChannels = 'Check-in Channels';
  static const String emailCheckIn = 'Email Check-in';
  static const String smsCheckIn = 'SMS Check-in';
  static const String pushCheckIn = 'Push Notification';
  static const String inAppCheckIn = 'In-App Check-in';

  // Grace Period
  static const String gracePeriodActive = 'Grace Period Active';
  static const String timeRemaining = 'Time remaining';
  static const String cancelGracePeriod = 'Cancel Grace Period';
  static const String heirsWillBeNotified = 'Heirs will be notified if no action is taken';
  static const String gracePeriodCancelled = 'Grace period cancelled successfully';
  static const String emergencyProtocol = 'Emergency Protocol';

  // Heir Management
  static const String heirs = 'Heirs';
  static const String addHeir = 'Add Heir';
  static const String heirConfiguration = 'Heir Configuration';
  static const String heirName = 'Heir Name';
  static const String heirEmail = 'Heir Email';
  static const String heirPhone = 'Heir Phone';
  static const String heirRelationship = 'Relationship';
  static const String saveHeir = 'Save Heir';
  static const String heirAdded = 'Heir added successfully';
  static const String heirUpdated = 'Heir updated successfully';
  static const String heirDeleted = 'Heir deleted successfully';
  static const String noHeirsConfigured = 'No heirs configured';
  static const String heirsConfigured = 'heirs configured';

  // Heir Relationships
  static const String spouse = 'Spouse / Partner';
  static const String child = 'Child';
  static const String parent = 'Parent';
  static const String sibling = 'Sibling';
  static const String friend = 'Friend';
  static const String lawyer = 'Lawyer / Notary';
  static const String otherRelationship = 'Other';

  // Conditional Inheritance
  static const String inheritanceRules = 'Inheritance Rules';
  static const String addInheritanceRule = 'Add Inheritance Rule';
  static const String ruleName = 'Rule Name';
  static const String ruleDescription = 'Rule Description';
  static const String conditionType = 'Condition Type';
  static const String timeBased = 'Time-based';
  static const String eventBased = 'Event-based';
  static const String locationBased = 'Location-based';
  static const String approvalBased = 'Approval-based';
  static const String customCondition = 'Custom Condition';
  static const String allowedHeirs = 'Allowed Heirs';
  static const String allowedFolders = 'Allowed Folders';
  static const String allowedDocumentTypes = 'Allowed Document Types';
  static const String saveRule = 'Save Rule';
  static const String ruleCreated = 'Rule created successfully';
  static const String ruleUpdated = 'Rule updated successfully';
  static const String ruleDeleted = 'Rule deleted successfully';

  // Subscription Management
  static const String subscription = 'Subscription';
  static const String chooseYourPlan = 'Choose Your Plan';
  static const String currentPlan = 'Current Plan';
  static const String freePlan = 'Free Plan';
  static const String premiumPlan = 'Premium Plan';
  static const String lifetimePlan = 'Lifetime Plan';
  static const String upgrade = 'Upgrade';
  static const String upgradeToPremium = 'Upgrade to Premium';
  static const String billingCycle = 'Billing Cycle';
  static const String monthly = 'Monthly';
  static const String yearly = 'Yearly';
  static const String lifetime = 'Lifetime';
  static const String paymentInformation = 'Payment Information';
  static const String cardNumber = 'Card Number';
  static const String expiryDate = 'Expiry Date';
  static const String cvv = 'CVV';
  static const String completePayment = 'Complete Payment';
  static const String paymentSuccessful = 'Payment successful';
  static const String paymentFailed = 'Payment failed';
  static const String premiumPlanActive = 'Premium Plan Active';
  static const String subscriptionCancelled = 'Subscription cancelled successfully';

  // Plan Features
  static const String features = 'Features';
  static const String documents = 'Documents';
  static const String maxDocuments = 'Max Documents';
  static const String unlimited = 'Unlimited';
  static const String maxHeirs = 'Max Heirs';
  static const String deadMansSwitchFeature = 'Dead Man\'s Switch';
  static const String conditionalInheritance = 'Conditional Inheritance';
  static const String multiChannelCheckIn = 'Multi-channel Check-in';
  static const String userReports = 'User Reports';
  static const String advancedSecurity = 'Advanced Security';

  // User Reporting
  static const String reportSettings = 'Report Settings';
  static const String reportFrequency = 'Report Frequency';
  static const String weekly = 'Weekly';
  static const String quarterly = 'Quarterly';
  static const String semiAnnually = 'Semi-annually';
  static const String annually = 'Annually';
  static const String includeCharts = 'Include Charts';
  static const String includeDetailedLogs = 'Include Detailed Logs';
  static const String saveSettings = 'Save Settings';
  static const String generateReport = 'Generate Report';
  static const String sendReport = 'Send Report';
  static const String vaultStatusReport = 'Vault Status Report';
  static const String generatedOn = 'Generated on';
  static const String totalDocuments = 'Total Documents';
  static const String totalSize = 'Total Size';
  static const String sharedDocuments = 'Shared Documents';
  static const String securitySummary = 'Security Summary';
  static const String heirStatus = 'Heir Status';
  static const String subscriptionStatus = 'Subscription Status';

  // Security Features
  static const String security = 'Security';
  static const String securitySettings = 'Security Settings';
  static const String changePin = 'Change PIN';
  static const String currentPin = 'Current PIN';
  static const String newPin = 'New PIN';
  static const String confirmNewPin = 'Confirm New PIN';
  static const String pinChanged = 'PIN changed successfully';
  static const String enableTwoFactor = 'Enable Two-Factor Authentication';
  static const String twoFactorEnabled = 'Two-factor authentication enabled';
  static const String twoFactorDisabled = 'Two-factor authentication disabled';

  // Settings
  static const String settings = 'Settings';
  static const String generalSettings = 'General';
  static const String language = 'Language';
  static const String theme = 'Theme';
  static const String darkTheme = 'Dark Theme';
  static const String lightTheme = 'Light Theme';
  static const String systemTheme = 'System Theme';
  static const String notifications = 'Notifications';
  static const String emailNotifications = 'Email Notifications';
  static const String pushNotifications = 'Push Notifications';
  static const String smsNotifications = 'SMS Notifications';
  static const String about = 'About';
  static const String version = 'Version';
  static const String privacyPolicy = 'Privacy Policy';
  static const String termsOfService = 'Terms of Service';
  static const String contactSupport = 'Contact Support';

  // Error Messages
  static const String somethingWentWrong = 'Something went wrong';
  static const String pleaseTryAgain = 'Please try again';
  static const String noInternetConnection = 'No internet connection';
  static const String serverError = 'Server error';
  static const String unauthorized = 'Unauthorized';
  static const String forbidden = 'Access forbidden';
  static const String notFound = 'Not found';
  static const String timeout = 'Request timeout';
  static const String invalidCredentials = 'Invalid credentials';
  static const String accountLocked = 'Account locked';
  static const String maintenanceMode = 'System under maintenance';

  // Success Messages
  static const String operationSuccessful = 'Operation completed successfully';
  static const String dataSaved = 'Data saved successfully';
  static const String changesApplied = 'Changes applied successfully';
  static const String configurationUpdated = 'Configuration updated successfully';
  static const String vaultIsReady = 'Your Vault is Ready';
  static const String welcomeBack = 'Welcome back';

  // Legal and Compliance
  static const String legalPolicy = 'Legal Policy';
  static const String termsAndConditions = 'Terms and Conditions';
  static const String dataProtection = 'Data Protection';
  static const String gdprCompliance = 'GDPR Compliance';
  static const String ccpaCompliance = 'CCPA Compliance';
  static const String zeroKnowledgeDefense = 'Zero-Knowledge Defense';
  static const String notLegalAdvice = 'Not Legal Advice';

  // Recovery
  static const String recovery = 'Recovery';
  static const String recoveryKey = 'Recovery Key';
  static const String generateRecoveryKey = 'Generate Recovery Key';
  static const String saveRecoveryKey = 'Save Recovery Key Securely';
  static const String recoveryKeyGenerated = 'Recovery key generated';
  static const String recoveryKeyWarning = 'Save this key in a safe place. You will need it to recover your vault.';
  static const String recoverVault = 'Recover Vault';
  static const String enterRecoveryKey = 'Enter Recovery Key';
  static const String invalidRecoveryKey = 'Invalid recovery key';
  static const String vaultRecovered = 'Vault recovered successfully';

  // Backup and Sync
  static const String backup = 'Backup';
  static const String createBackup = 'Create Backup';
  static const String restoreBackup = 'Restore Backup';
  static const String backupCreated = 'Backup created successfully';
  static const String backupRestored = 'Backup restored successfully';
  static const String lastBackup = 'Last Backup';
  static const String automaticBackup = 'Automatic Backup';
  static const String backupFrequency = 'Backup Frequency';

  // Statistics and Analytics
  static const String statistics = 'Statistics';
  static const String vaultStatistics = 'Vault Statistics';
  static const String totalVaultSize = 'Total Vault Size';
  static const String documentsByCategory = 'Documents by Category';
  static const String heirActivity = 'Heir Activity';
  static const String securityEvents = 'Security Events';
  static const String lastLogin = 'Last Login';
  static const String failedLogins = 'Failed Logins';

  // Help and Support
  static const String help = 'Help';
  static const String faq = 'Frequently Asked Questions';
  static const String tutorial = 'Tutorial';
  static const String contactUs = 'Contact Us';
  static const String feedback = 'Feedback';
  static const String reportIssue = 'Report Issue';

  // Placeholders for Legal Compliance
  static const String ownerDetails = '[INSERT_OWNER_DETAILS]';
  static const String companyName = '[INSERT_COMPANY_NAME]';
  static const String supportEmail = '[INSERT_SUPPORT_EMAIL]';
  static const String legalAddress = '[INSERT_LEGAL_ADDRESS]';
  static const String privacyContact = '[INSERT_PRIVACY_CONTACT]';
}
