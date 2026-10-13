import 'package:flutter/material.dart';
import 'match_history_view.dart';

class PlayerHistoryStandaloneView extends StatelessWidget {
  const PlayerHistoryStandaloneView({super.key});

  @override
  Widget build(BuildContext context) {
    return const MatchHistoryView(showBackButton: true);
  }
}
