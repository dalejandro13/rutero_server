import 'package:mongo_dart/mongo_dart.dart';
import 'package:rutero_server/adminDB.dart';
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
      .route("$urlBase/GetRuterosByID/[:id]")
      .link(() => UserConsult());
    
    //consultar todos los ruteros por el nombre de la empresa
    router
      .route("$urlBase/GetRuterosByName/[:name]")
      .link(() => UserConsult());

    //ingresa un nuevo cliente si no existe (post)
    router
      .route("$urlBase/CreateClient")
      .link(() => UserConsult());

    //insertar informacion en la lista de ruteros si el nombre o la id coincide (put)
    router
      .route("$urlBase/InsertDataRuteros/[:nameorid]")
      .link(() => UserConsult());

    //actualizar informacion acerca de los ruteros (put)
    router
      .route("$urlBase/UpdateDataRuteros/[:idupdate]")
      .link(() => UserConsult());

    //borra rutero por medio de su id (delete)
    router
      .route("$urlBase/DeleteRuterosById/[:DeleteRuterosId]")
      .link(() => UserConsult());

    //borra el cliente por medio su id o por su nombre (delete)
    router
      .route("$urlBase/DeleteClient/[:DeleteClientKey]")
      .link(() => UserConsult());

    ////////////consulta con RuteroServer//////////////
    //consulta toda la base de datos
    router
      .route("$urlBase/[:num]")
      .link(() => UserConsult());

    //consultar rutero especifico por medio de su id
    router
      .route("$urlBase/GetRutById/[:ident]") 
      .link(() => UserConsult());

    return router;
  }
}