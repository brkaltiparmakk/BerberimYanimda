import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'Berber Yanimda'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Randevu'**
  String get appSubtitle;

  /// No description provided for @welcome.
  ///
  /// In tr, this message translates to:
  /// **'Hoş Geldiniz'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get login;

  /// No description provided for @register.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logout;

  /// No description provided for @phoneNumber.
  ///
  /// In tr, this message translates to:
  /// **'Telefon Numarası'**
  String get phoneNumber;

  /// No description provided for @password.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get password;

  /// No description provided for @verify.
  ///
  /// In tr, this message translates to:
  /// **'Doğrula'**
  String get verify;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get edit;

  /// No description provided for @loading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get loading;

  /// No description provided for @errorOccurred.
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu.'**
  String get errorOccurred;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get retry;

  /// No description provided for @noData.
  ///
  /// In tr, this message translates to:
  /// **'Veri bulunamadı'**
  String get noData;

  /// No description provided for @search.
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get search;

  /// No description provided for @favorites.
  ///
  /// In tr, this message translates to:
  /// **'Favoriler'**
  String get favorites;

  /// No description provided for @appointments.
  ///
  /// In tr, this message translates to:
  /// **'Randevularım'**
  String get appointments;

  /// No description provided for @notifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notifications;

  /// No description provided for @profile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @home.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get home;

  /// No description provided for @barbers.
  ///
  /// In tr, this message translates to:
  /// **'Berberler'**
  String get barbers;

  /// No description provided for @booking.
  ///
  /// In tr, this message translates to:
  /// **'Randevu Al'**
  String get booking;

  /// No description provided for @serviceSelection.
  ///
  /// In tr, this message translates to:
  /// **'Hizmet Seçimi'**
  String get serviceSelection;

  /// No description provided for @staffSelection.
  ///
  /// In tr, this message translates to:
  /// **'Personel Seçimi'**
  String get staffSelection;

  /// No description provided for @dateTimeSelection.
  ///
  /// In tr, this message translates to:
  /// **'Tarih ve Saat'**
  String get dateTimeSelection;

  /// No description provided for @summary.
  ///
  /// In tr, this message translates to:
  /// **'Özet'**
  String get summary;

  /// No description provided for @payment.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme'**
  String get payment;

  /// No description provided for @success.
  ///
  /// In tr, this message translates to:
  /// **'Başarılı'**
  String get success;

  /// No description provided for @next.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get next;

  /// No description provided for @back.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get back;

  /// No description provided for @select.
  ///
  /// In tr, this message translates to:
  /// **'Seç'**
  String get select;

  /// No description provided for @selected.
  ///
  /// In tr, this message translates to:
  /// **'Seçildi'**
  String get selected;

  /// No description provided for @all.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get all;

  /// No description provided for @upcoming.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşan'**
  String get upcoming;

  /// No description provided for @past.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş'**
  String get past;

  /// No description provided for @cancelled.
  ///
  /// In tr, this message translates to:
  /// **'İptal Edilen'**
  String get cancelled;

  /// No description provided for @workHours.
  ///
  /// In tr, this message translates to:
  /// **'Çalışma Saatleri'**
  String get workHours;

  /// No description provided for @services.
  ///
  /// In tr, this message translates to:
  /// **'Hizmetler'**
  String get services;

  /// No description provided for @staff.
  ///
  /// In tr, this message translates to:
  /// **'Personel'**
  String get staff;

  /// No description provided for @dashboard.
  ///
  /// In tr, this message translates to:
  /// **'Panel'**
  String get dashboard;

  /// No description provided for @confirmAppointment.
  ///
  /// In tr, this message translates to:
  /// **'Randevuyu Onayla'**
  String get confirmAppointment;

  /// No description provided for @completeAppointment.
  ///
  /// In tr, this message translates to:
  /// **'Randevuyu Tamamla'**
  String get completeAppointment;

  /// No description provided for @rejectAppointment.
  ///
  /// In tr, this message translates to:
  /// **'Randevuyu Reddet'**
  String get rejectAppointment;

  /// No description provided for @createService.
  ///
  /// In tr, this message translates to:
  /// **'Hizmet Ekle'**
  String get createService;

  /// No description provided for @updateService.
  ///
  /// In tr, this message translates to:
  /// **'Hizmet Güncelle'**
  String get updateService;

  /// No description provided for @createStaff.
  ///
  /// In tr, this message translates to:
  /// **'Personel Ekle'**
  String get createStaff;

  /// No description provided for @updateStaff.
  ///
  /// In tr, this message translates to:
  /// **'Personel Güncelle'**
  String get updateStaff;

  /// No description provided for @changePassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Değiştir'**
  String get changePassword;

  /// No description provided for @deleteAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabı Sil'**
  String get deleteAccount;

  /// No description provided for @exportData.
  ///
  /// In tr, this message translates to:
  /// **'Verilerimi Dışa Aktar'**
  String get exportData;

  /// No description provided for @support.
  ///
  /// In tr, this message translates to:
  /// **'Destek'**
  String get support;

  /// No description provided for @submit.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get submit;

  /// No description provided for @coupon.
  ///
  /// In tr, this message translates to:
  /// **'Kupon Kodu'**
  String get coupon;

  /// No description provided for @apply.
  ///
  /// In tr, this message translates to:
  /// **'Uygula'**
  String get apply;

  /// No description provided for @payAtBarber.
  ///
  /// In tr, this message translates to:
  /// **'Berberde Öde'**
  String get payAtBarber;

  /// No description provided for @payOnline.
  ///
  /// In tr, this message translates to:
  /// **'Online Öde'**
  String get payOnline;

  /// No description provided for @review.
  ///
  /// In tr, this message translates to:
  /// **'Yorum Yap'**
  String get review;

  /// No description provided for @rating.
  ///
  /// In tr, this message translates to:
  /// **'Puan'**
  String get rating;

  /// No description provided for @comment.
  ///
  /// In tr, this message translates to:
  /// **'Yorum'**
  String get comment;

  /// No description provided for @markAllRead.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Oku'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim yok'**
  String get noNotifications;

  /// No description provided for @noAppointments.
  ///
  /// In tr, this message translates to:
  /// **'Randevu yok'**
  String get noAppointments;

  /// No description provided for @noFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Henüz favori eklenmedi'**
  String get noFavorites;

  /// No description provided for @guest.
  ///
  /// In tr, this message translates to:
  /// **'Misafir'**
  String get guest;

  /// No description provided for @unverifiedPhone.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızı doğrulamak için SMS ile gelen kodu giriniz.'**
  String get unverifiedPhone;

  /// No description provided for @loggingIn.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yapılıyor...'**
  String get loggingIn;

  /// No description provided for @registering.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt oluşturuluyor...'**
  String get registering;

  /// No description provided for @verifying.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulanıyor...'**
  String get verifying;

  /// No description provided for @dontHaveAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın yok mu? Kayıt Ol'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabın var mı? Giriş Yap'**
  String get alreadyHaveAccount;

  /// No description provided for @fullName.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get fullName;

  /// No description provided for @email.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon'**
  String get phone;

  /// No description provided for @exploreNearby.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki berberleri keşfet'**
  String get exploreNearby;

  /// No description provided for @nearbyBarbers.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki Berberler'**
  String get nearbyBarbers;

  /// No description provided for @viewAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Gör'**
  String get viewAll;

  /// No description provided for @popular.
  ///
  /// In tr, this message translates to:
  /// **'Popüler'**
  String get popular;

  /// No description provided for @maleBarber.
  ///
  /// In tr, this message translates to:
  /// **'Erkek Kuaförü'**
  String get maleBarber;

  /// No description provided for @beard.
  ///
  /// In tr, this message translates to:
  /// **'Sakal'**
  String get beard;

  /// No description provided for @skinCare.
  ///
  /// In tr, this message translates to:
  /// **'Cilt Bakımı'**
  String get skinCare;

  /// No description provided for @myFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Favorilerim'**
  String get myFavorites;

  /// No description provided for @myProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profilim'**
  String get myProfile;

  /// No description provided for @explore.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet'**
  String get explore;

  /// No description provided for @map.
  ///
  /// In tr, this message translates to:
  /// **'Harita'**
  String get map;

  /// No description provided for @nearMe.
  ///
  /// In tr, this message translates to:
  /// **'Yakınımda'**
  String get nearMe;

  /// No description provided for @highestRated.
  ///
  /// In tr, this message translates to:
  /// **'En Yüksek Puan'**
  String get highestRated;

  /// No description provided for @availableNow.
  ///
  /// In tr, this message translates to:
  /// **'Müsait Olanlar'**
  String get availableNow;

  /// No description provided for @bestPrice.
  ///
  /// In tr, this message translates to:
  /// **'En Uygun Fiyat'**
  String get bestPrice;

  /// No description provided for @currentPassword.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut Şifre'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Şifre'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Şifre Tekrar'**
  String get confirmNewPassword;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In tr, this message translates to:
  /// **'Şifreler eşleşmiyor'**
  String get passwordsDontMatch;

  /// No description provided for @passwordChanged.
  ///
  /// In tr, this message translates to:
  /// **'Şifre değiştirildi'**
  String get passwordChanged;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem geri alınamaz. Hesabınız ve tüm verileriniz silinecektir.'**
  String get deleteAccountWarning;

  /// No description provided for @enterYourPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifrenizi girin'**
  String get enterYourPassword;

  /// No description provided for @preparingData.
  ///
  /// In tr, this message translates to:
  /// **'Verileriniz hazırlanıyor...'**
  String get preparingData;

  /// No description provided for @dataDownloadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Veriler indirilemedi.'**
  String get dataDownloadFailed;

  /// No description provided for @noAppointmentsInCategory.
  ///
  /// In tr, this message translates to:
  /// **'Bu kategoride randevu bulunamadı.'**
  String get noAppointmentsInCategory;

  /// No description provided for @noBarbersFound.
  ///
  /// In tr, this message translates to:
  /// **'Berber bulunamadı.'**
  String get noBarbersFound;

  /// No description provided for @editProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profili düzenle'**
  String get editProfile;

  /// No description provided for @profilePhoto.
  ///
  /// In tr, this message translates to:
  /// **'Profil fotoğrafı'**
  String get profilePhoto;

  /// No description provided for @helloUser.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba {userName} 👋'**
  String helloUser(String userName);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
