import 'package:flutter/material.dart';
import '../core/app_assets.dart';
import '../services/localization_service.dart';
import '../services/translation_service.dart';
import '../models/movie.dart';

class ActorCard extends StatefulWidget {
  final Cast actor;

  const ActorCard({
    super.key,
    required this.actor,
  });

  @override
  State<ActorCard> createState() => _ActorCardState();
}

class _ActorCardState extends State<ActorCard> {
  String? _displayName;
  String? _displayCharacter;

  bool _looksArabic(String s) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(s);
  }

  @override
  void initState() {
    super.initState();
    _displayName = widget.actor.name;
    _displayCharacter =
        widget.actor.characterName.isEmpty ? 'N/A' : widget.actor.characterName;

    // If app language is Arabic, attempt to translate names/characters
    if (LocalizationService().isArabic) {
      _maybeTranslate();
    }
  }

  Future<void> _maybeTranslate() async {
    try {
      final ts = TranslationService();
      // Translate name if it does not look Arabic
      final name = widget.actor.name;
      if (name.isNotEmpty && !_looksArabic(name)) {
        final translated = await ts.translateToArabic(name);
        if (mounted && translated.isNotEmpty && translated != name) {
          setState(() => _displayName = translated);
        }
      }

      final character = widget.actor.characterName;
      if (character.isNotEmpty && !_looksArabic(character)) {
        final translatedChar = await ts.translateToArabic(character);
        if (mounted &&
            translatedChar.isNotEmpty &&
            translatedChar != character) {
          setState(() => _displayCharacter = translatedChar);
        }
      }
    } catch (_) {
      // ignore translation errors, keep original
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = LocalizationService().isArabic;
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    // Theme-aware colors
    final containerColor = isLightTheme ? Colors.grey[300] : AppAssets.gray;
    final textColor = isLightTheme ? Colors.black87 : AppAssets.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Actor Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              widget.actor.urlSmallImage,
              height: 70,
              width: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 70,
                  width: 70,
                  color: Colors.grey,
                  child: const Icon(Icons.person, color: Colors.white),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          // Actor Details
          Flexible(
            fit: FlexFit.loose,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isArabic ? 'الاسم' : 'Name'}: ${_displayName ?? widget.actor.name}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${isArabic ? 'الشخصية' : 'Character'}: ${_displayCharacter ?? widget.actor.characterName}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
