import 'package:rutero_server/busConsult.dart';
import 'package:rutero_server/variables.dart';
import 'rutero_server.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

/// This type initializes an application.
///
/// Override methods in this class to set up routes and initialize services like
/// database connections. See http://aqueduct.io/docs/http/channel/.


class RuteroServerChannel extends ApplicationChannel {

  Variables variables;
  String urlBase;

  RuteroServerChannel(){
    variables = Variables();
    urlBase = "Api/FlexoRuteros/Buses";
  }

  Future<void> getPublicIPAddress() async {
    try{
      final response = await http.get('http://checkip.dyndns.org/');
      final document = parse(parse(response.body).body.text);
      final getString = document.documentElement.text;
      variables.ip = getString.substring(getString.indexOf(':') + 2, getString.length).trim();
    }
    catch(e){
      print('Error: $e');
    }
    await Future.delayed(const Duration(minutes: 5));
    await getPublicIPAddress();
  }

  /// Initialize services in this method.
  ///
  /// Implement this method to initialize services, read values from [options]
  /// and any other initialization required before constructing [entryPoint].
  ///
  /// This method is invoked prior to [entryPoint] being accessed.

  @override
  Future prepare() async {
    logger.onRecord.listen((rec) => print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}"));
  }

  /// Construct the request channel.
  ///
  /// Return an instance of some [Controller] that will be the initial receiver
  /// of all [Request]s.
  ///
  /// This method is invoked after [prepare].
  @override
  Controller get entryPoint {
    final router = Router();

    // Prefer to use `link` instead of `linkFunction`.
    // See: https://aqueduct.io/docs/http/request_controller/

    //consulta los datos del bus por id
    router
      .route("$urlBase/GetID/[:id]")
      .link(() => BusConsult());

    //consulta los datos del bus por nombre
    router
      .route("$urlBase/ByName/[:name]")
      .link(() => BusConsult());

    //consulta todos los buses
    router
      .route("$urlBase/[:id]")
      .link(() => BusConsult());

    //consulta los datos del bus por IP publica
    router
      .route("$urlBase/ByPublicIP/[:publicIP]")
      .link(() => BusConsult());

    //consulta los datos del bus por IP compartida 
    router
      .route("$urlBase/BySharedIP/[:sharedIP]")
      .link(() => BusConsult());

    //ingresa un nuevo dato de bus si no existe (post)
    router
      .route("$urlBase/CreateBus")
      .link(() => BusConsult());

    //actualiza dato de bus existente o genera uno nuevo si no existe (put)
    router
      .route("$urlBase/UpdateDataBus/[:name]")
      .link(() => BusConsult());

    //elimina informacion de bus existente por medio de su nombre
    router
      .route("$urlBase/DeleteBus/ByName/[:name]")
      .link(() => BusConsult());

    //elimina informacion de bus existente por medio del ID
    router
      .route("$urlBase/DeleteBus/ByID/[:id]")
      .link(() => BusConsult());

    return router;
  }
}