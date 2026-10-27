import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows the dialog and closes the app if the user confirms.
Future<void> confirmExit(BuildContext context) async {
  final cs = Theme.of(context).colorScheme;

  final exit = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: cs.errorContainer, shape: BoxShape.circle),
        child: Icon(Icons.exit_to_app_rounded, color: cs.onErrorContainer, size: 30),
      ),
      title: const Text('Exit app?'),
      content: const Text('Are you sure you want to close the app?', textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Stay'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Exit'),
        ),
      ],
    ),
  );

  if (exit == true) SystemNavigator.pop();
}