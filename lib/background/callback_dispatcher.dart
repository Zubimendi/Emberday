import 'package:emberday/background/tasks.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await topUp();
      return true;
    } on Object {
      // Return success to avoid aggressive OS backoff; errors are logged.
      return true;
    }
  });
}
