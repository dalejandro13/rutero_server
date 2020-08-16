// import 'package:mongo_dart/mongo_dart.dart';
// import 'package:rutero_server/adminDB.dart';
import 'package:rutero_server/consultUsers.dart';
import 'package:rutero_server/consultServer.dart';
import 'package:rutero_server/consultDevice.dart';
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
  String urlBase, urlBase2;
  //AdmonDB admon = AdmonDB();
  //DbCollection globalCollUser, globalCollServer;

  RuteroServerChannel(){
    variables = Variables();
    urlBase = "Api/FlexoRuteros";
    //connectRuteros();
    //"http://localhost:9742/Api/FlexoRuteros/Buses/GetAllDevices/[:idDevice]"
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

    //consulta con todos los usuarios
    router
      .route("$urlBase/Users")
      .link(() => ConsultUsers());
    
    //consultar todos los ruteros en device
    router
      .route("$urlBase/Devices") //LISTO
      .link(() => ConsultDevices());
        
    //consultar todos los ruteros con id de empresa
    router
      .route("$urlBase/Devices/GetUserID/[:id]") //LISTO
      .link(() => ConsultDevices());
    
    //consultar todos los ruteros por el nombre de la empresa
    router
      .route("$urlBase/Devices/GetByUserName/[:name]") //LISTO
      .link(() => ConsultDevices());

    // ingresa un nuevo usuario si no existe (post)
    router
      .route("$urlBase/Users/CreateUsers") //LISTO
      .link(() => ConsultDevices());

    // insertar un nuevo rutero, si el nombre o la id coincide con el del usuario almacenado en la base de datos (post)
    router
      .route("$urlBase/Devices/CreateInUser/[:nameorid]") //LISTO
      .link(() => ConsultDevices());

    // actualizar informacion acerca de los ruteros (put)
    router
      .route("$urlBase/Devices/UpdateDevices/[:idupdate]") //LISTO
      .link(() => ConsultDevices());

    // borra rutero por medio de su id (delete)
    router
      .route("$urlBase/Devices/DeleteDevices/[:DeleteRuteroId]") //LISTO
      .link(() => ConsultDevices());

    // borra el cliente por medio su id o por su nombre (delete)
    router
      .route("$urlBase/Users/Delete/[:DeleteUserKey]") //SEGUIR PROBANDO
      .link(() => ConsultUsers());

    // actualiza la version
    router
      .route("$urlBase/Version") //LISTO
      .link(() => ConsultServer());

    ////////////consulta con RuteroServer//////////////
    //consulta toda la base de datos
    router
      .route("$urlBase")
      .link(() => ConsultServer());

    // consultar rutero especifico por medio de su id
    router
      .route("$urlBase/Devices/ID/[:ident]")
      .link(() => ConsultDevices());

    return router;
  }
}