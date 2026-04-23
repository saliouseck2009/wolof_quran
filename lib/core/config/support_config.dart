/// Remote-configurable support/donation information.
///
/// Default values are hardcoded so the app works offline.
/// A JSON override can be fetched from a GitHub Gist at runtime.
class SupportConfig {
  final String waveUrl;
  final String waveLabel;
  final String piSpiQrData;
  final String piSpiText;
  final String messageFr;
  final String messageEn;
  final String messageAr;
  final bool enabled;

  const SupportConfig({
    required this.waveUrl,
    required this.waveLabel,
    required this.piSpiQrData,
    required this.piSpiText,
    required this.messageFr,
    required this.messageEn,
    required this.messageAr,
    required this.enabled,
  });

  /// Hardcoded defaults — used when no remote config is available.
  static const SupportConfig defaults = SupportConfig(
    waveUrl: 'https://pay.wave.com/m/M_sn_qQLOpGuegWny/c/sn/',
    waveLabel: 'Wave',
    piSpiQrData:
        '00020136560012int.bceao.pi01366f041b7f-e66b-4b0f-8312-84dcae79a1cf5204000053039525802SN5901X6001X62071103731630410AB',
    piSpiText: '6f041b7f-e66b-4b0f-8312-84dcae79a1cf',
    messageFr:
        'Coran Wolof est un projet gratuit et bénévole. Votre soutien nous aide à maintenir l\'application, ajouter de nouvelles fonctionnalités et garder l\'accès libre pour tous. Chaque contribution, même petite, fait une grande différence. Jazaakumullaahu khairan.',
    messageEn:
        'Wolof Quran is a free, volunteer-driven project. Your support helps us maintain the app, add new features, and keep it accessible for everyone. Every contribution, no matter how small, makes a big difference. Jazaakumullaahu khairan.',
    messageAr:
        'القرآن بالولوف مشروع مجاني وتطوعي. دعمكم يساعدنا على صيانة التطبيق وإضافة ميزات جديدة وإبقائه متاحًا للجميع. كل مساهمة مهما كانت صغيرة تُحدث فرقًا كبيرًا. جزاكم الله خيرًا.',
    enabled: true,
  );

  factory SupportConfig.fromJson(Map<String, dynamic> json) {
    return SupportConfig(
      waveUrl: json['wave_url'] as String? ?? defaults.waveUrl,
      waveLabel: json['wave_label'] as String? ?? defaults.waveLabel,
      piSpiQrData: json['pi_spi_qr_data'] as String? ?? defaults.piSpiQrData,
      piSpiText: json['pi_spi_text'] as String? ?? defaults.piSpiText,
      messageFr: json['message_fr'] as String? ?? defaults.messageFr,
      messageEn: json['message_en'] as String? ?? defaults.messageEn,
      messageAr: json['message_ar'] as String? ?? defaults.messageAr,
      enabled: json['enabled'] as bool? ?? defaults.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'wave_url': waveUrl,
        'wave_label': waveLabel,
        'pi_spi_qr_data': piSpiQrData,
        'pi_spi_text': piSpiText,
        'message_fr': messageFr,
        'message_en': messageEn,
        'message_ar': messageAr,
        'enabled': enabled,
      };

  /// Returns the localised encouragement message for the given [languageCode].
  String messageForLocale(String languageCode) {
    switch (languageCode) {
      case 'fr':
        return messageFr;
      case 'ar':
        return messageAr;
      default:
        return messageEn;
    }
  }
}
