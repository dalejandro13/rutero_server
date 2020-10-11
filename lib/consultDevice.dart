import 'dart:convert';
import 'package:tuple/tuple.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rutero_server/adminDB.dart';
import 'package:rutero_server/rutero_server.dart';
import 'dart:developer' as dev;

class ConsultDevices extends ResourceController {
  DbCollection globalCollUser, globalCollServer, globalCollDevice, globalCollCredentials;
  AdmonDB admon = AdmonDB();
  bool change = false;
  bool ready = false;
  bool ready2 = false;
  
  ConsultDevices(){
    connectRuteros();
  }

  void connectRuteros() async {
    await admon.connectToRuteroServer().then((datab) {
      globalCollUser = datab.collection('user');
      globalCollServer = datab.collection('serverApp');
      globalCollDevice = datab.collection('device');
      globalCollCredentials = datab.collection('credentials');
    });   
  }

  @Operation.get()
  Future<Response> getDataInDevice() async {
    try{
      bool change = false;
      String refA = null;
      String refB = null;
      String acum = null;
      String resultA = null;
      String resultB = null;
      int valueA = 0;
      int valueB = 0;
      List<dynamic> devicesList = null;
      devicesList = [];
      await globalCollDevice.find().forEach((dev){
        // ignore: prefer_foreach
        for(var dd in dev['ruteros']){
          devicesList.add(dd);
        }
      });
      
      if(devicesList.isNotEmpty){
        acum = "";
        refA = "";
        refB = "";
        resultA = "";
        resultB = "";

        devicesList.sort((a, b) {
          refA = a['name'].toString();
          refB = b['name'].toString();

          for(int i = 0; i < refA.length; i++){
            if(change){
              acum += refA[i];
            }
            if(refA[i] == '-'){
              change = true;
            }
          }
          resultA = acum.replaceAll(RegExp("[a-zA-Z]"), '');
          acum = "";
          change = false;

          for(int i = 0; i < refB.length; i++){
            if(change){
              acum += refB[i];
            }
            if(refB[i] == '-'){
              change = true;
            }
          }
          resultB = acum.replaceAll(RegExp("[a-zA-Z]"), '');
          acum = "";
          change = false;

          valueA = int.parse(resultA);
          valueB = int.parse(resultB);
          return valueA.compareTo(valueB);
        });
        await admon.close();
        return Response.ok(devicesList);
      }
      else{
        await admon.close();
        return Response.badRequest(body: {"ERROR": "No hay informacion en Devices"});
      }      
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"ERROR": e.toString()});
    }
  }
  
  @Operation.get('id')
  Future<Response> getUser(@Bind.path('id') String id) async {
    try{
      List<dynamic> busesList = null;
      busesList = [];
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
      List<dynamic> busesList = null;
      busesList = [];
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
      if(busesList.isNotEmpty){
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

  // @Operation.get('nameClient')
  // Future<Response> getInfoClient(@Bind.path('nameClient') String name) async {
  //   try{
  //     Map<String, dynamic> mapeo = null;
  //     await globalCollUser.find().forEach((info) {
  //       if(info['name'] == name){
  //         mapeo = {'name': info['name'], 'password': info['password'], 'ftp': info['ftp']};
  //       }
  //     });

  //     if(mapeo != null){
  //       await admon.close();
  //       return Response.ok(mapeo);
  //     }
  //     else{
  //       await admon.close();
  //       return Response.badRequest(body: {"ERROR": "Este usuario no existe en la base de datos, verifica la informacion"});
  //     }
  //   }
  //   catch(e){
  //     await admon.close();
  //     return Response.badRequest(body: {"ERROR": e.toString()});
  //   }
  // }

  @Operation.post() //ingresar nuevo usuario si no existe
  Future<Response> createClient() async{
    bool start = false;
    bool repeat = false;
    try{
      final Map<String, dynamic> body1 = await request.body.decode();
      final nm = body1['name'];
      final pass = body1['password'];
      final ft = body1['ftp'];
      final ruteros = body1['ruteros'];
      await globalCollServer.find().forEach((data) async {
        if(data['version'] != "" && data['appVersion'] != "" && data['version'] != null && data['appVersion'] != null){
          start = true;
        }
      });

      if(start){
        if(pass != null && ft != null){
          var password = pass.trim();
          var ftp = ft.trim();
          if(password != "" && ftp != ""){
            if(nm != null && ruteros != null){
              var name = nm.trim();
              if(name != "" && ruteros != ""){
                if(ruteros.length == 0 && ruteros.runtimeType == [].runtimeType){
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
          else{
            return Response.badRequest(body: {"ERROR": "el campo ftp o password no tienen informacion, verifica nuevamente la informacion"});
          }
        }
        else{
          return Response.badRequest(body: {"ERROR": "el campo ftp o password son nulos, verifica nuevamente la informacion"});
        }
      }
      else{
        await admon.close();
        return Response.badRequest(body: {"ERROR": "no hay informacion en la base de datos"});
      }
    }
    catch(e){
      print("ERROR: ${e.toString()}");
      await admon.close();
      return Response.badRequest(body: {"ERROR": e.toString()});
    }
  }

  @Operation.put() //actualiza el campo update de los ruteros dados por el body
  Future<Response> update() async {
    try{
      List<dynamic> identList = null, listDuplicate = null;

      Map<String, dynamic> body = null;
      identList = [];
      listDuplicate = [];
      body = await request.body.decode();
      final devices = body['devices'];

      await globalCollDevice.find().forEach((data) async {
          for(var vv in data['ruteros']){
            for(var dd in devices){
              if(vv['id'] == ObjectId.fromHexString(dd.toString())){
                listDuplicate.add(dd.toString());
                //await globalCollUser.update(where.eq('_id', dd.toString()), modify.set('update', false));
            }
          }
        }
      });

      identList = listDuplicate.toSet().toList();

      if(identList.isNotEmpty){
        bool enab1 = false, enab2 = false, enab3 = false;
        
        enab1 = await updateUsers(identList); //actualizar en Users
        if(enab1){
          enab2 = await updateDevices(identList); //actualizar en Devices
        }
        if(enab2){
          enab3 = await updateServer(identList); //actualizar en server
        }

        if(enab1 && enab2 && enab3){
          await admon.close();
          return Response.ok(body = {"OK": "Actualizacion Exitosa"});
        }
        else{
          await admon.close();
          return Response.badRequest(body: {"ERROR": "no se puede actualizar la informacion, intentalo de nuevo"});
        }
      }
      else{
        await admon.close();
        return Response.badRequest(body: {"ERROR": "has ingresado mal los identificadores, verifica la informacion"});
      }
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"ERROR": e.toString()});
    }
  }

  @Operation.post('nameorid') //ingresa datos de ruteros nuevos a los clientes que ya existan en la base de datos, ya sea por su nombre o por su id
  Future<Response> createDataRuteros(@Bind.path('nameorid') String nmOrId) async {
    //String os = Platform.operatingSystem;
    bool start = false;
    int connectionIntent = 0;
    ready = false;
    bool ready2 = true, ready3 = true;
    dynamic rut = null;
    Map<String, dynamic> body = null;
    Map<String, dynamic> newBody = null;
    Map<String, dynamic> value = null;

    try{
      body = await request.body.decode();
      ObjectId objectId = ObjectId();
      final os = body['OS'].trim();
      final name = body['name'].trim();
      final chasis = body['chasis'].trim();
      final pmr = body['PMR'];
      final routeIndex = body['routeIndex'];
      final status = body['status'].trim();
      final publicIP = body['publicIP'].trim();
      final sharedIP = body['sharedIP'].trim();
      final version = body['version'].trim();
      final appVersion = body['appVersion'].trim();
      final panic = body['panic'];
      final online = body['onlineDevices'];
      final update = body['update'];
      final gps = body['GPS'];
      ready = false;

      newBody = {
        'id': objectId,
        'OS': os,
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
        'onlineDevices': online,
        'update': update,
        'GPS': gps,
        'connectionIntent': connectionIntent
      };

      await globalCollServer.find().forEach((data) async {
        if(data['version'] != "" && data['appVersion'] != "" && data['version'] != null && data['appVersion'] != null){
          start = true;
        }
      });

      if(start){
        if(name != "" && chasis != "" && pmr != "" && routeIndex != "" && status != "" && publicIP != "" && sharedIP != "" && version != "" && appVersion != "" && panic != "" && online != "" && update != "" && gps != "" && connectionIntent != ""){
          if(name != null && chasis != null && pmr != null && routeIndex != null && status != null && publicIP != null && sharedIP != null && version != null && appVersion != null && panic != null && online != null && update != null && gps != null && connectionIntent != null){

            await globalCollDevice.find().forEach((data) async {
              for(var jj in data['ruteros']){
                if(jj['name'] == name){
                  ready3 = false;
                }
              }
            });

            if(ready3){

              await globalCollUser.find().forEach((data) async {
                if(data['name'] == nmOrId || data['_id'] == ObjectId.fromHexString(nmOrId) || data['_id'] == nmOrId){
                  ready = true;
                  for(var vv in data['ruteros']){
                    if(vv['name'] == name){ //si existe un nombre repetido para este usuario ponga ready2 en false para que no ingrese en la base de datos
                      ready2 = false;
                    }
                  }
                }
              });

              if(ready){
                if(ready2){
                  value = await globalCollUser.findOne({"name": nmOrId });
                  if(value != null){
                    var value2 = value['ruteros'];
                    if(value2 != null){
                      rut = value2;
                      rut.add(newBody);
                      value2 = rut;
                      await globalCollUser.save(value);
                    }
                    else{
                      await globalCollUser.find().forEach((data) async {
                        if(data['name'] == nmOrId){
                          rut = data['ruteros'];
                          rut.add(newBody);
                          data['ruteros'] = rut;
                          await globalCollUser.save(data);
                        }
                      });
                    }
                  }
                  else{
                    value = await globalCollUser.findOne({"_id": ObjectId.fromHexString(nmOrId)});
                    if(value != null){
                      var value2 = value['ruteros'];
                      if(value2 != null){
                        rut = value2;
                        rut.add(newBody);
                        value2 = rut;
                        await globalCollUser.save(value);
                      }
                      else{
                        await globalCollUser.find().forEach((data) async {
                          if(data['_id'] == ObjectId.fromHexString(nmOrId) || data['_id'] == nmOrId){
                            rut = data['ruteros'];
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
                    await insertRuteroInCredentials(newBody);
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
                  return Response.badRequest(body: {"ERROR": "el nombre de este rutero ya existe para este usuario, cambia el nombre"});
                }
              }
              else{
                await admon.close();
                return Response.badRequest(body: {"ERROR": "El cliente no se encuentra registrado en la base de datos"});
              }
            }
            else{
              await admon.close();
              return Response.badRequest(body: {"ERROR": "el rutero de nombre $name ya esta registrado en la base de datos, cambia de nombre"});
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
      else{
        await admon.close();
        return Response.badRequest(body: {"ERROR": "no hay informacion en la base de datos"});
      }
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"ERROR": e.toString()});
    }
  }

  @Operation.put('idupdate') //actualiza la informacion del rutero identificado con idUpdate
  Future<Response> updateDataRuteros(@Bind.path('idupdate') String idUpdate) async {
    try{
      bool start = false, start2 = true;
      //bool startForName = false, startForId = false;
      dynamic ind = null, oldName = null; //idUpdt = null;
      //String os = Platform.operatingSystem;
      //String idUpdt = null;
      Map<String, dynamic> newBody = null, body = null;
      dynamic os = null, name = null, chasis = null, pmr = null, routeIndex = null, status = null, publicIP = null, sharedIP = null, version = null, appVersion = null, panic = null, online = null, update = null, gps = null, connectionIntent = null;
      body = await request.body.decode();
      if(body['OS'] != "" && body['OS'] != null){
        os = body['OS'].trim();
      }
      if(body['name'] != "" && body['name'] != null){
        name = body['name'].trim();
      }
      if(body['chasis'] != "" && body['chasis'] != null){
        chasis = body['chasis'].trim();
      }
      if(body['PMR'] != "" && body['PMR'] != null){
        if(body['PMR'].runtimeType == bool){
          pmr = body['PMR'];
        }
      }
      if(body['routeIndex'] != "" && body['routeIndex'] != null){
        if(body['routeIndex'].runtimeType == int){
          routeIndex = body['routeIndex'];
        }
      }
      if(body['status'] != "" && body['status'] != null){
        status = body['status'].trim();
      }
      if(body['publicIP'] != "" && body['publicIP'] != null){
        publicIP = body['publicIP'].trim();
      }
      if(body['sharedIP'] != "" && body['sharedIP'] != null){
        sharedIP = body['sharedIP'].trim();
      }
      if(body['version'] != "" && body['version'] != null){
        version = body['version'].trim();
      }
      if(body['appVersion'] != "" && body['appVersion'] != null){
        appVersion = body['appVersion'].trim();
      }
      if(body['panic'] != "" && body['panic'] != null){
        if(body['panic'].runtimeType == bool){
          panic = body['panic'];
        }
      }
      if(body['onlineDevices'] != "" && body['onlineDevices'] != null){
        if(body['onlineDevices'].length == 3){ //verifica que tenga los 3 digitos
          online = body['onlineDevices'];
        }
      }
      if(body['update'] != "" && body['update'] != null){
        if(body['update'].runtimeType == bool){
          update = body['update'];
        }
      }
      if(body['GPS'] != "" && body['GPS'] != null){
        gps = body['GPS'].trim();
      }
      if(body['connectionIntent'] != "" && body['connectionIntent'] != null){
        if(body['connectionIntent'].runtimeType == int){
          connectionIntent = body['connectionIntent'];
        }
      }
      ready = false;

      await globalCollServer.find().forEach((data) async {
        if(data['version'] != "" && data['appVersion'] != "" && data['version'] != null && data['appVersion'] != null){
          start = true;
        }
      });

      if(name != null){
        await globalCollDevice.find().forEach((data) async {
          for(var vv in data['ruteros']){
            if(vv[ 'name'].toString().toLowerCase().trim() == name.toString().toLowerCase().trim()){
              start2 = false;
            }
          }
        });
      }

      if(start){
        if(start2){
          await globalCollUser.find().forEach((data) async {
            if(data['ruteros'] != null && data['ruteros'].length != 0){
              for(var val in data['ruteros']){
                
                // try{
                //   if(val['id'] == ObjectId.fromHexString(idUpdate) || val['id'] == idUpdate){
                //     startForId = true;
                //     idUpdt = idUpdate;
                //   }
                // }
                // catch(e){
                //   if(val['name'] == idUpdate){
                //     startForName = true;
                //     idUpdt = val['id'];
                //   }
                // }

                if(val['id'] == ObjectId.fromHexString(idUpdate) || val['id'] == idUpdate){
                  // startForId = false;
                  // startForName = false;
                  oldName ??= val['name']; //consulta antiguo nombre de la base de datos
                  os ??= val['OS'];
                  name ??= val['name'];
                  chasis ??= val['chasis'];
                  pmr ??= val['PMR'];
                  routeIndex ??= val['routeIndex'];
                  status ??= val['status'];
                  publicIP ??= val['publicIP'];
                  sharedIP ??= val['sharedIP'];
                  version ??= val['version'];
                  appVersion ??= val['appVersion'];
                  panic ??= val['panic'];
                  online ??= val['onlineDevices'];
                  update ??= val['update'];
                  gps ??= val['GPS'];
                  connectionIntent ??= val['connectionIntent'];
                  try{
                    newBody = {
                      'id': ObjectId.fromHexString(idUpdate),
                      'OS': os,
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
                      'onlineDevices': online,
                      'update': update,
                      'GPS': gps,
                      'connectionIntent': connectionIntent,
                    };

                  
                    var value2 = data['ruteros']; //DE MUESTRA
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
            if(name != null){
              await updateDeviceNameInCredentials(name, oldName, idUpdate);
            }
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
          return Response.badRequest(body: {"ERROR": "el nombre del rutero ya existe en la base de datos, cambia el nombre"});
        }
      }
      else{
        await admon.close();
        return Response.badRequest(body: {"ERROR": "no hay informacion en la base de datos"});
      }
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"ERROR": e.toString()});
    }
  }

  @Operation.put('nameUser') //actualiza ó ingresa nuevo password y ftp dado el nombre del rutero
  Future<Response> updatePassword(@Bind.path('nameUser') String nameUser) async {
    bool start = false;
    try{
      Map<String, dynamic> newBody = null;
      dynamic pass = null, ftp = null, ident = null, value2 = null;
      int ind = 0;
      ready = false;
      ready2 = false;

      await globalCollServer.find().forEach((data) async {
        if(data['version'] != "" && data['appVersion'] != "" && data['version'] != null && data['appVersion'] != null){
          start = true;
        }
      });

      if(start){
        final Map<String, dynamic> body = await request.body.decode();
        if(body['password'] != "" && body['password'] != null){
          pass ??= body['password'].trim();
        }
        if(body['ftp'] != "" && body['ftp'] != null){
          ftp ??= body['ftp'].trim();
        }

        if(pass != null && pass != ""){
          if(ftp != null && ftp != ""){
            await globalCollServer.find().forEach((data) async { //cambia los datos de la coleccion server
              if(!ready){
                for(var val in data['users']) {
                  if(val['name'] == nameUser){
                    if(!ready){
                      value2 = data['users'];
                      value2.forEach((k){
                        if(val['id'] == k['id']){
                          try{
                            newBody = {
                              "id": k['id'],
                              "name": k['name'],
                              "password": pass,
                              "ftp": ftp,
                              "ruteros": k['ruteros']
                            };
                            ind = int.parse(value2.indexOf(k).toString()); 
                          }
                          catch(e){
                            return Response.badRequest(body: {"ERROR": "no almacena newBody"});
                          }
                        }
                      });

                      value2.removeAt(ind);

                      if(value2 != null){
                        var rut = value2;
                        rut.add(newBody);
                        val = rut;
                        ready = true;
                        await globalCollServer.save(data);
                      }
                    }
                  }
                }
              }
            });

            if(ready){
              if(!ready2) {
                await globalCollUser.find().forEach((data) async {
                  if(data["name"] == nameUser){
                    ident = data['_id'];
                  }
                });

                if(newBody != null){
                  await globalCollUser.update(where.eq('_id', ident), modify.set('name', newBody['name']));
                  await globalCollUser.update(where.eq('_id', ident), modify.set('password', newBody['password']));
                  await globalCollUser.update(where.eq('_id', ident), modify.set('ftp', newBody['ftp']));
                  await globalCollUser.update(where.eq('_id', ident), modify.set('ruteros', newBody['ruteros']));
                  ready2 = true;
                }
              }
            }
            if(ready && ready2){
              await admon.close();
              return Response.ok(newBody);
            }
            else{
              await admon.close();
              return Response.badRequest(body: {"ERROR": "La informacion no se pudo guardar, intentalo nuevamente"});
            }
          }
          else{
            await admon.close();
            return Response.badRequest(body: {"ERROR": "Falta ingresar el ftp"});
          }
        }
        else{
          await admon.close();
          return Response.badRequest(body: {"ERROR": "Falta ingresar la contraseña"});
        }
      }
      else{
        await admon.close();
        return Response.badRequest(body: {"ERROR": "No se puede ingresar a la base de datos, intenta nuevamente"});
      }
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"ERROR": e.toString()});
    }
  }

  @Operation.delete('deleteruteroid') //borra el rutero por medio de la id
  Future<Response> deleteRuteroForId(@Bind.path('deleteruteroid') String idDelete) async {
    dynamic ind = null, rut = null, vl = null, identForCred = null;
    ready = false;
    try{
      await globalCollUser.find().forEach((data) async {
        for(var value in data['ruteros']){
          if(value['id'] == ObjectId.fromHexString(idDelete) || value['id'] == idDelete) {
            vl = data['ruteros'];
            vl.forEach((k){
              if(k['id'] == ObjectId.fromHexString(idDelete)){
                ind = vl.indexOf(k);
                identForCred = k['id'];               
              }
            });

            vl.removeAt(ind);

            if(vl != null){
              rut = vl;
              value = rut;
              ready = true;
              await globalCollUser.save(data);
              await globalCollDevice.remove(await globalCollDevice.findOne({'id': ObjectId.fromHexString(idDelete)}));
            }            
          }
        }
      });

      if(ready){
        await eraseRuteroInServer(idDelete);
        await globalCollCredentials.remove(where.eq('_id', ObjectId.fromHexString(idDelete))); //borra el rutero de la coleccion de credenciales
        await admon.close();
        return Response.ok("OK: el rutero $idDelete ha sido borrado exitosamente");
      }
      else{
        await admon.close();
        return Response.badRequest(body: {"ERROR":"el rutero no se pudo borrar, verifica nuevamente la informacion"});
      }
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"ERROR": e.toString()});
    }
  }

  //////////////////////////////////para servidor//////////////////////////////////////
  
  @Operation.get('ident') //consulta un rutero en especifico por medio de su id
  Future<Response> getInfoRutero(@Bind.path('ident') String id) async {
    try{
      List<dynamic> busesList = null;
      busesList = [];
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

  @Operation.get('NameDevice') //consulta un rutero en especifico por medio de su nombre
  Future<Response> getInfoRuteroByName(@Bind.path('NameDevice') String nameDevices) async {
    try{
      List<dynamic> devicesInfo = null;
      devicesInfo = [];
      await globalCollDevice.find().forEach((dev){
        if(dev['ruteros'].length != 0){
          for(var val in dev['ruteros']){
            if(val['name'].toLowerCase().trim() == nameDevices.toLowerCase().trim()){
              devicesInfo.add(val);
            }
          }
        }
      });

      if(devicesInfo.isNotEmpty){
        await admon.close();
        return Response.ok(devicesInfo);
      }
      else{
        await admon.close();
        return Response.badRequest(body: {'ERROR':'El nombre del dispositivo no existe en el sistema'});
      }
    }
    catch(e){
      print("ERROR ${e.toString()}");
      await admon.close();
      return Response.badRequest(body: {"ERROR": e.toString()});
    }

  }

  /////////////////////////////////////////////////////////////////////////////////////
  
  // Future<void> deleteRuteroFromCredentials(dynamic identForCred) async {
  //   try{
  //     await globalCollCredentials.remove(await globalCollCredentials.findOne({'_id': identForCred}));
  //   }
  //   catch(e){
  //     print(e);
  //     await deleteRuteroFromCredentials(identForCred);
  //   }
  // }
  
  
  Future<void> updateDeviceNameInCredentials(dynamic name, dynamic oldName, String idUpdate) async {
    try{
      //print("nombre nuevo: $name");
      //print("nombre antiguo: $oldName");
      await globalCollCredentials.update(where.eq('_id', ObjectId.fromHexString(idUpdate)), modify.set('deviceName', name));
      //print("listo");
    }
    catch(e){
      print(e);
      await updateDeviceNameInCredentials(name, oldName, idUpdate);
    }
  }
  
  Future<bool> insertToServerData(Map<String, dynamic> body, bool repeat, String mens) async {
    ready = false;
    try{
      if(body['name'] != "" && body['ruteros'] != ""){
        if(!repeat){

          Map<String, dynamic> newBody = {
            'id': mens,
            'name': body['name'],
            'password': body['password'],
            'ftp': body['ftp'],
            'ruteros': body['ruteros'],
          };

          Map<String, dynamic> body2 = {
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
            bool getData = false;
            await globalCollDevice.find().forEach((data) async {
              var dd = data['ruteros'];
              getData = true;
            });

            if(!getData){
              await globalCollDevice.insert(body2);
            }
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
    bool ready2 = false;
    Map<String, dynamic> newBody;
    try{
      await globalCollServer.find().forEach((data) {
        for(var vl in data['users']){
          if(vl['name'] == nameClient || vl['id'] == nameClient){
            newBody = {
              'id': objectId,
              'OS': body['OS'],
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
              'onlineDevices': body['onlineDevices'],
              'update': body['update'],
              'GPS': body['GPS'],
              'connectionIntent': body['connectionIntent'],
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
        await globalCollDevice.find().forEach((value) async { 
          var rut = value['ruteros'];
          rut.add(newBody);
          value['ruteros'] = rut;
          ready2 = true;
          await globalCollDevice.save(value);
        });
      }

      if(ready2){
        return Tuple2(ready2, newBody);
      }
      else{
        return Tuple2(false, newBody);
      }
    }
    catch(e){
      return Tuple2(false, newBody);
    }
  }

  Future<void> insertRuteroInCredentials(Map<String, dynamic> newBody) async {
    try{
      Map<String, dynamic> bodyRedWifi = null, bodyCredentials = null;
      dynamic id = null;

      await globalCollUser.find().forEach((value) async {
        for(var vv in value['ruteros']){
          if(newBody['name'] == vv['name']){
            id = vv['id'];
          }
        }
      });

      bodyRedWifi = {
        'ssid': '--',
        'pass': '--'
      };
      if(id != null){
        bodyCredentials = {
          '_id': id,
          'deviceName': newBody['name'],
          'networkInterface': bodyRedWifi,
          'frontal': bodyRedWifi,
          'lateral': bodyRedWifi,
          'posterior': bodyRedWifi,
        };
      }
      else{
        bodyCredentials = {
          'deviceName': newBody['name'],
          'networkInterface': bodyRedWifi,
          'frontal': bodyRedWifi,
          'lateral': bodyRedWifi,
          'posterior': bodyRedWifi,
        };
      }
      await globalCollCredentials.save(bodyCredentials);
    }
    catch(e){
      print(e);
      await insertRuteroInCredentials(newBody); //si hay un error, llame de nuevo la funcion
    }
  }

  Future<void> updateRuterosInToServer(Map<String, dynamic> newBody, String idUpdate) async {
    try{
      Map<String, dynamic> newBody2 = null;
      dynamic ind = null, vl = null, ind2 = null;
      await globalCollServer.find().forEach((data) async {
        for(var value in data['users']){
          for(var value2 in value['ruteros']){
            if(value2['id'] == ObjectId.fromHexString(idUpdate) || value2['id'] == idUpdate){
              newBody2 = {
                'id': ObjectId.fromHexString(idUpdate),
                'OS': newBody['OS'],
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
                'onlineDevices': newBody['onlineDevices'],
                'update': newBody['update'],
                'GPS': newBody['GPS'],
                'connectionIntent': newBody['connectionIntent'],
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

      await globalCollDevice.find().forEach((data) async { //actualiza datos en device
        try{
          vl = data['ruteros'];
          vl.forEach((k){
            if(k['id'] == ObjectId.fromHexString(idUpdate)){
              ind2 = vl.indexOf(k);
            }
          });

          vl.removeAt(ind2);

          if(vl != null){
            var rut = vl;
            rut.add(newBody);
            vl = rut;
            await globalCollDevice.save(data); 
          }
        }
        catch(e){
          print(e);
        }
      });
    }
    catch(e){
      print(e);
    }
  }

  Future<bool> eraseRuteroInServer(String idDelete) async{
    try{
      bool save = false, save2 = false;
      dynamic ind, ind2, vl;
      await globalCollServer.find().forEach((data) async {
        for(var value in data['users']){
          for(var value2 in value['ruteros']){
            if(value2['id'] == ObjectId.fromHexString(idDelete)) {
              
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
        await globalCollDevice.find().forEach((data) async {
          try{
            vl = data['ruteros'];
            vl.forEach((k){
              if(k['id'] == ObjectId.fromHexString(idDelete)){
                ind2 = vl.indexOf(k);
              }
            });

            vl.removeAt(ind2);

            if(vl != null){
              var rut = vl;
              vl = rut;
              save2 = true;
              await globalCollDevice.save(data); 
            }
          }
          catch(e){
            print(e);
          }
        });
      }

      if(save2){
        return save2;
      }
      else{
        return save2;
      }
      
    }
    catch(e){
      return false;
    }
  }

  Future<bool> updateUsers(List<dynamic> identList) async {
    try{
      dynamic dataID = null, nameUser = null, password = null, ftp = null;
      Map<String, dynamic> newBody = null;
      List<dynamic> listID = null;
      Map<String, dynamic> bodyUsers = null;
      List<Map<String, dynamic>> listBodyUsers = null;
      List<dynamic> tempBody;
      int ctrlControl = 0;
      tempBody = [];
      listBodyUsers = [];
      listID = [];

      await globalCollUser.find().forEach((data) async {
        dataID = data['_id'];
        listID.add(data['_id']);
        nameUser = data['name'];
        password = data['password'];
        tempBody = null;
        tempBody = [];
        ftp = data['ftp'];
        for(var value in data['ruteros']){
          ctrlControl = 0;
          for(int x = 0; x < identList.length; x++){
            if(ObjectId.fromHexString(identList[x].toString()) == value['id']){
              newBody = {
                'id': value['id'],
                'OS': value['OS'],
                'name': value['name'],
                'chasis': value['chasis'],
                'PMR': value['PMR'],
                'routeIndex': value['routeIndex'],
                'status': value['status'],
                'publicIP': value['publicIP'],
                'sharedIP': value['sharedIP'],
                'version': value['version'],
                'appVersion': value['appVersion'],
                'panic': value['panic'],
                'onlineDevices': value['onlineDevices'],
                'update': true,
                'GPS': value['GPS'],
                'connectionIntent': value['connectionIntent'],
              };
              tempBody.add(newBody);
              ctrlControl = 0;
            }
            else{
              ctrlControl++;
              if(ctrlControl >= identList.length){
                ctrlControl = 0;
                tempBody.add(value);
              }
            }
          }
        }
        bodyUsers = {
          '_id': dataID,
          'name': nameUser,
          'password': password,
          'ftp': ftp,
          'ruteros': tempBody,
        };
        listBodyUsers.add(bodyUsers);
      });

      if(listBodyUsers.isNotEmpty){
        try{
          for(int v = 0; v < listID.length; v++){
            for(var hh in listBodyUsers){
              if(hh['_id'] == listID[v]){
                await globalCollUser.update(where.eq('_id', listID[v]), modify.set('ruteros', hh['ruteros']));
              }
            }
          }
          return true;
        }
        catch(e){
          return false;
        }
      }
      else{
        return false;
      }      
    }
    catch(e){
      print("Error $e");
      return false;
    }
  }

  Future<bool> updateDevices(List<dynamic> identList) async{
    try{
      int ctrlControl = 0;
      List<dynamic> tempBody = null;
      dynamic dataIdRef = null; 
      Map<String, dynamic> newBody = null;
      tempBody = [];

      await globalCollDevice.find().forEach((data) async {

        dataIdRef = data['_id'];
        for(var val in data['ruteros']){
          ctrlControl = 0;
          for(int x = 0; x < identList.length; x++){
            if(ObjectId.fromHexString(identList[x].toString()) == val['id']){
              newBody = {
                'id': val['id'],
                'OS': val['OS'],
                'name': val['name'],
                'chasis': val['chasis'],
                'PMR': val['PMR'],
                'routeIndex': val['routeIndex'],
                'status': val['status'],
                'publicIP': val['publicIP'],
                'sharedIP': val['sharedIP'],
                'version': val['version'],
                'appVersion': val['appVersion'],
                'panic': val['panic'],
                'onlineDevices': val['onlineDevices'],
                'update': true,
                'GPS': val['GPS'],
                'connectionIntent': val['connectionIntent'],
              };
              
              tempBody.add(newBody);
              ctrlControl = 0;
            }
            else{
              ctrlControl++;
              if(ctrlControl >= identList.length){
                ctrlControl = 0;
                tempBody.add(val);
              }
            }
          }
        }
      });

      if(tempBody.isNotEmpty){
        try{
          await globalCollDevice.update(where.eq('_id', dataIdRef), modify.set('ruteros', tempBody));
          return true;
        }
        catch(e){
          print("Error $e");
          return false;
        }
      }
      else{
        return false;
      }
    }
    catch(e){
      print("Error $e");
      return false;
    }
  }

  Future<bool> updateServer(List<dynamic> identList) async{
    try{
      dynamic id = null, version = null, appVersion = null, idUser = null, nameUser = null,
      password = null, ftp = null;

      int ctrlControl = 0;
      Map<String, dynamic> newBody = null;
      List<Map<String, dynamic>> listBodyUsers = null;
      List<dynamic> bodyRuteros;
      Map<String, dynamic> bodyUsers = null;
      listBodyUsers = [];
      await globalCollServer.find().forEach((data) async {
        id = data['_id'];
        version = data['version'];
        appVersion = data['appVersion'];
        for(var value in data['users']){
          idUser = value['id'];
          nameUser = value['name'];
          password = value['password'];
          ftp = value['ftp'];
          bodyRuteros = null;
          bodyRuteros = [];
          for(var value2 in value['ruteros']){
            ctrlControl = 0;
            for(int x = 0; x < identList.length; x++){
              if(value2['id'] == ObjectId.fromHexString(identList[x].toString())){
                newBody = {
                  'id': value2['id'],
                  'OS': value2['OS'],
                  'name': value2['name'],
                  'chasis': value2['chasis'],
                  'PMR': value2['PMR'],
                  'routeIndex': value2['routeIndex'],
                  'status': value2['status'],
                  'publicIP': value2['publicIP'],
                  'sharedIP': value2['sharedIP'],
                  'version': value2['version'],
                  'appVersion': value2['appVersion'],
                  'panic': value2['panic'],
                  'onlineDevices': value2['onlineDevices'],
                  'update': true,
                  'GPS': value2['GPS'],
                  'connectionIntent': value2['connectionIntent'],
                };
                bodyRuteros.add(newBody);
                ctrlControl = 0;
              }
              else{
                ctrlControl++;
                if(ctrlControl >= identList.length){
                  ctrlControl = 0;
                  bodyRuteros.add(value2);
                }
              }
            }
          }
          bodyUsers = {
            'id': idUser,
            'name': nameUser,
            'password': password,
            'ftp': ftp,
            'ruteros': bodyRuteros,
          };
          listBodyUsers.add(bodyUsers);
        }
      });

      if(listBodyUsers.isNotEmpty){
        if(listBodyUsers.isNotEmpty){
          try{
            await globalCollServer.update(where.eq('_id', id), modify.set('users', listBodyUsers));
            return true;
          }
          catch(e){
            print("Error $e");
            return false;
          }
        }
      }
      else{
        return false;
      }
    }
    catch(e){
      print("Error $e");
      return false;
    }
  }

}