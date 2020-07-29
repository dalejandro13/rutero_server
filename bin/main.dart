import 'package:rutero_server/rutero_server.dart';

Future main() async {
  final app = Application<RuteroServerChannel>()
      ..options.configurationFilePath = "config.yaml"
      ..options.port = 9742;

  final count = Platform.numberOfProcessors ~/ 2;
  await app.start(numberOfInstances: count > 0 ? count : 1);

  print("Servidor HTTP establecido en puerto: ${app.options.port}.");
}