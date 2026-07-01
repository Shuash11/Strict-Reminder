import 'package:flutter/material.dart';

import 'app.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseService.init();

  // Initialize notifications
  await NotificationService.init();

  runApp(const ForRealApp());
}
