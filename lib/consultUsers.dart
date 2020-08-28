import 'package:aqueduct/aqueduct.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rutero_server/adminDB.dart';

class ConsultUsers extends ResourceController {
  DbCollection globalCollUser, globalCollServer, globalCollDevice;
  AdmonDB admon = AdmonDB();
  bool ready;
  int decision;

  ConsultUsers(){
    connectRuteros();
  }

  void connectRuteros() async {
    await admon.connectToRuteroServer().then((datab) {
      globalCollUser = datab.collection('user');
      globalCollServer = datab.collection('serverApp');
      globalCollDevice = datab.collection('device');
    });   
  }

  @Operation.get() //consulta todos los usuarios
  Future<Response> getusers() async { //@Bind.path('getusers') String user) async {
    try{
      var listUsers = [];
      await globalCollUser.find().forEach((data) {
        listUsers.add(data);
      });

      if(listUsers.length > 0){
        await admon.close();
        return Response.ok(listUsers);
      }
      else{
        await admon.close();
        return Response.badRequest(body: {"ERROR":"No se encontro informacion, verifica la nuevamente"});
      }
    }
    catch(e){
      print("ERROR ${e.toString()}");
      await admon.close();
      return Response.badRequest(body: {"ERROR": e.toString()});
    }
  }

  @Operation.delete('deleteuserkey') //borra el cliente por medio de la id o por el nombre
  Future<Response> deleteClientForId(@Bind.path('deleteuserkey') String keyDelete) async {
    dynamic ind;
    ready = false;
    decision = 0;
    try{
      await globalCollServer.find().forEach((data) async {
        for(var result in data['users']){
          try{
            if(result['id'] == ObjectId.fromHexString(keyDelete) || result['id'] == keyDelete){
              ready = true;
              var vl = data['users'];
              vl.forEach((k){
                if(k['id'] == ObjectId.fromHexString(keyDelete) || k['id'] == keyDelete){
                  ind = vl.indexOf(k);                    
                }
              });

              vl.removeAt(ind);

              if(vl != null){
                var rut = vl;
                result = rut;
                ready = true;
                decision = 1;
                await globalCollServer.save(data); 
              }   
            }
          }
          catch(e){
            try{ 
              if(result['name'] == keyDelete){
                ready = true;
                var vl = data['users'];
                vl.forEach((k){
                  if(k['name'] == keyDelete){
                    ind = vl.indexOf(k);                    
                  }
                });

                vl.removeAt(ind);

                if(vl != null){
                  var rut = vl;
                  result = rut;
                  ready = true;
                  decision = 2;
                  await globalCollServer.save(data);
                }
              }
            }
            catch(e){
              print('ERROR: $e');
              await admon.close();
              return Response.badRequest(body: {"ERROR":"el cliente no se pudo borrar"});
            }
          }
        }
      });

      if(ready){
        if(decision == 1){
          await deleteInDeviceDb(keyDelete, decision);
          await globalCollUser.remove(await globalCollUser.findOne({'_id': ObjectId.fromHexString(keyDelete)})); //borra en base de datos Usuarios por medio de su id
          
        }
        else if (decision == 2){
          await deleteInDeviceDb(keyDelete, decision);
          await globalCollUser.remove(await globalCollUser.findOne({'name': keyDelete})); //borra en base de datos Usuarios por medio de su nombre
        }

        if(decision == 1 || decision == 2){
          await admon.close();
          return Response.ok("OK: el cliente ha sido borrado exitosamente");
        }
        else{
          await admon.close();
          return Response.badRequest(body: {"ERROR":"el cliente no existe en la base de datos"});
        }
      }
      else{
        await admon.close();
        return Response.badRequest(body: {"ERROR":"el cliente no existe en la base de datos"});
      }
    }
    catch(e){
      decision = 0;
      await admon.close();
      return Response.badRequest(body: {"ERROR": e.toString()});
    }
  }

  Future<void> deleteInDeviceDb(String keyDelete, int decision) async {
    var listOfId = [];
    dynamic ind;

    await globalCollUser.find().forEach((data) async {
      if(decision == 1){ //busqueda por id
        try{
          if(data['_id'] == ObjectId.fromHexString(keyDelete) || data['_id'] == keyDelete){
            var vl = data['ruteros'];
            vl.forEach((k){
              listOfId.add(k['id']);
            }); 
          }
        }
        catch(e){
          print('ERROR: $e');
          await admon.close();
        }
      }
      else if(decision == 2){ //busqueda por nombre
        try{ 
          if(data['name'] == keyDelete){
            var vl = data['ruteros'];
            vl.forEach((k){
              listOfId.add(k['id']);
            });
          }
        }
        catch(e){
          print('ERROR: $e');
          await admon.close();
        }
      }
    });

    if(listOfId.length > 0){
      int numb = 0;
      var value = await globalCollDevice.findOne({"ruteros":  [ ]});
      if(value == null){
        await eliminateId(listOfId, 0, ind);
      }
    }
  }

  Future<void> eliminateId(List<dynamic> listId, int i, dynamic ind) async{
    var id = listId[i];
    await globalCollDevice.find().forEach((data) async {
      try{
        var value2 = data['ruteros'];
        value2.forEach((k){
          if(id == k['id']){
            ind = value2.indexOf(k);                        
          }
        });

        value2.removeAt(ind);

        if(value2 != null){
          var rut = value2;
          value2 = rut;
          await globalCollDevice.save(data);
        }
      }
      catch(e){
        ready = false;
        print(e);
      }
    });

    i++;
    if(i < listId.length){
      await eliminateId(listId, i, ind);
    }
  }

}