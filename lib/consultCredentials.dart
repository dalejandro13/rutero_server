import 'package:tuple/tuple.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rutero_server/adminDB.dart';
import 'package:rutero_server/rutero_server.dart';

class ConsultCredentials extends ResourceController{
  DbCollection globalCollCredentials, globalCollServer, globalCollUser, globalCollDevice;
  AdmonDB admon = AdmonDB();
  bool start = false;

  ConsultCredentials(){
    connectCredentials();
  }

  void connectCredentials() async {
    await admon.connectToRuteroServer().then((datab) {
      //globalCollUser = datab.collection('user');
      globalCollServer = datab.collection('serverApp');
      globalCollDevice = datab.collection('device');
      globalCollCredentials = datab.collection('credentials');
    });   
  }

  @Operation.get('NameDevice') //consultar la credencial del dispositivo con su nombre
  Future<Response> getDataIncredentials(@Bind.path('NameDevice') String name) async {
    try{
      List<dynamic> dataCredentials = null;
      dataCredentials = [];
      await globalCollCredentials.find().forEach((data) {
        if(data['deviceName'].toLowerCase().trim() == name.toLowerCase().trim()){
          dataCredentials.add(data);
        }
      });

      if(dataCredentials.isNotEmpty){
        await admon.close();
        return Response.ok(dataCredentials);
      }
      else{
        await admon.close();
        return Response.badRequest(body: {'ERROR':'Este dispositivo no tiene credenciales en la base de datos'});
      }
    }
    catch(e){
      print("Error $e"); 
      await admon.close();
      return Response.badRequest(body: {'ERROR': e.toString()});
    }
  }

  @Operation.get() //consultar la credencial del dispositivo con su nombre
  Future<Response> getAllCredentials() async {
    try{
      List<dynamic> listCredentials = null;
      listCredentials = [];
      await globalCollCredentials.find().forEach(listCredentials.add);
      
      if(listCredentials.isNotEmpty){
        await admon.close();
        return Response.ok(listCredentials);
      }
      else{
        await admon.close();
        return Response.badRequest(body: {"ERROR": "No hay credenciales en la base de datos"});
      }
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {'ERROR': e.toString()});
    }
  }

  @Operation.put('idDevice') //actualiza la informacion de las credenciales
  Future<Response> putDataRuteros(@Bind.path('idDevice') String ident) async {
    try{
      Map<String, dynamic> newBody = null;
      start = false;
      await globalCollServer.find().forEach((data) async {
        if(data['version'] != "" && data['appVersion'] != "" && data['version'] != null && data['appVersion'] != null){
          start = true;
        }
      });

      if(start){
        final Map<String, dynamic> body = await request.body.decode();
        if(body['ssid'] != "" && body['pass'] != ""){
          if(body['ssid'] != null && body['pass'] != null){
            await globalCollCredentials.find().forEach((data) async {
              if(ObjectId.fromHexString(ident) == data['_id']){
                newBody = {
                  "_id": data['_id'],
                  "deviceName": data['deviceName'],
                  "networkInterface": {"ssid": body['ssid'],"pass": body['pass']},
                  "frontal": {"ssid": body['ssid'], "pass": body['pass']},
                  "lateral": {"ssid": body['ssid'], "pass": body['pass']},
                  "posterior": {"ssid": body['ssid'], "pass": body['pass']}
                };
              }
            });

            if(newBody != null){
              await globalCollCredentials.remove(where.eq('_id', ObjectId.fromHexString(ident))); //await globalCollCredentials.findOne({'_id': ident}));
              await globalCollCredentials.save(newBody);
              await admon.close();
              return Response.ok(newBody);
            }
            else{
              return Response.badRequest(body: {"ERROR": "este rutero no existe en la base de datos, verifica nuevamente la informacion"});
            }
          }
          else{
            await admon.close();
            return Response.badRequest(body: {"ERROR": "uno o ambos campos son nulos, verifica nuevamente"});
          }
        }
        else{
          await admon.close();
          return Response.badRequest(body: {"ERROR": "falta un campo por completar, verifica nuevamente"});
        }
      }
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"ERROR": e.toString()});
    }
  }

  @Operation.post('newName') //ingresa datos de ruteros nuevos a los clientes que ya existan en la base de datos, ya sea por su nombre o por su id
  Future<Response> createDataRuteros(@Bind.path('newName') String newName) async {
    try{
      await globalCollDevice.find().forEach((data) async {
        for(var vv in data['ruteros']){
          if(vv['name'] == newName){
            //CONTINUA ACA
          }
        }
        return Response.ok("ingresando nuevas credenciales: $newName");
      });
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"ERROR": e.toString()});
    }
  }

}