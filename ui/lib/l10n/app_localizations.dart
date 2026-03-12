import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

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
    Locale('en'),
    Locale('hi'),
    Locale('mr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Agri Assist'**
  String get appTitle;

  /// No description provided for @cropAdvice.
  ///
  /// In en, this message translates to:
  /// **'Crop Advice'**
  String get cropAdvice;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @marketPrices.
  ///
  /// In en, this message translates to:
  /// **'Market Prices'**
  String get marketPrices;

  /// No description provided for @governmentSchemes.
  ///
  /// In en, this message translates to:
  /// **'Government Schemes'**
  String get governmentSchemes;

  /// No description provided for @soilType.
  ///
  /// In en, this message translates to:
  /// **'Soil Type'**
  String get soilType;

  /// No description provided for @waterSource.
  ///
  /// In en, this message translates to:
  /// **'Water Source'**
  String get waterSource;

  /// No description provided for @micInstruction.
  ///
  /// In en, this message translates to:
  /// **'Tap the microphone and start speaking'**
  String get micInstruction;

  /// No description provided for @deleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete Chat?'**
  String get deleteChat;

  /// No description provided for @deleteChatConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this chat history? This cannot be undone.'**
  String get deleteChatConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete chat. Please try again.'**
  String get deleteFailed;

  /// No description provided for @createChatFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create new chat session.'**
  String get createChatFailed;

  /// No description provided for @loadChatFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load chat history.'**
  String get loadChatFailed;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// No description provided for @myGallery.
  ///
  /// In en, this message translates to:
  /// **'My Gallery'**
  String get myGallery;

  /// No description provided for @recentChats.
  ///
  /// In en, this message translates to:
  /// **'Recent Chats'**
  String get recentChats;

  /// No description provided for @noRecentChats.
  ///
  /// In en, this message translates to:
  /// **'No recent chats.'**
  String get noRecentChats;

  /// No description provided for @selectState.
  ///
  /// In en, this message translates to:
  /// **'Select State'**
  String get selectState;

  /// No description provided for @selectDistrict.
  ///
  /// In en, this message translates to:
  /// **'Select District'**
  String get selectDistrict;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type message...'**
  String get typeMessage;

  /// No description provided for @loginToChat.
  ///
  /// In en, this message translates to:
  /// **'Please login to chat'**
  String get loginToChat;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @audioLoading.
  ///
  /// In en, this message translates to:
  /// **'Audio is still loading, please wait.'**
  String get audioLoading;

  /// No description provided for @typing.
  ///
  /// In en, this message translates to:
  /// **'Typing...'**
  String get typing;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @micNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Microphone not available'**
  String get micNotAvailable;

  /// No description provided for @noSpeech.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t hear anything'**
  String get noSpeech;

  /// No description provided for @thinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking...'**
  String get thinking;

  /// No description provided for @speaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking...'**
  String get speaking;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server connection problem'**
  String get serverError;

  /// No description provided for @somethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWrong;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @voice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voice;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @currently.
  ///
  /// In en, this message translates to:
  /// **'Currently'**
  String get currently;

  /// No description provided for @assistantVoicePreferences.
  ///
  /// In en, this message translates to:
  /// **'Assistant Voice Preferences'**
  String get assistantVoicePreferences;

  /// No description provided for @appVersionInfo.
  ///
  /// In en, this message translates to:
  /// **'App version & information'**
  String get appVersionInfo;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @featureNextUpdate.
  ///
  /// In en, this message translates to:
  /// **'Feature available in the next update.'**
  String get featureNextUpdate;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @aiCompanion.
  ///
  /// In en, this message translates to:
  /// **'Your AI Farming Companion.'**
  String get aiCompanion;

  /// No description provided for @bazaarBhav.
  ///
  /// In en, this message translates to:
  /// **'Bazaar Bhav'**
  String get bazaarBhav;

  /// No description provided for @filterMarkets.
  ///
  /// In en, this message translates to:
  /// **'Filter Markets'**
  String get filterMarkets;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @applyFilter.
  ///
  /// In en, this message translates to:
  /// **'Apply Filter'**
  String get applyFilter;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @market.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get market;

  /// No description provided for @msp.
  ///
  /// In en, this message translates to:
  /// **'MSP'**
  String get msp;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @pleaseSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Please select your location to see market prices'**
  String get pleaseSelectLocation;

  /// No description provided for @agriSchemes.
  ///
  /// In en, this message translates to:
  /// **'Agri Schemes'**
  String get agriSchemes;

  /// No description provided for @searchSchemes.
  ///
  /// In en, this message translates to:
  /// **'Search schemes, crops, or benefits...'**
  String get searchSchemes;

  /// No description provided for @states.
  ///
  /// In en, this message translates to:
  /// **'States'**
  String get states;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @schemesFound.
  ///
  /// In en, this message translates to:
  /// **'{count} schemes found'**
  String schemesFound(Object count);

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @noSchemesFound.
  ///
  /// In en, this message translates to:
  /// **'No matching schemes found'**
  String get noSchemesFound;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @unknownScheme.
  ///
  /// In en, this message translates to:
  /// **'Unknown Scheme'**
  String get unknownScheme;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description provided.'**
  String get noDescription;

  /// No description provided for @schemeDetails.
  ///
  /// In en, this message translates to:
  /// **'Scheme Details'**
  String get schemeDetails;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @geographicEligibility.
  ///
  /// In en, this message translates to:
  /// **'Geographic Eligibility'**
  String get geographicEligibility;

  /// No description provided for @closingDate.
  ///
  /// In en, this message translates to:
  /// **'Closing Date'**
  String get closingDate;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @applyForScheme.
  ///
  /// In en, this message translates to:
  /// **'Apply for Scheme'**
  String get applyForScheme;

  /// No description provided for @agriWeather.
  ///
  /// In en, this message translates to:
  /// **'AgriWeather'**
  String get agriWeather;

  /// No description provided for @weeklyForecast.
  ///
  /// In en, this message translates to:
  /// **'Weekly Forecast'**
  String get weeklyForecast;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @caution.
  ///
  /// In en, this message translates to:
  /// **'Caution'**
  String get caution;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Sync Error'**
  String get syncError;

  /// No description provided for @retryConnection.
  ///
  /// In en, this message translates to:
  /// **'Retry Connection'**
  String get retryConnection;

  /// No description provided for @noWeatherData.
  ///
  /// In en, this message translates to:
  /// **'No weather data available'**
  String get noWeatherData;

  /// No description provided for @adviceSunnyGood.
  ///
  /// In en, this message translates to:
  /// **'Ideal for harvesting and sun-drying.'**
  String get adviceSunnyGood;

  /// No description provided for @adviceSunnyBad.
  ///
  /// In en, this message translates to:
  /// **'High evaporation. Check irrigation.'**
  String get adviceSunnyBad;

  /// No description provided for @adviceCloudGood.
  ///
  /// In en, this message translates to:
  /// **'Perfect for spraying fertilizers.'**
  String get adviceCloudGood;

  /// No description provided for @adviceCloudBad.
  ///
  /// In en, this message translates to:
  /// **'Not ideal for solar-drying crops.'**
  String get adviceCloudBad;

  /// No description provided for @adviceRainGood.
  ///
  /// In en, this message translates to:
  /// **'Natural irrigation! Great for transplanting.'**
  String get adviceRainGood;

  /// No description provided for @adviceRainBad.
  ///
  /// In en, this message translates to:
  /// **'Avoid harvesting to prevent rot.'**
  String get adviceRainBad;

  /// No description provided for @adviceStormGood.
  ///
  /// In en, this message translates to:
  /// **'Indoor planning and equipment maintenance.'**
  String get adviceStormGood;

  /// No description provided for @adviceStormBad.
  ///
  /// In en, this message translates to:
  /// **'Secure livestock and stay safe.'**
  String get adviceStormBad;

  /// No description provided for @adviceDefaultGood.
  ///
  /// In en, this message translates to:
  /// **'Favorable for field inspections.'**
  String get adviceDefaultGood;

  /// No description provided for @adviceDefaultBad.
  ///
  /// In en, this message translates to:
  /// **'Watch for sudden weather shifts.'**
  String get adviceDefaultBad;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
    case 'mr': return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
