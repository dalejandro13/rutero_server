import 'package:tuple/tuple.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rutero_server/adminDB.dart';
import 'package:rutero_server/rutero_server.dart';
import 'dart:developer' as dev;

class UserConsult extends ResourceController {
  DbCollection globalCollUser;
  DbCollection globalCollServer;
  AdmonDB admon = AdmonDB();
  bool change = false;
  bool ready = false;
  UserConsult(){
    connectRuteros();
  }

  void connectRuteros() async {
    await admon.connectToRuteroServer().then((datab) {
      globalCollUser = datab.collection('Usuario');
      globalCollServer = datab.collection('RuteroServer');
    });   
  }

  //////////////////////////////para Usuarios/////////////////////////////////////////
  
  @Operation.get('id')
  Future<Response> getUser(@Bind.path('id') String id) async {
    try{
      var busesList = [];
      await globalCollUser.find().forEach((bus) {
        if(bus['_id'] == ObjectId.fromHexString(id) || bus['_id'] == id){
          if(bus['ruteros'].length != 0){
            // ignore: prefer_foreach
            for(var val in bus['ruteros']){
              busesList.add(val);
            }
          }
        }
      });

      if(busesList.length > 0){
        await admon.close();
        return Response.ok(busesList);
      }
      else{
        await admon.close();
        return Response.badRequest(body: {'ERROR':'Este cliente no tiene ruteros registrados en el sistema'});
      }
    }
    catch(e){
      print("ERROR ${e.toString()}");
      await admon.close();
      return Response.badRequest(body: {"ERROR": e.toString()});
    }
  }

