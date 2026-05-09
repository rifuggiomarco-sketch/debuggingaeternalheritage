import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Digital Vault Heritage'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Protect Your Digital Legacy'**
  String get appTagline;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for Now'**
  String get skipForNow;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get info;

  /// No description provided for @welcomeToDigitalVault.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Digital Vault Heritage'**
  String get welcomeToDigitalVault;

  /// No description provided for @createYourPin.
  ///
  /// In en, this message translates to:
  /// **'Create Your PIN'**
  String get createYourPin;

  /// No description provided for @enterYourPin.
  ///
  /// In en, this message translates to:
  /// **'Enter Your PIN'**
  String get enterYourPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// No description provided for @pinHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 4-8 digit PIN'**
  String get pinHint;

  /// No description provided for @pinCreated.
  ///
  /// In en, this message translates to:
  /// **'PIN Created'**
  String get pinCreated;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PIN Mismatch'**
  String get pinMismatch;

  /// No description provided for @pinTooShort.
  ///
  /// In en, this message translates to:
  /// **'PIN Too Short'**
  String get pinTooShort;

  /// No description provided for @pinTooLong.
  ///
  /// In en, this message translates to:
  /// **'PIN Too Long'**
  String get pinTooLong;

  /// No description provided for @invalidPin.
  ///
  /// In en, this message translates to:
  /// **'Invalid PIN'**
  String get invalidPin;

  /// No description provided for @pinLocked.
  ///
  /// In en, this message translates to:
  /// **'PIN Locked'**
  String get pinLocked;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session Expired'**
  String get sessionExpired;

  /// No description provided for @pleaseEnterPinAgain.
  ///
  /// In en, this message translates to:
  /// **'Please enter PIN again'**
  String get pleaseEnterPinAgain;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @lock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lock;

  /// No description provided for @enableBiometricAuth.
  ///
  /// In en, this message translates to:
  /// **'Enable Biometric Authentication'**
  String get enableBiometricAuth;

  /// No description provided for @useBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Use Biometrics'**
  String get useBiometrics;

  /// No description provided for @biometricNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication Not Available'**
  String get biometricNotAvailable;

  /// No description provided for @biometricAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication Failed'**
  String get biometricAuthFailed;

  /// No description provided for @biometricSetupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Biometric Setup Success'**
  String get biometricSetupSuccess;

  /// No description provided for @yourDigitalVault.
  ///
  /// In en, this message translates to:
  /// **'Your Digital Vault'**
  String get yourDigitalVault;

  /// No description provided for @noDocumentsYet.
  ///
  /// In en, this message translates to:
  /// **'No Documents Yet'**
  String get noDocumentsYet;

  /// No description provided for @addDocument.
  ///
  /// In en, this message translates to:
  /// **'Add Document'**
  String get addDocument;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uploadDocument;

  /// No description provided for @documentName.
  ///
  /// In en, this message translates to:
  /// **'Document Name'**
  String get documentName;

  /// No description provided for @selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get selectFile;

  /// No description provided for @documentUploaded.
  ///
  /// In en, this message translates to:
  /// **'Document Uploaded'**
  String get documentUploaded;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload Failed'**
  String get uploadFailed;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network Error'**
  String get networkError;

  /// No description provided for @unableToUploadFile.
  ///
  /// In en, this message translates to:
  /// **'Unable to Upload File'**
  String get unableToUploadFile;

  /// No description provided for @fileSizeTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File Size Too Large'**
  String get fileSizeTooLarge;

  /// No description provided for @unsupportedFileType.
  ///
  /// In en, this message translates to:
  /// **'Unsupported File Type'**
  String get unsupportedFileType;

  /// No description provided for @identity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get identity;

  /// No description provided for @financial.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get financial;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @medical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get medical;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @documentDetails.
  ///
  /// In en, this message translates to:
  /// **'Document Details'**
  String get documentDetails;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get fileName;

  /// No description provided for @fileSize.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get fileSize;

  /// No description provided for @uploadedOn.
  ///
  /// In en, this message translates to:
  /// **'Uploaded On'**
  String get uploadedOn;

  /// No description provided for @lastModified.
  ///
  /// In en, this message translates to:
  /// **'Last Modified'**
  String get lastModified;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @shareWithHeirs.
  ///
  /// In en, this message translates to:
  /// **'Share with Heirs'**
  String get shareWithHeirs;

  /// No description provided for @heirAccessLevel.
  ///
  /// In en, this message translates to:
  /// **'Heir Access Level'**
  String get heirAccessLevel;

  /// No description provided for @noAccess.
  ///
  /// In en, this message translates to:
  /// **'No Access'**
  String get noAccess;

  /// No description provided for @readOnly.
  ///
  /// In en, this message translates to:
  /// **'Read Only'**
  String get readOnly;

  /// No description provided for @readWrite.
  ///
  /// In en, this message translates to:
  /// **'Read/Write'**
  String get readWrite;

  /// No description provided for @fullAccess.
  ///
  /// In en, this message translates to:
  /// **'Full Access'**
  String get fullAccess;

  /// No description provided for @deadMansSwitch.
  ///
  /// In en, this message translates to:
  /// **'Dead Man\'s Switch'**
  String get deadMansSwitch;

  /// No description provided for @activateDeadMansSwitch.
  ///
  /// In en, this message translates to:
  /// **'Activate Dead Man\'s Switch'**
  String get activateDeadMansSwitch;

  /// No description provided for @deadMansSwitchActive.
  ///
  /// In en, this message translates to:
  /// **'Dead Man\'s Switch Active'**
  String get deadMansSwitchActive;

  /// No description provided for @deadMansSwitchInactive.
  ///
  /// In en, this message translates to:
  /// **'Dead Man\'s Switch Inactive'**
  String get deadMansSwitchInactive;

  /// No description provided for @checkInInterval.
  ///
  /// In en, this message translates to:
  /// **'Check-in Interval'**
  String get checkInInterval;

  /// No description provided for @maxMissedCheckIns.
  ///
  /// In en, this message translates to:
  /// **'Max Missed Check-ins'**
  String get maxMissedCheckIns;

  /// No description provided for @gracePeriod.
  ///
  /// In en, this message translates to:
  /// **'Grace Period'**
  String get gracePeriod;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @weeks.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get weeks;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get months;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get years;

  /// No description provided for @performCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Perform Check-in'**
  String get performCheckIn;

  /// No description provided for @checkInSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Check-in Successful'**
  String get checkInSuccessful;

  /// No description provided for @checkInFailed.
  ///
  /// In en, this message translates to:
  /// **'Check-in Failed'**
  String get checkInFailed;

  /// No description provided for @lastCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Last Check-in'**
  String get lastCheckIn;

  /// No description provided for @nextCheckInDue.
  ///
  /// In en, this message translates to:
  /// **'Next Check-in Due'**
  String get nextCheckInDue;

  /// No description provided for @missedCheckIns.
  ///
  /// In en, this message translates to:
  /// **'Missed Check-ins'**
  String get missedCheckIns;

  /// No description provided for @checkInChannels.
  ///
  /// In en, this message translates to:
  /// **'Check-in Channels'**
  String get checkInChannels;

  /// No description provided for @emailCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Email Check-in'**
  String get emailCheckIn;

  /// No description provided for @smsCheckIn.
  ///
  /// In en, this message translates to:
  /// **'SMS Check-in'**
  String get smsCheckIn;

  /// No description provided for @pushCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Push Check-in'**
  String get pushCheckIn;

  /// No description provided for @inAppCheckIn.
  ///
  /// In en, this message translates to:
  /// **'In-App Check-in'**
  String get inAppCheckIn;

  /// No description provided for @gracePeriodActive.
  ///
  /// In en, this message translates to:
  /// **'Grace Period Active'**
  String get gracePeriodActive;

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time Remaining'**
  String get timeRemaining;

  /// No description provided for @cancelGracePeriod.
  ///
  /// In en, this message translates to:
  /// **'Cancel Grace Period'**
  String get cancelGracePeriod;

  /// No description provided for @heirsWillBeNotified.
  ///
  /// In en, this message translates to:
  /// **'Heirs Will Be Notified'**
  String get heirsWillBeNotified;

  /// No description provided for @gracePeriodCancelled.
  ///
  /// In en, this message translates to:
  /// **'Grace Period Cancelled'**
  String get gracePeriodCancelled;

  /// No description provided for @emergencyProtocol.
  ///
  /// In en, this message translates to:
  /// **'Emergency Protocol'**
  String get emergencyProtocol;

  /// No description provided for @heirs.
  ///
  /// In en, this message translates to:
  /// **'Heirs'**
  String get heirs;

  /// No description provided for @addHeir.
  ///
  /// In en, this message translates to:
  /// **'Add Heir'**
  String get addHeir;

  /// No description provided for @heirConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Heir Configuration'**
  String get heirConfiguration;

  /// No description provided for @heirName.
  ///
  /// In en, this message translates to:
  /// **'Heir Name'**
  String get heirName;

  /// No description provided for @heirEmail.
  ///
  /// In en, this message translates to:
  /// **'Heir Email'**
  String get heirEmail;

  /// No description provided for @heirPhone.
  ///
  /// In en, this message translates to:
  /// **'Heir Phone'**
  String get heirPhone;

  /// No description provided for @heirRelationship.
  ///
  /// In en, this message translates to:
  /// **'Heir Relationship'**
  String get heirRelationship;

  /// No description provided for @saveHeir.
  ///
  /// In en, this message translates to:
  /// **'Save Heir'**
  String get saveHeir;

  /// No description provided for @heirAdded.
  ///
  /// In en, this message translates to:
  /// **'Heir Added'**
  String get heirAdded;

  /// No description provided for @heirUpdated.
  ///
  /// In en, this message translates to:
  /// **'Heir Updated'**
  String get heirUpdated;

  /// No description provided for @heirDeleted.
  ///
  /// In en, this message translates to:
  /// **'Heir Deleted'**
  String get heirDeleted;

  /// No description provided for @noHeirsConfigured.
  ///
  /// In en, this message translates to:
  /// **'No Heirs Configured'**
  String get noHeirsConfigured;

  /// No description provided for @heirsConfigured.
  ///
  /// In en, this message translates to:
  /// **'Heirs Configured'**
  String get heirsConfigured;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get lightTheme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System Theme'**
  String get systemTheme;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @legalPolicy.
  ///
  /// In en, this message translates to:
  /// **'Legal Policy'**
  String get legalPolicy;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @dataProtection.
  ///
  /// In en, this message translates to:
  /// **'Data Protection'**
  String get dataProtection;

  /// No description provided for @gdprCompliance.
  ///
  /// In en, this message translates to:
  /// **'GDPR Compliance'**
  String get gdprCompliance;

  /// No description provided for @ccpaCompliance.
  ///
  /// In en, this message translates to:
  /// **'CCPA Compliance'**
  String get ccpaCompliance;

  /// No description provided for @zeroKnowledgeDefense.
  ///
  /// In en, this message translates to:
  /// **'Zero Knowledge Defense'**
  String get zeroKnowledgeDefense;

  /// No description provided for @notLegalAdvice.
  ///
  /// In en, this message translates to:
  /// **'Not Legal Advice'**
  String get notLegalAdvice;

  /// No description provided for @ownerDetails.
  ///
  /// In en, this message translates to:
  /// **'[ENTER_OWNER_DETAILS]'**
  String get ownerDetails;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'[ENTER_COMPANY_NAME]'**
  String get companyName;

  /// No description provided for @supportEmail.
  ///
  /// In en, this message translates to:
  /// **'[ENTER_SUPPORT_EMAIL]'**
  String get supportEmail;

  /// No description provided for @legalAddress.
  ///
  /// In en, this message translates to:
  /// **'[ENTER_LEGAL_ADDRESS]'**
  String get legalAddress;

  /// No description provided for @privacyContact.
  ///
  /// In en, this message translates to:
  /// **'[ENTER_PRIVACY_CONTACT]'**
  String get privacyContact;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @tutorial.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get tutorial;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportIssue;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @vaultStatistics.
  ///
  /// In en, this message translates to:
  /// **'Vault Statistics'**
  String get vaultStatistics;

  /// No description provided for @totalVaultSize.
  ///
  /// In en, this message translates to:
  /// **'Total Vault Size'**
  String get totalVaultSize;

  /// No description provided for @documentsByCategory.
  ///
  /// In en, this message translates to:
  /// **'Documents by Category'**
  String get documentsByCategory;

  /// No description provided for @heirActivity.
  ///
  /// In en, this message translates to:
  /// **'Heir Activity'**
  String get heirActivity;

  /// No description provided for @securityEvents.
  ///
  /// In en, this message translates to:
  /// **'Security Events'**
  String get securityEvents;

  /// No description provided for @lastLogin.
  ///
  /// In en, this message translates to:
  /// **'Last Login'**
  String get lastLogin;

  /// No description provided for @failedLogins.
  ///
  /// In en, this message translates to:
  /// **'Failed Logins'**
  String get failedLogins;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
