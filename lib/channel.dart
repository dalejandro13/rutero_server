import 'package:mongo_dart/mongo_dart.dart';
import 'package:rutero_server/adminDB.dart';
import 'package:rutero_server/serverConsult.dart';
import 'package:rutero_server/userConsult.dart';
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
  //AdmonDB admon = AdmonDB();
  //DbCollection globalCollUser, globalCollServer;

  RuteroServerChannel(){
    variables = Variables();
    urlBase = "Api/FlexoRuteros/Buses";
    //connectRuteros();
  }

  // void connectRuteros() async {
  //   await admon.connectToRuteroServer().then((datab) {
  //     globalCollUser = datab.collection('Usuario');
  //     globalCollServer = datab.collection('RuteroServer');
  //   });   
  // }

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


    ///////////////consulta con Usuarios//////////////
    
    //consultar todos los ruteros con id de empresa
    router
      .route("$urlBase/GetUserByID/[:id]")
      .link(() => UserConsult());
    
    //consultar todos los ruteros por el nombre de la empresa
    router
      .route("$urlBase/GetUserByName/[:name]")
      .link(() => UserConsult());

    //ingresa un nuevo usuario si no existe (post)
    router
      .route("$urlBase/CreateUser")
      .link(() => UserConsult());

    //inserta datos en la lista de ruteros si esta vacio (put)
    router
      .route("$urlBase/InsertDataRuteros/[:nme]")
      .link(() => UserConsult());

    //borra usuario completo por medio de la id
    router
      .route("$urlBase/DeleteById/[:identy]")
      .link(() => UserConsult());

    //borra usuario completo por medio del nombre
    router
      .route("$urlBase/DeleteByName/[:nm]")
      .link(() => UserConsult());




    ////////////consulta con RuteroServer//////////////
    //consulta toda la base de datos
    router
      .route("$urlBase/[:idt]")
      .link(() => UserConsult());

    //consultar rutero por medio de su id
    router
      .route("$urlBase/GetRuteroByID/[:ident]")
      .link(() => UserConsult());

    //consultar rutero por su nombre
    router
      .route("$urlBase/GetRuteroByName/[:nm]")
      .link(() => UserConsult());





    // //ingresa un nuevo usuario si no existe (post)
    // router
    //   .route("$urlBase/CreateUser")
    //   .link(() => ServerConsult());




    // //consulta los datos del bus por nombre
    // router
    //   .route("$urlBase/ByName/[:name]")
    //   .link(() => BusConsult());

    // //consulta los datos del bus por IP publica
    // router
    //   .route("$urlBase/ByPublicIP/[:publicIP]")
    //   .link(() => BusConsult());

    // //consulta los datos del bus por IP compartida 
    // router
    //   .route("$urlBase/BySharedIP/[:sharedIP]")
    //   .link(() => BusConsult());

    

    

    // //elimina informacion de bus existente por medio de su nombre
    // router
    //   .route("$urlBase/DeleteBus/ByName/[:name]")
    //   .link(() => BusConsult());

    // //elimina informacion de bus existente por medio del ID
    // router
    //   .route("$urlBase/DeleteBus/ByID/[:id]")
    //   .link(() => BusConsult());


    

    

    return router;
  }
}