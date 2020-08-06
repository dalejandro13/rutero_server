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
        if(bus['_id'] == ObjectId.fromHexString(id)){
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
        return Response.badRequest(body: {'Error':'No se pudieron encontrar elementos para retornar'});
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
        return Response.badRequest(body: {'Error': 'No se encontraron elementos para retornar'});
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
            return Response.badRequest(body: {"Error": "Ya existe un bus con el mismo nombre"});
          }
        }
        else{
          await admon.close();
          return Response.badRequest(body: {"Error": "un dato esta vacio, verifica nuevamente la informacion"});
        }
      }
      else{
        await admon.close();
          return Response.badRequest(body: {"Error": "un dato esta nulo, verifica nuevamente la informacion"});
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
              if(data['name'] == nm || data['_id'] == ObjectId.fromHexString(nm)){
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
                      if(data['_id'] == ObjectId.fromHexString(nm)){
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
                return Response.ok(result.item2);
              }
              else{
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
                if(val['id'] == ObjectId.fromHexString(idUpdate)){
                  ready = true;
                  // newBody = {
                  //   'id': idUpdate,
                  //   'name': name,
                  //   'chasis': chasis,
                  //   'PMR': pmr,
                  //   'routeIndex': routeIndex,
                  //   'status': status,
                  //   'publicIP': publicIP,
                  //   'sharedIP': sharedIP,
                  //   'version': version,
                  //   'appVersion': appVersion,
                  //   'panic': panic,
                  //   'routes': routes,
                  // };
                  // print(newBody);

                  // var value2 = data['ruteros'];
                  // if(value2 != null){
                  //   int count = 0;
                  //   var rut = value2;
                    
                  //   rut.add(newBody);
                  //   val = rut;
                  //   await globalCollUser.save(data);
                  // }

                  Map<String, dynamic> val1;
                  if(val['name'] != name){
                    try{
                      print(val['name']);
                      print(val['name'].toString());
                      //await val.update(where.eq('name', val['name']), modify.set('name', name));
                      var val1 = await globalCollUser.findOne({'ruteros': });
                      val1['name'] = val['name'];
                      await val.save(val1);
                    }
                    catch(e){
                      print("Error $e");
                    }
                  }
                  if(val['chasis'] != chasis){
                    //await val.update(where.eq('chasis', val['chasis']), modify.set('chasis', chasis));
                    val1 = await globalCollUser.findOne(where.eq('chasis', val['chasis']));
                    val.update(val1);
                  }
                  if(val['PMR'] != pmr){
                    //await val.update(where.eq('PMR', val['PMR']), modify.set('PMR', pmr));
                    val1 = await globalCollUser.findOne(where.eq('PMR', val['PMR']));
                    val.update(val1);
                  }
                  if(val['routeIndex'] != routeIndex){
                    
                  }
                  if(val['status'] != status){
                    
                  }
                  if(val['publicIP'] != publicIP){
                    
                  }
                  if(val['sharedIP'] != sharedIP){
                    
                  }
                  if(val['version'] != version){
                    
                  }
                  if(val['appVersion'] != appVersion){
                    
                  }
                  if(val['panic'] != panic){
                    
                  }
                  if(val['routes'] != routes){
                    
                  }

                  // for(var dt in rut){
                  //   if(dt['id'] == ObjectId.fromHexString(idUpdate)){
                  //     rut.removeAt(0);
                  //   }
                  //   count++;
                  // }

                }
              }
            }
          });

          bool result = await updateRuterosInToServer(newBody, idUpdate);

          if(result){
            return Response.ok("la informacion ha sido actualizada exitosamente");
          }
          else{
            return Response.badRequest(body: {"Error": "no hay informacion con este identificador"});
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








  @Operation.delete('DeleteRuterosId')
  Future<Response> deleteRuteroForId(@Bind.path('DeleteRuterosId') String idDelete) async {
    try{
      //change = false;
      await globalCollUser.find().forEach((data) async {
        for(var value in data['ruteros']){
          if(data['id'] == ObjectId.fromHexString(idDelete)) {
            var val1 = await globalCollUser.findOne(where.eq('name', value['name']));
            var val2 = await globalCollUser.findOne(where.eq('chasis', value['chasis']));
            var val3 = await globalCollUser.findOne(where.eq('PMR', value['PMR']));
            var val4 = await globalCollUser.findOne(where.eq('routeIndex', value['routeIndex']));
            var val5 = await globalCollUser.findOne(where.eq('status', value['status']));
            var val6 = await globalCollUser.findOne(where.eq('publicIP', value['publicIP']));
            var val7 = await globalCollUser.findOne(where.eq('sharedIP', value['sharedIP']));
            var val8 = await globalCollUser.findOne(where.eq('version', value['version']));
            var val9 = await globalCollUser.findOne(where.eq('appVersion', value['appVersion']));
            var val10 = await globalCollUser.findOne(where.eq('panic', value['panic']));
            var val11 = await globalCollUser.findOne(where.eq('routes', value['routes']));
            await globalCollUser.remove(val1);
            await globalCollUser.remove(val2);
            await globalCollUser.remove(val3);
            await globalCollUser.remove(val4);
            await globalCollUser.remove(val5);
            await globalCollUser.remove(val6);
            await globalCollUser.remove(val7);
            await globalCollUser.remove(val8);
            await globalCollUser.remove(val9);
            await globalCollUser.remove(val10);
            await globalCollUser.remove(val11);
            
          }
        }
      });

      bool result = await eraseRuteroInServer(idDelete);

      if(result){
        await admon.close();
        return Response.ok("info: la informacion ha sido borrada exitosamente");
      }
      else{
        await admon.close();
        return Response.badRequest(body: {"Error":"el dato no se pudo borrar, verifica nuevamente la informacion"});
      }


      // if(change == true){
      //   var val = await globalCollUser.findOne({"ruteros": []});
      //   if(val != null){
          
      //   }
      //   else{
      //     await globalCollUser.find().forEach((data) async {
      //       for(var value in data['ruteros']){
      //         if(data['id'] == ObjectId.fromHexString(idDelete)) {
      //           var val1 = await globalCollUser.findOne(where.eq('name', value['name']));
      //           var val2 = await globalCollUser.findOne(where.eq('chasis', value['chasis']));
      //           await globalCollUser.remove(val1);

      //         }
      //       }
      //     });
      //   }
      // }
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"Error": e.toString()});
    }
  }


  @Operation.delete('DeleteClientId')
  Future<Response> deleteClientForId(@Bind.path('DeleteClientId') String idDelete) async {
    try{

    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"Error": e.toString()});
    }
  }


  // @Operation.delete('nameForDelete')
  // Future<Response> deleteDataBus(@Bind.path('nameForDelete') String nm) async {
  //   try{

  //     change = false;
  //     await globalCollUser.find().forEach((bus) {
  //       if(bus['name'] == nm) {
  //         change = true;
  //       }
  //     });

  //     if(change){
  //       var val = await globalCollUser.findOne(where.eq('name', nm));
  //       await globalCollUser.remove(val);
  //       return Response.ok("info: la informacion ha sido borrada exitosamente");
  //     }
  //     else{
  //       return Response.badRequest(body: {"Error":"el dato no se pudo borrar, verifica nuevamente la informacion"});
  //     }
      
  //   }
  //   catch(e){
  //     return Response.badRequest(body: {"Error": e.toString()});
  //   }
  // }


  ////////////////////////////////////////////////////////////////////////////////////
  


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

  @Operation.delete('identy') //falta probar esto
  Future<Response> deleteUserByID(@Bind.path('identy') String id) async {
    try{
      change = false;
      await globalCollServer.find().forEach((bus) async { //verifica si existe la informacion ingresada por la URL
        for(var value in bus['users']){
          if(value['id'] == id){
            await globalCollServer.remove(await globalCollServer.findOne(where.eq('id', id)));
            change = true;          
          }
        }
      });

      if(change){
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

  Future<bool> updateRuterosInToServer(Map<String, dynamic> newBody, String idUpdate) async {
    print("actualizando datos del servidor");
    try{
      await globalCollServer.find().forEach((data) {
        for(var value in data['users']){
          for(var value2 in value['ruteros']){
            if(value2['id'] == ObjectId.fromHexString(idUpdate)){ 
              //falta reemplazar los datos
              return true;
            }
          }
        }
      });
    }
    catch(e){
      return false;
    }
  }

  Future<bool> eraseRuteroInServer(String idDelete) async{
    try{
      await globalCollServer.find().forEach((data) async {
        for(var value in data['users']){
          for(var value2 in value['ruteros']){
              if(value2['id'] == ObjectId.fromHexString(idDelete)) {
                var val1 = await globalCollUser.findOne(where.eq('name', value2['name']));
                var val2 = await globalCollUser.findOne(where.eq('chasis', value2['chasis']));
                var val3 = await globalCollUser.findOne(where.eq('PMR', value2['PMR']));
                var val4 = await globalCollUser.findOne(where.eq('routeIndex', value2['routeIndex']));
                var val5 = await globalCollUser.findOne(where.eq('status', value2['status']));
                var val6 = await globalCollUser.findOne(where.eq('publicIP', value2['publicIP']));
                var val7 = await globalCollUser.findOne(where.eq('sharedIP', value2['sharedIP']));
                var val8 = await globalCollUser.findOne(where.eq('version', value2['version']));
                var val9 = await globalCollUser.findOne(where.eq('appVersion', value2['appVersion']));
                var val10 = await globalCollUser.findOne(where.eq('panic', value2['panic']));
                var val11 = await globalCollUser.findOne(where.eq('routes', value2['routes']));
                await globalCollUser.remove(val1);
                await globalCollUser.remove(val2);
                await globalCollUser.remove(val3);
                await globalCollUser.remove(val4);
                await globalCollUser.remove(val5);
                await globalCollUser.remove(val6);
                await globalCollUser.remove(val7);
                await globalCollUser.remove(val8);
                await globalCollUser.remove(val9);
                await globalCollUser.remove(val10);
                await globalCollUser.remove(val11);
                
              }
          }
        }
      });
      return true;
    }
    catch(e){
      return false;
    }
  }
}