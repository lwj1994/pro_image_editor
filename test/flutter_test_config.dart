import 'dart:async';

import 'package:pro_image_editor/core/utils/logger.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Logger.enabled = true;
  await testMain();
}
