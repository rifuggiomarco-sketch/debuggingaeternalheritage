// Simple Localization Service for Digital Vault Heritage v3.0
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_en.dart' as en;
import 'app_it.dart' as it;

class AppLanguage {
  final String displayName;
  final String code;
  final String flag;

  const AppLanguage(this.displayName, this.code, this.flag);

  static const en = AppLanguage('English', 'en', '🇺🇸');
  static const it = AppLanguage('Italiano', 'it', '🇮🇹');
}

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  Locale _currentLocale = const Locale('it');
  final StreamController<Locale> _localeController = StreamController<Locale>.broadcast();

  Stream<Locale> get localeStream => _localeController.stream;
  Locale get currentLocale => _currentLocale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'it';
    _currentLocale = Locale(languageCode);
    _localeController.add(_currentLocale);
  }

  Future<void> changeLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    _currentLocale = Locale(languageCode);
    _localeController.add(_currentLocale);
  }

  String get(String key) {
    switch (_currentLocale.languageCode) {
      case 'en':
        return _getEnglishString(key);
      case 'it':
        return _getItalianString(key);
      default:
        return _getItalianString(key);
    }
  }

  String _getEnglishString(String key) {
    switch (key) {
      case 'appName': return en.AppLocalizations.appName;
      case 'appTagline': return en.AppLocalizations.appTagline;
      case 'getStarted': return en.AppLocalizations.getStarted;
      case 'skipForNow': return en.AppLocalizations.skipForNow;
      case 'continueText': return en.AppLocalizations.continueText;
      case 'cancel': return en.AppLocalizations.cancel;
      case 'save': return en.AppLocalizations.save;
      case 'delete': return en.AppLocalizations.delete;
      case 'edit': return en.AppLocalizations.edit;
      case 'add': return en.AppLocalizations.add;
      case 'remove': return en.AppLocalizations.remove;
      case 'confirm': return en.AppLocalizations.confirm;
      case 'retry': return en.AppLocalizations.retry;
      case 'loading': return en.AppLocalizations.loading;
      case 'error': return en.AppLocalizations.error;
      case 'success': return en.AppLocalizations.success;
      case 'warning': return en.AppLocalizations.warning;
      case 'info': return en.AppLocalizations.info;
      case 'hello': return en.AppLocalizations.hello;
      case 'welcome': return en.AppLocalizations.welcome;

      // Authentication
      case 'welcomeToDigitalVault': return en.AppLocalizations.welcomeToDigitalVault;
      case 'createYourPin': return en.AppLocalizations.createYourPin;
      case 'enterYourPin': return en.AppLocalizations.enterYourPin;
      case 'confirmPin': return en.AppLocalizations.confirmPin;
      case 'pinHint': return en.AppLocalizations.pinHint;
      case 'pinCreated': return en.AppLocalizations.pinCreated;
      case 'pinMismatch': return en.AppLocalizations.pinMismatch;
      case 'pinTooShort': return en.AppLocalizations.pinTooShort;
      case 'pinTooLong': return en.AppLocalizations.pinTooLong;
      case 'invalidPin': return en.AppLocalizations.invalidPin;
      case 'pinLocked': return en.AppLocalizations.pinLocked;
      case 'sessionExpired': return en.AppLocalizations.sessionExpired;
      case 'pleaseEnterPinAgain': return en.AppLocalizations.pleaseEnterPinAgain;
      case 'unlock': return en.AppLocalizations.unlock;
      case 'lock': return en.AppLocalizations.lock;

      // Biometric Authentication
      case 'enableBiometricAuth': return en.AppLocalizations.enableBiometricAuth;
      case 'useBiometrics': return en.AppLocalizations.useBiometrics;
      case 'biometricNotAvailable': return en.AppLocalizations.biometricNotAvailable;
      case 'biometricAuthFailed': return en.AppLocalizations.biometricAuthFailed;
      case 'biometricSetupSuccess': return en.AppLocalizations.biometricSetupSuccess;

      // Vault Management
      case 'yourDigitalVault': return en.AppLocalizations.yourDigitalVault;
      case 'noDocumentsYet': return en.AppLocalizations.noDocumentsYet;
      case 'addDocument': return en.AppLocalizations.addDocument;
      case 'uploadDocument': return en.AppLocalizations.uploadDocument;
      case 'documentName': return en.AppLocalizations.documentName;
      case 'selectFile': return en.AppLocalizations.selectFile;
      case 'documentUploaded': return en.AppLocalizations.documentUploaded;
      case 'uploadFailed': return en.AppLocalizations.uploadFailed;
      case 'networkError': return en.AppLocalizations.networkError;
      case 'unableToUploadFile': return en.AppLocalizations.unableToUploadFile;
      case 'fileSizeTooLarge': return en.AppLocalizations.fileSizeTooLarge;
      case 'unsupportedFileType': return en.AppLocalizations.unsupportedFileType;

      // Document Categories
      case 'identity': return en.AppLocalizations.identity;
      case 'financial': return en.AppLocalizations.financial;
      case 'legal': return en.AppLocalizations.legal;
      case 'personal': return en.AppLocalizations.personal;
      case 'medical': return en.AppLocalizations.medical;
      case 'other': return en.AppLocalizations.other;

      // Document Details
      case 'documentDetails': return en.AppLocalizations.documentDetails;
      case 'fileName': return en.AppLocalizations.fileName;
      case 'fileSize': return en.AppLocalizations.fileSize;
      case 'uploadedOn': return en.AppLocalizations.uploadedOn;
      case 'lastModified': return en.AppLocalizations.lastModified;
      case 'category': return en.AppLocalizations.category;
      case 'shareWithHeirs': return en.AppLocalizations.shareWithHeirs;
      case 'heirAccessLevel': return en.AppLocalizations.heirAccessLevel;
      case 'noAccess': return en.AppLocalizations.noAccess;
      case 'readOnly': return en.AppLocalizations.readOnly;
      case 'readWrite': return en.AppLocalizations.readWrite;
      case 'fullAccess': return en.AppLocalizations.fullAccess;

      // Dead Man's Switch
      case 'deadMansSwitch': return en.AppLocalizations.deadMansSwitch;
      case 'activateDeadMansSwitch': return en.AppLocalizations.activateDeadMansSwitch;
      case 'deadMansSwitchActive': return en.AppLocalizations.deadMansSwitchActive;
      case 'deadMansSwitchInactive': return en.AppLocalizations.deadMansSwitchInactive;
      case 'checkInInterval': return en.AppLocalizations.checkInInterval;
      case 'maxMissedCheckIns': return en.AppLocalizations.maxMissedCheckIns;
      case 'gracePeriod': return en.AppLocalizations.gracePeriod;
      case 'hours': return en.AppLocalizations.hours;
      case 'days': return en.AppLocalizations.days;
      case 'weeks': return en.AppLocalizations.weeks;
      case 'months': return en.AppLocalizations.months;
      case 'years': return en.AppLocalizations.years;

      // Check-in System
      case 'performCheckIn': return en.AppLocalizations.performCheckIn;
      case 'checkInSuccessful': return en.AppLocalizations.checkInSuccessful;
      case 'checkInFailed': return en.AppLocalizations.checkInFailed;
      case 'lastCheckIn': return en.AppLocalizations.lastCheckIn;
      case 'nextCheckInDue': return en.AppLocalizations.nextCheckInDue;
      case 'missedCheckIns': return en.AppLocalizations.missedCheckIns;
      case 'checkInChannels': return en.AppLocalizations.checkInChannels;
      case 'emailCheckIn': return en.AppLocalizations.emailCheckIn;
      case 'smsCheckIn': return en.AppLocalizations.smsCheckIn;
      case 'pushCheckIn': return en.AppLocalizations.pushCheckIn;
      case 'inAppCheckIn': return en.AppLocalizations.inAppCheckIn;

      // Grace Period
      case 'gracePeriodActive': return en.AppLocalizations.gracePeriodActive;
      case 'timeRemaining': return en.AppLocalizations.timeRemaining;
      case 'cancelGracePeriod': return en.AppLocalizations.cancelGracePeriod;
      case 'heirsWillBeNotified': return en.AppLocalizations.heirsWillBeNotified;
      case 'gracePeriodCancelled': return en.AppLocalizations.gracePeriodCancelled;
      case 'emergencyProtocol': return en.AppLocalizations.emergencyProtocol;

      // Heir Management
      case 'heirs': return en.AppLocalizations.heirs;
      case 'addHeir': return en.AppLocalizations.addHeir;
      case 'heirConfiguration': return en.AppLocalizations.heirConfiguration;
      case 'heirName': return en.AppLocalizations.heirName;
      case 'heirEmail': return en.AppLocalizations.heirEmail;
      case 'heirPhone': return en.AppLocalizations.heirPhone;
      case 'heirRelationship': return en.AppLocalizations.heirRelationship;
      case 'saveHeir': return en.AppLocalizations.saveHeir;
      case 'heirAdded': return en.AppLocalizations.heirAdded;
      case 'heirUpdated': return en.AppLocalizations.heirUpdated;
      case 'heirDeleted': return en.AppLocalizations.heirDeleted;
      case 'noHeirsConfigured': return en.AppLocalizations.noHeirsConfigured;
      case 'heirsConfigured': return en.AppLocalizations.heirsConfigured;

      // Settings
      case 'settings': return en.AppLocalizations.settings;
      case 'generalSettings': return en.AppLocalizations.generalSettings;
      case 'language': return en.AppLocalizations.language;
      case 'theme': return en.AppLocalizations.theme;
      case 'darkTheme': return en.AppLocalizations.darkTheme;
      case 'lightTheme': return en.AppLocalizations.lightTheme;
      case 'systemTheme': return en.AppLocalizations.systemTheme;
      case 'notifications': return en.AppLocalizations.notifications;
      case 'about': return en.AppLocalizations.about;
      case 'version': return en.AppLocalizations.version;
      case 'privacyPolicy': return en.AppLocalizations.privacyPolicy;
      case 'termsOfService': return en.AppLocalizations.termsOfService;
      case 'contactSupport': return en.AppLocalizations.contactSupport;

      // Legal and Compliance
      case 'legalPolicy': return en.AppLocalizations.legalPolicy;
      case 'termsAndConditions': return en.AppLocalizations.termsAndConditions;
      case 'dataProtection': return en.AppLocalizations.dataProtection;
      case 'gdprCompliance': return en.AppLocalizations.gdprCompliance;
      case 'ccpaCompliance': return en.AppLocalizations.ccpaCompliance;
      case 'zeroKnowledgeDefense': return en.AppLocalizations.zeroKnowledgeDefense;
      case 'notLegalAdvice': return en.AppLocalizations.notLegalAdvice;

      // Placeholders
      case 'ownerDetails': return en.AppLocalizations.ownerDetails;
      case 'companyName': return en.AppLocalizations.companyName;
      case 'supportEmail': return en.AppLocalizations.supportEmail;
      case 'legalAddress': return en.AppLocalizations.legalAddress;
      case 'privacyContact': return en.AppLocalizations.privacyContact;

      // Help and Support
      case 'help': return en.AppLocalizations.help;
      case 'faq': return en.AppLocalizations.faq;
      case 'tutorial': return en.AppLocalizations.tutorial;
      case 'contactUs': return en.AppLocalizations.contactUs;
      case 'feedback': return en.AppLocalizations.feedback;
      case 'reportIssue': return en.AppLocalizations.reportIssue;

      // Statistics and Analytics
      case 'statistics': return en.AppLocalizations.statistics;
      case 'vaultStatistics': return en.AppLocalizations.vaultStatistics;
      case 'totalVaultSize': return en.AppLocalizations.totalVaultSize;
      case 'documentsByCategory': return en.AppLocalizations.documentsByCategory;
      case 'heirActivity': return en.AppLocalizations.heirActivity;
      case 'securityEvents': return en.AppLocalizations.securityEvents;
      case 'lastLogin': return en.AppLocalizations.lastLogin;
      case 'failedLogins': return en.AppLocalizations.failedLogins;

      default:
        return key; // Return key if not found
    }
  }

  String _getItalianString(String key) {
    switch (key) {
      // App General
      case 'appName': return it.AppLocalizations.appName;
      case 'appTagline': return it.AppLocalizations.appTagline;
      case 'getStarted': return it.AppLocalizations.getStarted;
      case 'skipForNow': return it.AppLocalizations.skipForNow;
      case 'continueText': return it.AppLocalizations.continueText;
      case 'cancel': return it.AppLocalizations.cancel;
      case 'save': return it.AppLocalizations.save;
      case 'delete': return it.AppLocalizations.delete;
      case 'edit': return it.AppLocalizations.edit;
      case 'add': return it.AppLocalizations.add;
      case 'remove': return it.AppLocalizations.remove;
      case 'confirm': return it.AppLocalizations.confirm;
      case 'retry': return it.AppLocalizations.retry;
      case 'loading': return it.AppLocalizations.loading;
      case 'error': return it.AppLocalizations.error;
      case 'success': return it.AppLocalizations.success;
      case 'warning': return it.AppLocalizations.warning;
      case 'info': return it.AppLocalizations.info;
      case 'hello': return it.AppLocalizations.hello;
      case 'welcome': return it.AppLocalizations.welcome;

      // Authentication
      case 'welcomeToDigitalVault': return it.AppLocalizations.welcomeToDigitalVault;
      case 'createYourPin': return it.AppLocalizations.createYourPin;
      case 'enterYourPin': return it.AppLocalizations.enterYourPin;
      case 'confirmPin': return it.AppLocalizations.confirmPin;
      case 'pinHint': return it.AppLocalizations.pinHint;
      case 'pinCreated': return it.AppLocalizations.pinCreated;
      case 'pinMismatch': return it.AppLocalizations.pinMismatch;
      case 'pinTooShort': return it.AppLocalizations.pinTooShort;
      case 'pinTooLong': return it.AppLocalizations.pinTooLong;
      case 'invalidPin': return it.AppLocalizations.invalidPin;
      case 'pinLocked': return it.AppLocalizations.pinLocked;
      case 'sessionExpired': return it.AppLocalizations.sessionExpired;
      case 'pleaseEnterPinAgain': return it.AppLocalizations.pleaseEnterPinAgain;
      case 'unlock': return it.AppLocalizations.unlock;
      case 'lock': return it.AppLocalizations.lock;

      // Biometric Authentication
      case 'enableBiometricAuth': return it.AppLocalizations.enableBiometricAuth;
      case 'useBiometrics': return it.AppLocalizations.useBiometrics;
      case 'biometricNotAvailable': return it.AppLocalizations.biometricNotAvailable;
      case 'biometricAuthFailed': return it.AppLocalizations.biometricAuthFailed;
      case 'biometricSetupSuccess': return it.AppLocalizations.biometricSetupSuccess;

      // Vault Management
      case 'yourDigitalVault': return it.AppLocalizations.yourDigitalVault;
      case 'noDocumentsYet': return it.AppLocalizations.noDocumentsYet;
      case 'addDocument': return it.AppLocalizations.addDocument;
      case 'uploadDocument': return it.AppLocalizations.uploadDocument;
      case 'documentName': return it.AppLocalizations.documentName;
      case 'selectFile': return it.AppLocalizations.selectFile;
      case 'documentUploaded': return it.AppLocalizations.documentUploaded;
      case 'uploadFailed': return it.AppLocalizations.uploadFailed;
      case 'networkError': return it.AppLocalizations.networkError;
      case 'unableToUploadFile': return it.AppLocalizations.unableToUploadFile;
      case 'fileSizeTooLarge': return it.AppLocalizations.fileSizeTooLarge;
      case 'unsupportedFileType': return it.AppLocalizations.unsupportedFileType;

      // Document Categories
      case 'identity': return it.AppLocalizations.identity;
      case 'financial': return it.AppLocalizations.financial;
      case 'legal': return it.AppLocalizations.legal;
      case 'personal': return it.AppLocalizations.personal;
      case 'medical': return it.AppLocalizations.medical;
      case 'other': return it.AppLocalizations.other;

      // Document Details
      case 'documentDetails': return it.AppLocalizations.documentDetails;
      case 'fileName': return it.AppLocalizations.fileName;
      case 'fileSize': return it.AppLocalizations.fileSize;
      case 'uploadedOn': return it.AppLocalizations.uploadedOn;
      case 'lastModified': return it.AppLocalizations.lastModified;
      case 'category': return it.AppLocalizations.category;
      case 'shareWithHeirs': return it.AppLocalizations.shareWithHeirs;
      case 'heirAccessLevel': return it.AppLocalizations.heirAccessLevel;
      case 'noAccess': return it.AppLocalizations.noAccess;
      case 'readOnly': return it.AppLocalizations.readOnly;
      case 'readWrite': return it.AppLocalizations.readWrite;
      case 'fullAccess': return it.AppLocalizations.fullAccess;

      // Dead Man's Switch
      case 'deadMansSwitch': return it.AppLocalizations.deadMansSwitch;
      case 'activateDeadMansSwitch': return it.AppLocalizations.activateDeadMansSwitch;
      case 'deadMansSwitchActive': return it.AppLocalizations.deadMansSwitchActive;
      case 'deadMansSwitchInactive': return it.AppLocalizations.deadMansSwitchInactive;
      case 'checkInInterval': return it.AppLocalizations.checkInInterval;
      case 'maxMissedCheckIns': return it.AppLocalizations.maxMissedCheckIns;
      case 'gracePeriod': return it.AppLocalizations.gracePeriod;
      case 'hours': return it.AppLocalizations.hours;
      case 'days': return it.AppLocalizations.days;
      case 'weeks': return it.AppLocalizations.weeks;
      case 'months': return it.AppLocalizations.months;
      case 'years': return it.AppLocalizations.years;

      // Check-in System
      case 'performCheckIn': return it.AppLocalizations.performCheckIn;
      case 'checkInSuccessful': return it.AppLocalizations.checkInSuccessful;
      case 'checkInFailed': return it.AppLocalizations.checkInFailed;
      case 'lastCheckIn': return it.AppLocalizations.lastCheckIn;
      case 'nextCheckInDue': return it.AppLocalizations.nextCheckInDue;
      case 'missedCheckIns': return it.AppLocalizations.missedCheckIns;
      case 'checkInChannels': return it.AppLocalizations.checkInChannels;
      case 'emailCheckIn': return it.AppLocalizations.emailCheckIn;
      case 'smsCheckIn': return it.AppLocalizations.smsCheckIn;
      case 'pushCheckIn': return it.AppLocalizations.pushCheckIn;
      case 'inAppCheckIn': return it.AppLocalizations.inAppCheckIn;

      // Grace Period
      case 'gracePeriodActive': return it.AppLocalizations.gracePeriodActive;
      case 'timeRemaining': return it.AppLocalizations.timeRemaining;
      case 'cancelGracePeriod': return it.AppLocalizations.cancelGracePeriod;
      case 'heirsWillBeNotified': return it.AppLocalizations.heirsWillBeNotified;
      case 'gracePeriodCancelled': return it.AppLocalizations.gracePeriodCancelled;
      case 'emergencyProtocol': return it.AppLocalizations.emergencyProtocol;

      // Heir Management
      case 'heirs': return it.AppLocalizations.heirs;
      case 'addHeir': return it.AppLocalizations.addHeir;
      case 'heirConfiguration': return it.AppLocalizations.heirConfiguration;
      case 'heirName': return it.AppLocalizations.heirName;
      case 'heirEmail': return it.AppLocalizations.heirEmail;
      case 'heirPhone': return it.AppLocalizations.heirPhone;
      case 'heirRelationship': return it.AppLocalizations.heirRelationship;
      case 'saveHeir': return it.AppLocalizations.saveHeir;
      case 'heirAdded': return it.AppLocalizations.heirAdded;
      case 'heirUpdated': return it.AppLocalizations.heirUpdated;
      case 'heirDeleted': return it.AppLocalizations.heirDeleted;
      case 'noHeirsConfigured': return it.AppLocalizations.noHeirsConfigured;
      case 'heirsConfigured': return it.AppLocalizations.heirsConfigured;

      // Settings
      case 'settings': return it.AppLocalizations.settings;
      case 'generalSettings': return it.AppLocalizations.generalSettings;
      case 'language': return it.AppLocalizations.language;
      case 'theme': return it.AppLocalizations.theme;
      case 'darkTheme': return it.AppLocalizations.darkTheme;
      case 'lightTheme': return it.AppLocalizations.lightTheme;
      case 'systemTheme': return it.AppLocalizations.systemTheme;
      case 'notifications': return it.AppLocalizations.notifications;
      case 'about': return it.AppLocalizations.about;
      case 'version': return it.AppLocalizations.version;
      case 'privacyPolicy': return it.AppLocalizations.privacyPolicy;
      case 'termsOfService': return it.AppLocalizations.termsOfService;
      case 'contactSupport': return it.AppLocalizations.contactSupport;

      // Legal and Compliance
      case 'legalPolicy': return it.AppLocalizations.legalPolicy;
      case 'termsAndConditions': return it.AppLocalizations.termsAndConditions;
      case 'dataProtection': return it.AppLocalizations.dataProtection;
      case 'gdprCompliance': return it.AppLocalizations.gdprCompliance;
      case 'ccpaCompliance': return it.AppLocalizations.ccpaCompliance;
      case 'zeroKnowledgeDefense': return it.AppLocalizations.zeroKnowledgeDefense;
      case 'notLegalAdvice': return it.AppLocalizations.notLegalAdvice;

      // Placeholders
      case 'ownerDetails': return it.AppLocalizations.ownerDetails;
      case 'companyName': return it.AppLocalizations.companyName;
      case 'supportEmail': return it.AppLocalizations.supportEmail;
      case 'legalAddress': return it.AppLocalizations.legalAddress;
      case 'privacyContact': return it.AppLocalizations.privacyContact;

      // Help and Support
      case 'help': return it.AppLocalizations.help;
      case 'faq': return it.AppLocalizations.faq;
      case 'tutorial': return it.AppLocalizations.tutorial;
      case 'contactUs': return it.AppLocalizations.contactUs;
      case 'feedback': return it.AppLocalizations.feedback;
      case 'reportIssue': return it.AppLocalizations.reportIssue;

      // Statistics and Analytics
      case 'statistics': return it.AppLocalizations.statistics;
      case 'vaultStatistics': return it.AppLocalizations.vaultStatistics;
      case 'totalVaultSize': return it.AppLocalizations.totalVaultSize;
      case 'documentsByCategory': return it.AppLocalizations.documentsByCategory;
      case 'heirActivity': return it.AppLocalizations.heirActivity;
      case 'securityEvents': return it.AppLocalizations.securityEvents;
      case 'lastLogin': return it.AppLocalizations.lastLogin;
      case 'failedLogins': return it.AppLocalizations.failedLogins;

      default:
        return key; // Return key if not found
    }
  }

  AppLanguage getLanguageForLocale(Locale locale) {
    final languages = [AppLanguage.en, AppLanguage.it];
    for (final language in languages) {
      if (language.code == locale.languageCode) {
        return language;
      }
    }
    return AppLanguage.en; // Default to English
  }

  List<AppLanguage> get supportedLanguages => [AppLanguage.en, AppLanguage.it];
}

// Extension method for easy access to localized strings
extension LocalizedString on String {
  String tr(BuildContext context) {
    final localizations = LocalizationService();
    return localizations.get(this);
  }
}
