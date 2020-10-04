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

  @Operation.put('name') //actualiza la informacion de las credenciales
  Future<Response> putDataRuteros(@Bind.path('name') String ident) async {
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
              //if(ObjectId.fromHexString(ident) == data['_id']){
              if(data['deviceName'] == ident){
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
              //await globalCollCredentials.remove(where.eq('_id', ObjectId.fromHexString(ident))); //await globalCollCredentials.findOne({'_id': ident}));
              await globalCollCredentials.remove(where.eq('deviceName', ident)); //await globalCollCredentials.findOne({'_id': ident}));
              await globalCollCredentials.save(newBody);
              await admon.close();
              return Response.ok(newBody);
            }
            else{
              await admon.close();
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

  @Operation.post('newName') //ingresa datos de ruteros nuevos a los clientes que ya existan en la base de datos, usando su nombre
  Future<Response> createDataRuteros(@Bind.path('newName') String newName) async {
    try{
      Map<String, dynamic> bodyRedWifi = null, bodyCredentials = null;
      bool enterData = true;
      start = false;
      await globalCollServer.find().forEach((data) async {
        if(data['version'] != "" && data['appVersion'] != "" && data['version'] != null && data['appVersion'] != null){
          start = true;
        }
      });

      if(start){
        await globalCollDevice.find().forEach((data) async { //consulta con la coleccion de device
          for(var vv in data['ruteros']){
            if(vv['name'] == newName){
              bodyRedWifi = {
                'ssid': '--',
                'pass': '--'
              };
              bodyCredentials = {
                '_id': vv['id'],
                'deviceName': newName,
                'networkInterface': bodyRedWifi,
                'frontal': bodyRedWifi,
                'lateral': bodyRedWifi,
                'posterior': bodyRedWifi,
              };
            }
          }
        });

        if(bodyCredentials != null){

          await globalCollCredentials.find().forEach((data) async {
            if(data["deviceName"] == newName){
              enterData = false;
            }
          });

          if(enterData){
            await globalCollCredentials.save(bodyCredentials);
            await admon.close();
            return Response.ok(bodyCredentials);
          }
          else{
            return Response.badRequest(body: {"ERROR": "el rutero $newName ya esta registrado en las credenciales, intenta con otro nombre de rutero"});
          }
        }
        else{
          await admon.close();
          return Response.badRequest(body: {"ERROR": "el rutero $newName no se encuentra en la base de datos, intenta con otro nombre de rutero"});
        }
      }
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"ERROR": e.toString()});
    }
  }

  @Operation.delete('name') //borra el rutero por medio de la id
  Future<Response> deleteRuteroForId(@Bind.path('name') String nameDelete) async {
    bool readyToDelete = false;
    try{
      await globalCollCredentials.find().forEach((data) async {
        if(data['deviceName'] == nameDelete){
          readyToDelete = true;
        }
      });

      if(readyToDelete){
        await globalCollCredentials.remove(where.eq('deviceName', nameDelete)); //borra el rutero de la coleccion de credenciales
        await admon.close();
        return Response.ok("el rutero $nameDelete ha sido borrado de credenciales");
      }
      else{
        await admon.close();
        return Response.badRequest(body: {"ERROR": "el rutero $nameDelete no existe en las credenciales"});
      }
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"ERROR": e.toString()});
    }
  }

}