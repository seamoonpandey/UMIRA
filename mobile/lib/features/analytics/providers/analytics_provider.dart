import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/analytics_repository.dart';

final analyticsSummaryProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>(
        (ref) => ref.read(analyticsRepoProvider).summary(),);