  @Operation.get('name')
  Future<Response> getByName(@Bind.path('name') String name) async {
    try{
      var busesList = [];
      await globalCollUser.find().forEach((bus) {
        if(bus['name'] == name){
          if(bus['ruteros'].length != 0){
            // ignore: prefer_foreach
            for(var value in bus['ruteros']){
              busesList.add(value);
            }
          }
        }
      });
      if(busesList.length > 0){
        await admon.close();
        return Response.ok(busesList);
      }
      else{
        await admon.close();
        return Response.badRequest(body: {'ERROR': 'Este cliente no tiene ruteros registrados en el sistema'});
      }
      
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"ERROR": e.toString()});
    }
  }

  @Operation.post() //ingresar un nuevo Id de usuario si no existe
  Future<Response> createClient() async{
    try{
      final Map<String, dynamic> body1 = await request.body.decode();
      final name = body1['name'];
      final ruteros = body1['ruteros'];
      bool repeat = false;

      if(name != null && ruteros != null){
        if(name != "" && ruteros != ""){
          if(ruteros.length == 0){
            await globalCollUser.find().forEach((bus) async {
              if(bus['name'] == name){
                repeat = true;
              }
            });

            if(!repeat){
              String mens; 
              await globalCollUser.insert(body1);
              await globalCollUser.find().forEach((data) {
                bool capture = false;
                String acum = '';
                var aa = data['_id'].toString();
                for(int i = 0; i < aa.length; i++){
                  if(aa[i] == '('){
                    capture = true;
                  }
                  else if (aa[i] == ')'){
                    capture = false;
                  }

                  if(capture && aa[i] != '(' && aa[i] != ')' && aa[i] != '\"'){
                    acum += aa[i];
                  }
                }
                mens = acum.trim();
              });
              
              var resp = await insertToServerData(body1, repeat, mens);
              if(resp == true){
                await admon.close();
                return Response.ok(body1);
              }
              else{
                await admon.close();
                return Response.badRequest(body: {"ERROR": "datos no insertados en RuteroServer"});
              }
            }
            else{
              await admon.close();
              return Response.badRequest(body: {"ERROR": "Ya existe un cliente con el mismo nombre"});
            }
          }
          else{
             await admon.close();
             return Response.badRequest(body: {"ERROR": "El campo ruteros no debe tener ningun valor"});
          }
        }
        else{
          await admon.close();
          return Response.badRequest(body: {"ERROR": "un campo esta vacio, verifica nuevamente la informacion"});
        }
        
      }
      else{
        await admon.close();
        return Response.badRequest(body: {"ERROR": "un campo esta nulo, verifica nuevamente la informacion"});
      }

    }
    catch(e){
      print("ERROR: ${e.toString()}");
      await admon.close();
      return Response.badRequest(body: {"ERROR": e.toString()});
    }
  }

  @Operation.put('nameorid') //ingresa datos de los ruteros a los clientes por nombre o por id
  Future<Response> updateDataBus(@Bind.path('nameorid') String nmOrId) async {
    try{
      
      final Map<String, dynamic> body = await request.body.decode();
      ObjectId objectId = ObjectId();
      final name = body['name'];
      final chasis = body['chasis'];
      final pmr = body['PMR'];
      final routeIndex = body['routeIndex'];
      final status = body['status'];
      final publicIP = body['publicIP'];
      final sharedIP = body['sharedIP'];
      final version = body['version'];
      final appVersion = body['appVersion'];
      final panic = body['panic'];
      final routes = body['routes'];
      ready = false;

      Map<String, dynamic> newBody = {
        'id': objectId,
        'name': name,
        'chasis': chasis,
        'PMR': pmr,
        'routeIndex': routeIndex,
        'status': status,
        'publicIP': publicIP,
        'sharedIP': sharedIP,
        'version': version,
        'appVersion': appVersion,
        'panic': panic,
        'routes': routes,
      };      

      if(name != "" && chasis != "" && pmr != "" && routeIndex != "" && status != "" && publicIP != "" && sharedIP != "" && version != "" && appVersion != "" && panic != "" && routes != ""){
        if(name != null && chasis != null && pmr != null && routeIndex != null && status != null && publicIP != null && sharedIP != null && version != null && appVersion != null && panic != null && routes != null){
            await globalCollUser.find().forEach((data) async {
              if(data['name'] == nmOrId || data['_id'] == ObjectId.fromHexString(nmOrId) || data['_id'] == nmOrId){
                ready = true;
              }
            });

            if(ready){
              var value = await globalCollUser.findOne({"name": nmOrId });
              if(value != null){
                var value2 = value['ruteros'];
                if(value2 != null){
                  var rut = value2;
                  rut.add(newBody);
                  value2 = rut;
                  await globalCollUser.save(value); //no olvidar descomentar esto
                }
                else{
                  await globalCollUser.find().forEach((data) async {
                    if(data['name'] == nmOrId){
                      var rut = data['ruteros'];
                      rut.add(newBody);
                      data['ruteros'] = rut;
                      await globalCollUser.save(data); //no olvidar descomentar esto
                    }
                  });
                }
              }
              else{
                var value = await globalCollUser.findOne({"_id": ObjectId.fromHexString(nmOrId)});
                if(value != null){
                  var value2 = value['ruteros'];
                  if(value2 != null){
                    var rut = value2;
                    rut.add(newBody);
                    value2 = rut;
                    await globalCollUser.save(value);
                  }
                  else{
                    await globalCollUser.find().forEach((data) async {
                      if(data['_id'] == ObjectId.fromHexString(nmOrId) || data['_id'] == nmOrId){
                        var rut = data['ruteros'];
                        rut.add(newBody);
                        data['ruteros'] = rut;
                        await globalCollUser.save(data);
                      }
                    });
                  }
                }
              }

              var result = await insertInfoRuteroInServer(newBody, ready, nmOrId, objectId);

              if(result.item1){
                await admon.close();
                return Response.ok(result.item2);
              }
              else{
                await admon.close();
                return Response.badRequest(body: {"ERROR": "los datos no se pudieron guardar, intentalo nuevamente"});
              }
            }
            else{
              await admon.close();
              return Response.badRequest(body: {"ERROR": "El cliente no se encuentra registrado en la base de datos"});
            }
          }
          else{
            await admon.close();
            return Response.badRequest(body: {"ERROR": "un dato esta nulo, verifica nuevamente la informacion"});
          }
        }
        else{
          await admon.close();
          return Response.badRequest(body: {"ERROR": "falta llenar un dato, verifica nuevamente la informacion"});
        }
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"ERROR": e.toString()});
    }
  }

  @Operation.put('idupdate') //actualiza la informacion que esta dentro de ruteros
  Future<Response> updateDataRuteros(@Bind.path('idupdate') String idUpdate) async {
    try{
      Map<String, dynamic> newBody;
      final Map<String, dynamic> body = await request.body.decode();
      final name = body['name'];
      final chasis = body['chasis'];
      final pmr = body['PMR'];
      final routeIndex = body['routeIndex'];
      final status = body['status'];
      final publicIP = body['publicIP'];
      final sharedIP = body['sharedIP'];
      final version = body['version'];
      final appVersion = body['appVersion'];
      final panic = body['panic'];
      final routes = body['routes'];
      ready = false;

      if(name != "" && chasis != "" && pmr != "" && routeIndex != "" && status != "" && publicIP != "" && sharedIP != "" && version != "" && appVersion != "" && panic != "" && routes != ""){
        if(name != null && chasis != null && pmr != null && routeIndex != null && status != null && publicIP != null && sharedIP != null && version != null && appVersion != null && panic != null && routes != null){

          await globalCollUser.find().forEach((data) async {
            if(data['ruteros'] != null && data['ruteros'].length != 0){
              for(var val in data['ruteros']){
                if(val['id'] == ObjectId.fromHexString(idUpdate) || val['id'] == idUpdate){
                  dynamic ind;
                  newBody = {
                    'id': ObjectId.fromHexString(idUpdate),
                    'name': name,
                    'chasis': chasis,
                    'PMR': pmr,
                    'routeIndex': routeIndex,
                    'status': status,
                    'publicIP': publicIP,
                    'sharedIP': sharedIP,
                    'version': version,
                    'appVersion': appVersion,
                    'panic': panic,
                    'routes': routes,
                  };

                  try{
                    var value2 = data['ruteros'];
                    value2.forEach((k){
                      if(val['id'] == k['id']){
                        ind = value2.indexOf(k);                        
                      }
                    });

                    value2.removeAt(ind);

                    if(value2 != null){
                      var rut = value2;
                      rut.add(newBody);
                      val = rut;
                      ready = true;
                      await globalCollUser.save(data);
                    }
                  }
                  catch(e){
                    ready = false;
                    print(e);
                  }
                }
              }
            }
          });
          
          if(ready){
            await updateRuterosInToServer(newBody, idUpdate);
            await admon.close();
            return Response.ok(newBody);
          }
          else{
            await admon.close();
            return Response.badRequest(body: {"ERROR": "Este rutero no existe en la base de datos"});
          }

        }
        else{
          await admon.close();
          return Response.badRequest(body: {"ERROR": "un dato esta nulo, verifica nuevamente la informacion"});
        }
      }
      else{
        await admon.close();
        return Response.badRequest(body: {"ERROR": "falta llenar un dato, verifica nuevamente la informacion"});
      }
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"ERROR": e.toString()});
    }
  }

  @Operation.delete('DeleteRuterosId') //borra el rutero por medio de la id
  Future<Response> deleteRuteroForId(@Bind.path('DeleteRuterosId') String idDelete) async {
    try{
      dynamic ind;
      ready = false;
      await globalCollUser.find().forEach((data) async {
        for(var value in data['ruteros']){
          if(value['id'] == ObjectId.fromHexString(idDelete) || value['id'] == idDelete) {
            var vl = data['ruteros'];
            vl.forEach((k){
              if(k['id'] == ObjectId.fromHexString(idDelete)){
                ind = vl.indexOf(k);                    
              }
            });

            vl.removeAt(ind);

            if(vl != null){
              var rut = vl;
              value = rut;
              ready = true;
              await globalCollUser.save(data);
            }            
          }
        }
      });

      if(ready){
        await eraseRuteroInServer(idDelete);
        await admon.close();
        return Response.ok("OK: la informacion ha sido borrada exitosamente");
      }
      else{
        await admon.close();
        return Response.badRequest(body: {"ERROR":"la informacion no se pudo borrar, verifica nuevamente la informacion"});
      }
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"ERROR": e.toString()});
    }
  }

  @Operation.delete('DeleteClientKey') //borra el cliente por medio de la id
  Future<Response> deleteClientForId(@Bind.path('DeleteClientKey') String keyDelete) async {
    dynamic ind;
    ready = false;
    int decision = 0;
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
            }
          }
        }
      });

      if(ready){
        if(decision == 1){
          await globalCollUser.remove(await globalCollUser.findOne({'_id': ObjectId.fromHexString(keyDelete)})); //borra en base de datos Usuarios por medio de su id
        }
        else if (decision == 2){
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

  //////////////////////////////////para servidor//////////////////////////////////////
  
  @Operation.get('num') //consulta todo el servidor o consulta todos los clientes
  Future<Response> getAllClients(@Bind.path('num') String number) async {
    try{
      var busesList = [];
      if(number == "0"){
        await globalCollServer.find().forEach(busesList.add);
      }
      else if(number == "1"){
        await globalCollUser.find().forEach(busesList.add);
      }
      
      if(busesList.length > 0){
        await admon.close();
        return Response.ok(busesList);
      }
      else{
        await admon.close();
        return Response.badRequest(body: {"ERROR": "No hay informacion en Usuarios"});
      }
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"ERROR": e.toString()});
    }
  }

  @Operation.get('ident') //consulta un rutero en especifico por medio de su id
  Future<Response> getInfoRutero(@Bind.path('ident') String id) async {
    try{
      var busesList = [];
      await globalCollServer.find().forEach((bus) {
        for(var value in bus['users']){
          for(var value2 in value['ruteros']){
            if(value2['id'] == ObjectId.fromHexString(id)){
              busesList.add(value2);
            }
          }
        }
      });

      if(busesList.length > 0){
        await admon.close();
        return Response.ok(busesList);
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

  // @Operation.get('nm') //buscar ruteros por nombre del cliente o por el id del cliente
  // Future<Response> getByNameServer(@Bind.path('nm') String nameOrId) async {
  //   try{
  //     var busesList = [];
  //     await globalCollServer.find().forEach((bus) {
  //       // ignore: prefer_foreach
  //       for(var value in bus['users']){
  //         for(var value2 in value['ruteros']){
  //           if(value['name'] == nameOrId || value['id'] == ObjectId.fromHexString(nameOrId) || value['id'] == nameOrId){
  //             busesList.add(value2);
  //           }
  //         }       
  //       }
  //     });

  //     if(busesList.length > 0){
  //       await admon.close();
  //       return Response.ok(busesList);
  //     }
  //     else{
  //       await admon.close();
  //       return Response.badRequest(body: {'ERROR':'No se pudieron encontrar elementos para retornar'});
  //     }
      
  //   }
  //   catch(e){
  //     await admon.close();
  //     return Response.badRequest(body: {"ERROR": e.toString()});
  //   }
  // }

  /////////////////////////////////////////////////////////////////////////////////////
  ///
  Future<bool> insertToServerData(Map<String, dynamic> body, bool repeat, String mens) async {
    ready = false;
    try{
      if(body['name'] != "" && body['ruteros'] != ""){
        if(!repeat){

          Map<String, dynamic> newBody = {
            'id': mens,
            'name': body['name'],
            'ruteros': body['ruteros'],
          };

          var value = await globalCollServer.findOne({"users": []});
          if(value != null){
            var rut = value['users'];
            rut.add(newBody);
            value['users'] = rut;
            await globalCollServer.save(value);
            ready = true;
          }
          else{
            await globalCollServer.find().forEach((data) async {
              var rut = data['users'];
              rut.add(newBody);
              data['users'] = rut;
              await globalCollServer.save(data);
            });
            ready = true;
          }

          if(ready){
            return ready; //true
          }
          else{
            return ready; //false
          }
        }
      }
      else{
        return false;
      }
    }
    catch(e){
      return false;
    }
  }

  Future<Tuple2<bool, Map<String, dynamic>>> insertInfoRuteroInServer(Map<String, dynamic> body, bool start, String nameClient, ObjectId objectId) async {
    ready = false;
    Map<String, dynamic> newBody;
    try{
      await globalCollServer.find().forEach((data) {
        for(var vl in data['users']){
          if(vl['name'] == nameClient || vl['id'] == nameClient){
            newBody = {
              'id': objectId,
              'name': body['name'],
              'chasis': body['chasis'],
              'PMR': body['PMR'],
              'routeIndex': body['routeIndex'],
              'status': body['status'],
              'publicIP': body['publicIP'],
              'sharedIP': body['sharedIP'],
              'version': body['version'],
              'appVersion': body['appVersion'],
              'panic': body['panic'],
              'routes': body['routes'],
            };
          }
        }
      });

      await globalCollServer.find().forEach((value) async {
        for(var val in value['users']){
          if(val['name'] == nameClient || val['id'] == nameClient){
            var rut = val['ruteros'];
            rut.add(newBody);
            val['ruteros'] = rut;
            ready = true;
            await globalCollServer.save(value);
          }
        }
      });

      if(ready){
        return Tuple2(ready, newBody);
      }
      else{
        return Tuple2(false, newBody);
      }
    }
    catch(e){
      return Tuple2(false, newBody);
    }
  }

  Future<void> updateRuterosInToServer(Map<String, dynamic> newBody, String idUpdate) async {
    try{
      Map<String, dynamic> newBody2;
      await globalCollServer.find().forEach((data) async {
        for(var value in data['users']){
          for(var value2 in value['ruteros']){
            if(value2['id'] == ObjectId.fromHexString(idUpdate) || value2['id'] == idUpdate){
              dynamic ind;
              newBody2 = {
                'id': ObjectId.fromHexString(idUpdate),
                'name': newBody['name'],
                'chasis': newBody['chasis'],
                'PMR': newBody['PMR'],
                'routeIndex': newBody['routeIndex'],
                'status': newBody['status'],
                'publicIP': newBody['publicIP'],
                'sharedIP': newBody['sharedIP'],
                'version': newBody['version'],
                'appVersion': newBody['appVersion'],
                'panic': newBody['panic'],
                'routes': newBody['routes'],
              };

              var value3 = value['ruteros'];
              value3.forEach((k){
                if(value2['id'] == k['id']){
                  ind = value3.indexOf(k);                        
                }
              });

              value3.removeAt(ind);

              if(value3 != null){
                var rut = value3;
                rut.add(newBody);
                value3 = rut;
                await globalCollServer.save(data);
              }
            }
          }
        }
      });
    }
    catch(e){
      print(e);
    }
  }

  Future<bool> eraseRuteroInServer(String idDelete) async{
    try{
      bool save = false;
      await globalCollServer.find().forEach((data) async {
        for(var value in data['users']){
          for(var value2 in value['ruteros']){
            if(value2['id'] == ObjectId.fromHexString(idDelete)) {
              dynamic ind;
              var value3 = value['ruteros'];
              value3.forEach((k){
                if(value2['id'] == k['id']){
                  ind = value3.indexOf(k);                        
                }
              });

              value3.removeAt(ind);

              if(value3 != null){
                var rut = value3;
                value3 = rut;
                save = true;
                await globalCollServer.save(data);
              }                
            }
          }
        }
      });

      if(save){
        return save;
      }
      else{
        return save;
      }
      
    }
    catch(e){
      return false;
    }
  }
}