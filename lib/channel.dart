// import 'package:mongo_dart/mongo_dart.dart';
// import 'package:rutero_server/adminDB.dart';
import 'package:rutero_server/consultCredentials.dart';
import 'package:rutero_server/consultUsers.dart';
import 'package:rutero_server/consultServer.dart';
import 'package:rutero_server/consultDevice.dart';
import 'package:rutero_server/variables.dart';
import 'rutero_server.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';


//181.140.181.103 -> NUEVA IP PUBLICA DEL SERVIDOR

/// This type initializes an application.
///
/// Override methods in this class to set up routes and initialize services like
/// database connections. See http://aqueduct.io/docs/http/channel/.


class RuteroServerChannel extends ApplicationChannel {

  Variables variables;
  String urlBase, urlBase2;

  RuteroServerChannel(){
    variables = Variables();
    urlBase = "Api/FlexoRuteros";
    //connectRuteros();
    //"http://localhost:9742/Api/FlexoRuteros/Buses/GetAllDevices/[:idDevice]"
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

    //consulta con todos los usuarios
    router
      .route("$urlBase/Users")
      .link(() => ConsultUsers());
    
    //consultar todos los ruteros en device
    router
      .route("$urlBase/Devices")
      .link(() => ConsultDevices());
        
    //consultar todos los ruteros con id del usuario
    router
      .route("$urlBase/Devices/GetUserID/[:id]")
      .link(() => ConsultDevices());
    
    //consultar todos los ruteros por el nombre del usuario
    router
      .route("$urlBase/Devices/GetByUserName/[:name]")
      .link(() => ConsultDevices());

    //consultar toda la informacion del usuario junto con los ruteros que tenga registrado
    router
      .route("$urlBase/Devices/ConsultInfoUser/[:nameClient]")
      .link(() => ConsultDevices());

    //ingresa un nuevo usuario si no existe (post)
    router
      .route("$urlBase/Users/CreateUsers")
      .link(() => ConsultDevices());

    //generar un nuevo rutero, si el nombre o la id coincide con el del usuario almacenado en la base de datos (post)
    router
      .route("$urlBase/Devices/CreateInUser/[:nameorid]")
      .link(() => ConsultDevices());

    //actualizar informacion acerca de los ruteros (put)
    router
      .route("$urlBase/Devices/UpdateDevices/[:idupdate]")
      .link(() => ConsultDevices());

    //ingresar o actualizar password y ftp en los usuarios de la base de datos con el nombre del usuario
    router
      .route("$urlBase/Users/UpdatePass/[:nameUser]")
      .link(() => ConsultDevices());

    //Elimina rutero por medio de su id (delete)
    router
      .route("$urlBase/Devices/DeleteDevices/[:deleteruteroid]")
      .link(() => ConsultDevices());

    //Elimina Usuario por medio su id ó por su nombre (delete)
    router
      .route("$urlBase/Users/Delete/[:deleteuserkey]")
      .link(() => ConsultUsers());

    //actualiza Version ó appVersion (put)
    router
      .route("$urlBase/Version")
      .link(() => ConsultServer());

    ////////////consulta con RuteroServer//////////////
    //consulta toda la base de datos
    router
      .route("$urlBase")
      .link(() => ConsultServer());

    //consultar rutero especifico por medio de su id
    router
      .route("$urlBase/Devices/ID/[:ident]")
      .link(() => ConsultDevices());

    //consultar rutero usando su nombre
    router
      .route("$urlBase/Devices/Name/[:NameDevice]")
      .link(() => ConsultDevices());

    //////////////consulta con las credenciales////////////
    //consulta las credenciales de un rutero en especifico
    router
      .route("$urlBase/Credentials/Name/[:NameDevice]")
      .link(() => ConsultCredentials());

    //consultar todas las credenciales de todos los ruteros
    router
      .route("$urlBase/Credentials")
      .link(() => ConsultCredentials());

    //actualiza la informacion de las credenciales con el nombre
    router
      .route("$urlBase/Credentials/UpdateByName/[:name]")
      .link(() => ConsultCredentials());

    //inserta en credenciales una nueva nueva informacion si el rutero existe
    router
      .route("$urlBase/Credentials/NewCredentials/[:newName]")
      .link(() => ConsultCredentials());

    //borra rutero solo en las credenciales
    router
      .route("$urlBase/Credentials/DeleteCredentials/[:name]")
      .link(() => ConsultCredentials());

    return router;
  }
}