import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';

bool get isDesktopOrElse =>
  kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux;

abstract class EditorControllerHost {
  TextEditingController get nameController;
  TextEditingController get xController;
  TextEditingController get yController;
}
