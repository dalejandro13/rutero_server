import 'dart:convert';
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
  //bool change = false;
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
        return Response.badRequest(body: {'Error':'Este cliente no tiene ruteros registrados en el sistema'});
      }
    }
    catch(e){
      print("Error ${e.toString()}");
      await admon.close();
      return Response.badRequest(body: {"Error": e.toString()});
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
        return Response.badRequest(body: {'Error': 'No se encontro informacion en la base de datos'});
      }
      
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"Error": e.toString()});
    }
  }

  @Operation.post() //ingresar un nuevo Id de usuario si no existe
  Future<Response> createClient() async{
    try{
      final Map<String, dynamic> body = await request.body.decode();
      final name = body['name'];
      final ruteros = body['ruteros'];
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
              await globalCollUser.insert(body);
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
              
              var resp = await insertToServerData(body, repeat, mens);
              if(resp.body == true){
                await admon.close();
                return Response.ok(body);
              }
              else{
                await admon.close();
                return Response.badRequest(body: {"Error": "datos no insertados en RuteroServer"});
              }
            }
            else{
              await admon.close();
              return Response.badRequest(body: {"Error": "Ya existe un cliente con el mismo nombre"});
            }
          }
          else{
             await admon.close();
             return Response.badRequest(body: {"Error": "El campo ruteros no debe tener ningun valor"});
          }
        }
        else{
          await admon.close();
          return Response.badRequest(body: {"Error": "un campo esta vacio, verifica nuevamente la informacion"});
        }
        
      }
      else{
        await admon.close();
          return Response.badRequest(body: {"Error": "un campo esta nulo, verifica nuevamente la informacion"});
      }

    }
    catch(e){
      print("Error: ${e.toString()}");
      await admon.close();
      return Response.badRequest(body: {"Error": e.toString()});
    }
  }

  @Operation.put('nme') //ingresa datos de los ruteros a los clientes
  Future<Response> updateDataBus(@Bind.path('nme') String nm) async {
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
              if(data['name'] == nm || data['_id'] == ObjectId.fromHexString(nm) || data['_id'] == nm){
                ready = true;
              }
            });

            if(ready){
              var value = await globalCollUser.findOne({"name": nm });
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
                    if(data['name'] == nm){
                      var rut = data['ruteros'];
                      rut.add(newBody);
                      data['ruteros'] = rut;
                      await globalCollUser.save(data); //no olvidar descomentar esto
                    }
                  });
                }
              }
              else{
                var value = await globalCollUser.findOne({"_id": ObjectId.fromHexString(nm) });
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
                      if(data['_id'] == ObjectId.fromHexString(nm) || data['_id'] == nm){
                        var rut = data['ruteros'];
                        rut.add(newBody);
                        data['ruteros'] = rut;
                        await globalCollUser.save(data);
                      }
                    });
                  }
                }
              }

              var result = await insertInfoRuteroInServer(newBody, ready, nm, objectId);

              if(result.item1){
                await admon.close();
                return Response.ok(result.item2);
              }
              else{
                await admon.close();
                return Response.badRequest(body: {"info": "los datos no se pudieron guardar, intentalo nuevamente"});
              }
            }
            else{
              return Response.badRequest(body: {"Error": "El cliente no se encuentra registrado en la base de datos"});
            }
          }
          else{
            await admon.close();
            return Response.badRequest(body: {"Error": "un dato esta nulo, verifica nuevamente la informacion"});
          }
        }
        else{
          await admon.close();
          return Response.badRequest(body: {"Error": "falta llenar un dato, verifica nuevamente la informacion"});
        }
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"Error": e.toString()});
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
                      print(value2.indexOf(k));
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
                  // Map<String, dynamic> val1;
                  // if(val['name'] != name){
                  //   try{
                  //     print(val['name']);
                  //     print(val['name'].toString());
                  //     //await val.update(where.eq('name', val['name']), modify.set('name', name));
                  //     var val1 = await val.findOne({'name': val['name']});
                  //     //val1['name'] = val['name'];
                  //     await val.save(val['name']);
                  //   }
                  //   catch(e){
                  //     print("Error $e");
                  //   }
                  // }
                  // if(val['chasis'] != chasis){
                  //   //await val.update(where.eq('chasis', val['chasis']), modify.set('chasis', chasis));
                  //   val1 = await globalCollUser.findOne(where.eq('chasis', val['chasis']));
                  //   val.update(val1);
                  // }
                  // if(val['PMR'] != pmr){
                  //   //await val.update(where.eq('PMR', val['PMR']), modify.set('PMR', pmr));
                  //   val1 = await globalCollUser.findOne(where.eq('PMR', val['PMR']));
                  //   val.update(val1);
                  // }
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
            return Response.badRequest(body: {"Error": "Este rutero no existe en la base de datos"});
          }

        }
        else{
          await admon.close();
          return Response.badRequest(body: {"Error": "un dato esta nulo, verifica nuevamente la informacion"});
        }
      }
      else{
        await admon.close();
        return Response.badRequest(body: {"Error": "falta llenar un dato, verifica nuevamente la informacion"});
      }
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"Error": e.toString()});
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
              print(vl.indexOf(k));
              if(k['id'] == ObjectId.fromHexString(idDelete)){
                ind = vl.indexOf(k);                    
              }
            });

            vl.removeAt(ind);

            if(vl != null){
              var rut = vl;
              //rut.add(newBody);
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
        return Response.ok("info: la informacion ha sido borrada exitosamente");
      }
      else{
        await admon.close();
        return Response.badRequest(body: {"Error":"el dato no se pudo borrar, verifica nuevamente la informacion"});
      }
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"Error": e.toString()});
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
                print(vl.indexOf(k));
                if(k['id'] == ObjectId.fromHexString(keyDelete) || k['id'] == keyDelete){
                  ind = vl.indexOf(k);                    
                }
              });

              vl.removeAt(ind);

              if(vl != null){
                var rut = vl;
                //rut.add(newBody);
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
                  print(vl.indexOf(k));
                  if(k['name'] == keyDelete){
                    ind = vl.indexOf(k);                    
                  }
                });

                vl.removeAt(ind);

                if(vl != null){
                  var rut = vl;
                  //rut.add(newBody);
                  result = rut;
                  ready = true;
                  decision = 2;
                  await globalCollServer.save(data);
                }
              }
            }
            catch(e){
              print('Error: $e');
            }
          }
        }
      });

      if(ready){
        if(decision == 1){
          await globalCollUser.remove(await globalCollUser.findOne({'_id': ObjectId.fromHexString(keyDelete)}));
        }
        else if (decision == 2){
          await globalCollUser.remove(await globalCollUser.findOne({'name': keyDelete}));
        }

        if(decision == 1 || decision == 2){
          await admon.close();
          return Response.ok("info: el cliente ha sido borrado exitosamente");
        }
        else{
          await admon.close();
          return Response.badRequest(body: {"Error":"el cliente no existe en la base de datos"});
        }
      }
      else{
        await admon.close();
        return Response.badRequest(body: {"Error":"el cliente no existe en la base de datos"});
      }
    }
    catch(e){
      decision = 0;
      await admon.close();
      return Response.badRequest(body: {"Error": e.toString()});
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
      await admon.close();
      return Response.ok(busesList);
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"Error": e.toString()});
    }
  }

  @Operation.get('ident') //consulta un rutero en especifico por medio de su id
  Future<Response> getInfoRutero(@Bind.path('ident') String id) async {
    try{
      var busesList = [];
      await globalCollServer.find().forEach((bus) {
        for(var value in bus['users']){
          for(var value2 in value['ruteros']){
            if(value2['id'] == id){
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
        return Response.badRequest(body: {'Error':'No se pudieron encontrar elementos para retornar'});
      }
    }
    catch(e){
      print("Error ${e.toString()}");
      await admon.close();
      return Response.badRequest(body: {"Error": e.toString()});
    }
  }

  @Operation.get('nm') //buscar rutero por nombre
  Future<Response> getByNameServer(@Bind.path('nm') String name) async {
    try{
      var busesList = [];
      await globalCollServer.find().forEach((bus) {
        // ignore: prefer_foreach
        for(var value in bus['users']){
          for(var value2 in value['ruteros']){
            if(value2['name'] == name){
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
        return Response.badRequest(body: {'Error':'No se pudieron encontrar elementos para retornar'});
      }
      
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"Error": e.toString()});
    }
  }

  /////////////////////////////////////////////////////////////////////////////////////
  Future<Response> insertToServerData(Map<String, dynamic> body, bool repeat, String mens) async {
    try{
      ready = false;
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
            return Response.ok(ready); //true
          }
          else{
            return Response.ok(ready); //false
          }
        }
      }
      else{
        return Response.badRequest(body: {"Error": "un dato esta vacio, verifica nuevamente la informacion"});
      }
    }
    catch(e){
      return Response.badRequest(body: {"Error": e.toString()});
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
                print(value3.indexOf(k));
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
                //rut.add(newBody);
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

  Future<void> deleteClientInUsuario(String idDelete) async {
    try{
      
    }
    catch(e){
      print(e);
    }
  }

  Future<void> deleteClientInUsuario2(String nameDelete) async { //FALTA TERMINAR ACA
    try{
      dynamic ind;
      bool getData = true;
      dynamic store = [];
      Map<String, dynamic> data2;

      await globalCollUser.find().forEach((data) async {
        if(getData)
        {
          getData = false;
          data2 = data;
        }
        store.add(data);
      });

      // await globalCollUser.getIndexes().then((data) async {
      //   print('Se tiene: $data');
      // });

      store.forEach((element) {
        print(element); 
        print(store.indexOf(element));
        if(element['name'] == nameDelete){
          ind = store.indexOf(element);
        }
      });

      store.removeAt(ind);

      // data2 = {
      //   store,
      // };
      // print(data2);

      if(store != null){
        var rut = store;
        //rut.add(newBody);
        store = rut;
        ready = true;
        await globalCollUser.insert(data2);
      }  
    }
    catch(e){
      print(e);
    }
  }

}