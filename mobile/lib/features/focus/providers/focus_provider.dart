import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/focus_repository.dart';

final focusActionsProvider = Provider((ref) => ref.watch(focusRepoProvider));
