// lib/services/spartan_service.dart
// Backward-compatible aliases for code that still imports the old Spartan/Sherpa name.
// New code should import q_builder_service.dart directly.

import 'q_builder_service.dart';

@Deprecated('Use QBuilderService instead.')
class SpartanLegacyService extends QBuilderService {
  SpartanLegacyService(super.exerciseService);
}

@Deprecated('Use QBuilderRequest instead.')
typedef SpartanRequest = QBuilderRequest;

@Deprecated('Use QBuilderResult instead.')
typedef SpartanResult = QBuilderResult;

@Deprecated('Use QBuilderReview instead.')
typedef SpartanReview = QBuilderReview;
