import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rutero_server/adminDB.dart';
import 'package:rutero_server/rutero_server.dart';
import 'dart:developer' as dev;

class UserConsult extends ResourceController {
  DbCollection globalCollUser;
  DbCollection globalCollServer;
  AdmonDB admon = AdmonDB();
  bool change = false;
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
  ///
  @Operation.get('id')
  Future<Response> getUser(@Bind.path('id') String id) async {
    try{
      var busesList = [];
      await globalCollUser.find().forEach((bus) {
        if(bus['_id'] == ObjectId.fromHexString(id)){
          // ignore: prefer_foreach
          for(var val in bus['ruteros']){
            busesList.add(val);
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
          // ignore: prefer_foreach
          for(var value in bus['ruteros']){
            busesList.add(value);
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

  @Operation.post() //ingresar un nuevo usuario si no existe (falta probar esto)
  Future<Response> createUser() async{
    try{
      final Map<String, dynamic> body = await request.body.decode();
      final name = body['name'];
      final ruteros = body['ruteros'];
      bool repeat = false;

      if(name != "" && ruteros != ""){
        if(name != null && ruteros != null){
          await globalCollUser.find().forEach((bus) async {
            if(bus['name'] == name){
              repeat = true;
            }
          });

          if(!repeat){
            await globalCollUser.insert(body);
            var resp = await insertToServerData(body);
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
          return Response.badRequest(body: {"Error": "un dato esta nulo, verifica nuevamente la informacion"});
        }
      }
      else{
        await admon.close();
        return Response.badRequest(body: {"Error": "un dato esta vacio, verifica nuevamente la informacion"});
      }
    }
    catch(e){
      print("Error: ${e.toString()}");
      await admon.close();
      return Response.badRequest(body: {"Error": e.toString()});
    }
  }

  @Operation.put('nme') //falta probar esto
  Future<Response> updateDataBus(@Bind.path('nme') String nm) async {
    try{
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

      if(name != "" && chasis != "" && pmr != "" && routeIndex != "" && status != "" && publicIP != "" && sharedIP != "" && version != "" && appVersion != "" && panic != "" && routes != ""){
        if(name != null && chasis != null && pmr != null && routeIndex != null && status != null && publicIP != null && sharedIP != null && version != null && appVersion != null && panic != null && routes != null){
          await globalCollUser.find().forEach((bus) async { //verifica si existe la informacion ingresada por la URL
            if(bus['name'] == nm){
                await globalCollUser.update(await globalCollUser.findOne(where.eq(bus['ruteros'].toString(), '[]')), {
                r'$set': {
                  "ruteros": [{
                    'name': name,
                    'chasis': chasis,
                    "PMR": pmr,
                    'routeIndex': routeIndex,
                    'status': status,
                    'publicIP': publicIP,
                    'sharedIP': sharedIP,
                    'version': version,
                    'appVersion': appVersion,
                    'panic': panic,
                    'routes': routes
                  }]
                },
              });
              return Response.ok("info: los datos han sido actualizados exitosamente");
            }
          });
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

  @Operation.delete('identy') //falta probar esto
  Future<Response> deleteUserByID(@Bind.path('identy') String id) async {
    try{
      change = false;
      await globalCollUser.find().forEach((bus) { //verifica si existe la informacion ingresada por la URL
        if(bus['_id'] == ObjectId.fromHexString(id)){
          change = true;
        }
      });

      if(change){
        await globalCollUser.remove(await globalCollUser.findOne(where.eq('_id', id)));
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

  @Operation.delete('nm')
  Future<Response> deleteDataBus(@Bind.path('nm') String nm) async { //continua aca
    try{

      change = false;
      await globalCollServer.find().forEach((bus) { //verifica si existe la informacion ingresada por la URL
        if(bus['name'] == nm){
          change = true;
        }
      });

      if(change){
        await globalCollServer.remove(await globalCollServer.findOne(where.eq('name', nm)));
        return Response.ok("info: la informacion ha sido borrada exitosamente");
      }
      else{
        return Response.badRequest(body: {"Error":"el dato no se pudo borrar, verifica nuevamente la informacion"});
      }
      
    }
    catch(e){
      return Response.badRequest(body: {"Error": e.toString()});
    }
  }


  ////////////////////////////////////////////////////////////////////////////////////
  




  
  //////////////////////////////////para servidor//////////////////////////////////////
  
  @Operation.get() //consulta todo el servidor
  Future<Response> getAllBuses() async {
    try{
      var busesList = [];
      await globalCollServer.find().forEach(busesList.add);
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
  Future<Response> insertToServerData(Map<String, dynamic> bdy) async {
    //@Operation.post() //ingresar usuario en RuteroServer
    //Future<Response> createUser() async{
      try{
        // final Map<String, dynamic> body = await request.body.decode();
        // final name = body['name'];
        // final ruteros = body['ruteros'];
        bool ready = false;
        if(bdy['name'] != "" && bdy['ruteros'] != ""){
          if(bdy['name'] != null && bdy['ruteros'] != null){
            await globalCollServer.find().forEach((bus) async {
              print('se tiene que: $bus');
              for(var val in bus['users']){
                for(var val2 in val['ruteros']){
                  
                  //await globalCollServer.insert(bdy);
                  await globalCollUser.update(await globalCollServer.findOne(where.eq(bus['users'].toString(), 'id')), {
                  r'$set': {
                    "users":[{
                        bdy,
                      }],
                    },
                  });
                  ready = true;
                }
              }
            });
            
            if(ready){
              return Response.ok(ready); //true
            }
            else{
              return Response.ok(ready); //false
            }
            
            // if(!repeat){
            //   // await globalCollUser.update(await globalCollUser.findOne(where.eq('users', bus['users'])), {
            //   //   r'$set': {
            //   //     'name': name,
            //   //     'ruteros': ruteros,
            //   //   },
            //   // });
            //   await globalCollServer.insert(body);
            //   await insertToServerData();
            //   return Response.ok(body);
            // }
            // else{
            //   return Response.badRequest(body: {"Error": "Ya existe un bus con el mismo nombre"});
            // }
          }
          else{
            return Response.badRequest(body: {"Error": "un dato esta nulo, verifica nuevamente la informacion"});
          }
        }
        else{
          return Response.badRequest(body: {"Error": "un dato esta vacio, verifica nuevamente la informacion"});
        }
      }
      catch(e){
        return Response.badRequest(body: {"Error": e.toString()});
      }
    //}
  }

}