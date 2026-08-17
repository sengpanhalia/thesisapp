import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:thesisapp/localization/app_localizations.dart';
import 'package:thesisapp/service/api_token_store.dart';
import 'package:thesisapp/theme_color.dart';

/// Asks for the key the book office issued for this phone, and saves it.
///
/// This used to live only inside the profile screen, and that put it somewhere
/// nobody without a key could ever reach. The app opens on sign-in; signing in
/// calls the API; the API refuses without a key — so the one screen that could
/// accept a key sat behind the one action a key was needed for. A phone with
/// no key could only ever show "This app has not been given a key for the book
/// system yet", with no way at all to give it one.
///
/// So it is a function rather than a method on a screen, and the sign-in page
/// offers it the moment that refusal is what came back. Both callers share
/// this one copy: a second dialog would be a second set of strings to keep in
/// step, and they would drift.
///
/// The API authenticates the *device*, not the student. A token is created in
/// the web app under Settings ▸ API Tokens and shown once, because only its
/// SHA-256 hash is stored. A build can carry one baked in with
/// `--dart-define=USEA_API_TOKEN=…`; this is how a phone is re-keyed
/// afterwards, when a token is revoked, without shipping a new build.
///
/// The field never shows a key that is already saved — a token is a password,
/// and there is nothing to gain by displaying it back.
Future<bool> showApiKeyDialog(BuildContext context) async {
  final lang = AppLocalizations.of(context)!;
  final controller = TextEditingController();

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        lang.translate('api_key'),
        style: TextStyle(fontFamily: getFontFamily(context)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            lang.translate('api_key_message'),
            style: TextStyle(
              fontFamily: getFontFamily(context),
              fontSize: fontText,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autocorrect: false,
            enableSuggestions: false,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'usea_…',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(lang.translate('cancel')),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(lang.translate('confirm')),
        ),
      ],
    ),
  );

  if (saved != true) return false;

  final key = controller.text.trim();

  // An empty box is a cancel by another route, and saving it would replace a
  // working key with nothing.
  if (key.isEmpty) return false;

  await ApiTokenStore.save(key);

  if (!context.mounted) return true;
  Fluttertoast.showToast(msg: lang.translate('api_key_saved'));

  return true;
}
