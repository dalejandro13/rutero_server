import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rutero_server/adminDB.dart';
import 'package:rutero_server/rutero_server.dart';
//import 'dart:async';
import 'dart:developer' as dev;
//import 'package:rutero_server/busConsult.dart';

class ServerConsult extends ResourceController {
  
  DbCollection collBus;
  AdmonDB admon = AdmonDB();
  DbCollection globalCollServer;
  bool change = false;
  // ignore: sort_constructors_first
  ServerConsult(){
    //connectRuteros();
  }

  // void connectRuteros() async {
  //   await admon.connectToRuteroServer().then((datab) {
  //     globalCollServer = datab.collection('RuteroServer');
  //   });   
  // }

  /////////////////////para RuteroServer/////////////////////////////////////
  // @Operation.get('id')
  // Future<Response> getData(@Bind.path('id') String id) async {
  //   try{
  //     final busesList = [];
  //     dynamic version, appVersion, id2, name, id3, name2, chasis, pmr, 
  //     routeIndex, status, publicIP, sharedIP, version2, appVersion2, panic, routes;
  //     await globalCollServer.find().forEach((bus) {
  //       final version = bus['version'];
  //       final appVersion = bus['appVersion'];
  //       for(var val in bus['users']){
  //         if(val['id'] == id){
  //           print(val);
  //           Map<String, dynamic> bb = {}; //jsonEncode(val);
  //           print(bb);
  //           dev.debugger();
  //           busesList.add(bb);
  //           print(busesList);
  //           dev.debugger();
  //           return Response.ok(busesList);
  //           // name = val['name'];
  //           // for(var val2 in val['ruteros']){
  //           //   id3 = val2['id'];
  //           //   name2 = val2['name'];
  //           //   chasis = val2['chasis'];
  //           //   pmr = val2['PMR'];
  //           //   routeIndex = val2['routeIndex'];
  //           //   status = val2['status'];
  //           //   publicIP = val2['publicIP'];
  //           //   sharedIP = val2['sharedIP'];
  //           //   version2 = val2['version'];
  //           //   appVersion2 = val2['appVersion'];
  //           //   panic = val2['panic'];
  //           //   routes = val2['routes'];
            
  //           // }
  //         }
  //       }
  //     });

  //     await globalCollServer.find().forEach((bus) {
  //       if(bus['_id'] == ObjectId.fromHexString(id)){
  //         busesList.add(bus);
  //       }
  //     });
      
  //   }
  //   catch(e){
  //     dev.debugger();
  //     return Response.badRequest(body: {"Error": e.toString()});
  //   }
  // }

  @Operation.get() //consulta todo el servidor
  Future<Response> getAllBuses() async {
    try{
      final busesList = [];
      await globalCollServer.find().forEach(busesList.add);   
      return Response.ok(busesList);
    }
    catch(e){
      return Response.badRequest(body: {"Error": e.toString()});
    }
  }

  @Operation.get('ident') //consulta un rutero en especifico por medio de su id
  Future<Response> getInfoRutero(@Bind.path('ident') String id) async {
    try{
      List<dynamic> busesList = [];
      await globalCollServer.find().forEach((bus) {
        for(var value in bus['users']){
          for(var value2 in value['ruteros']){
            if(value2['id'] == id){
              busesList.add(value2);
            }
          }
        }
      });

      if(busesList.isNotEmpty){
        return Response.ok(busesList);
      }
      else{
        return Response.badRequest(body: {'Error':'No se pudieron encontrar elementos para retornar'});
      }
    }
    catch(e){
      print("Error ${e.toString()}");
      return Response.badRequest(body: {"Error": e.toString()});
    }
  }

  @Operation.get('name') //buscar rutero por nombre
  Future<Response> getByName(@Bind.path('name') String name) async {
    try{
      final busesList = [];
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

      if(busesList.isNotEmpty){
        return Response.ok(busesList);
      }
      else{
        return Response.badRequest(body: {'Error':'No se pudieron encontrar elementos para retornar'});
      }
      
    }
    catch(e){
      return Response.badRequest(body: {"Error": e.toString()});
    }
  }

  // @Operation.post() //ingresar un nuevo usuario si no existe
  // Future<Response> createUser() async{
  //   try{
  //     final Map<String, dynamic> body = await request.body.decode();
  //     final name = body['name'];
  //     final ruteros = body['ruteros'];
  //     bool repeat = false;

  //     if(name != "" && ruteros != ""){
  //       if(name != null && ruteros != null){
  //         await globalCollServer.find().forEach((bus) async { 
  //           for(var value in bus['users']){
  //             if(value['name'] == name){
  //               repeat = true;
  //             }
  //           }

  //           if(!repeat){

  //             await globalCollServer.update(await globalCollServer.findOne(where.eq('users', bus['users'])), {
  //               r'$set': {
  //                 'name': name,
  //                 'ruteros': ruteros,
  //               },
  //             });

  //             //await globalCollServer.insert(body);
  //             return Response.ok(body);  
  //           }
  //           else{
  //             return Response.badRequest(body: {"Error": "Ya existe un bus con el mismo nombre"});
  //           }
  //         });
  //       }
  //       else{
  //         return Response.badRequest(body: {"Error": "un dato esta nulo, verifica nuevamente la informacion"});
  //       }
  //     }
  //     else{
  //       return Response.badRequest(body: {"Error": "un dato esta vacio, verifica nuevamente la informacion"});
  //     }

  //     // for(var value in body['users']){

  //     // }
      


  //     // final version = body['version'];
  //     // final appVersion = body['appVersion'];
  //     // dynamic id, id2, name2, ruteros, id3, name3, chasis, pmr, routeIndex, status, publicIP, sharedIP, version2, appVersion2, panic, routes;
  //     // final users = body['users'];
  //     // for(var val in users){
  //     //   id2 = val['id'];
  //     //   name2 = val['name'];
  //     //   ruteros = val['ruteros'];
  //     //   for(var val2 in ruteros){
  //     //     id3 = val2['id'];
  //     //     name3 = val2['name'];
  //     //     chasis = val2['chasis'];
  //     //     pmr = val2["PMR"];
  //     //     routeIndex = val2['routeIndex'];
  //     //     status = val2['status'];
  //     //     publicIP = val2['publicIP'];
  //     //     sharedIP = val2['sharedIP'];
  //     //     version2 = val2['version'];
  //     //     appVersion2 = val2['appVersion'];
  //     //     panic = val2['panic'];
  //     //     routes = val2['routes'];
  //     //     print(routes);

  //     //   }
  //     // }
  //     //change = false;

  //     // if(version != "" && appVersion != "" && id2 != "" && name2 != "" && ruteros != "" && id3 != "" && name3 != "" && chasis != "" && pmr != "" && routeIndex != "" && status != "" && publicIP != "" && sharedIP != "" && version2 != "" && appVersion != "" && panic != "" && routes != ""){
  //     //   if(version != null && appVersion != null && id2 != null && name2 != null && ruteros != null && id3 != null && name3 != null && chasis != null && pmr != null && routeIndex != null && status != null && publicIP != null && sharedIP != null && version2 != null && appVersion != null && panic != null && routes != null){
  //     //     await globalCollServer.find().forEach((bus) { 
  //     //       id = bus['_id'];
  //     //       dynamic ident2, ident3;
  //     //       for(var value in bus['users']){

  //     //       }
  //     //     });
  //     //   }
  //     //   else{
  //     //     return Response.badRequest(body: {"Error": "un dato esta nulo, verifica nuevamente la informacion"});
  //     //   }
  //     // }
  //     // else{
  //     //   return Response.badRequest(body: {"Error": "un dato esta vacio, verifica nuevamente la informacion"});
  //     // }

  //     // if(name != "" && routeInfo != "" && status != "" && publicIP != "" && sharedIP != "" && version != "" && appVersion != "" && panic != ""){
  //     //   if(name != null && routeInfo != null && status != null && publicIP != null && sharedIP != null && version != null && appVersion != null && panic != null){

  //     //     await globalCollServer.find().forEach((bus) {
  //     //       if(bus['name'] == name){
  //     //         change = true;
  //     //       }
  //     //     });

  //     //     if(change){
  //     //       return Response.badRequest(body: {"Error": "Ya existe un bus con el mismo nombre"});
  //     //     }
  //     //     else{
  //     //       await globalCollServer.insert(body);
  //     //       return Response.ok("info: los datos han sido guardados exitosamente");
  //     //     }
  //     //   }
  //     //   else{
  //     //     return Response.badRequest(body: {"Error": "un dato esta nulo, verifica nuevamente la informacion"});
  //     //   }
  //     // }
  //     // else{
  //     //   return Response.badRequest(body: {"Error": "un dato esta vacio, verifica nuevamente la informacion"});
  //     // }
  //   }
  //   catch(e){
  //     print("Error: ${e.toString()}");
  //     return Response.badRequest(body: {"Error": e.toString()});
  //   }
  // }

  // @Operation.get('publicIP')
  // Future<Response> getByPublicIP(@Bind.path('publicIP') String ip) async {
  //   try{
  //     final busesList = [];
  //     await globalCollServer.find().forEach((bus){
  //       for(var value in bus['users']){
  //         for(var value2 in value['ruteros']){
  //           if(value2['publicIP'] == ip){
  //             busesList.add(bus);
  //           }
  //         }
  //       }
  //     });
  //     return Response.ok(busesList);
  //   }
  //   catch(e){
  //     return Response.badRequest(body: {"Error": e.toString()});
  //   }
  // }

  // @Operation.get('sharedIP')
  // Future<Response> getBySharedIP(@Bind.path('sharedIP') String ip) async {
  //   try{
  //     final busesList = [];
  //     await globalCollServer.find().forEach((bus){
  //       for(var value in bus['users']){
  //         for(var value2 in value['ruteros']){
  //           if(value2['sharedIP'] == ip){
  //             busesList.add(bus);
  //           }
  //         }
  //       }
  //     });
  //     return Response.ok(busesList);
  //   }
  //   catch(e){
  //     return Response.badRequest(body: {"Error": e.toString()});
  //   }
  // }

  // @Operation.post()
  // Future<Response> createBus() async{
  //   try{
  //     final Map<String, dynamic> body = await request.body.decode();
  //     // final name = body['name'];
  //     // final routeInfo = body['routeInfo'];
  //     // final status = body['status'];
  //     // final publicIP = body['publicIP'];
  //     // final sharedIP = body['sharedIP'];
  //     // final version = body['version'];
  //     // final appVersion = body['appVersion'];
  //     // final panic = body['panic'];
  //     final version = body['version'];
  //     final appVersion = body['appVersion'];
  //     dynamic id, id2, name2, ruteros, id3, name3, chasis, pmr, routeIndex, status, publicIP, sharedIP, version2, appVersion2, panic, routes;
  //     final users = body['users'];
  //     for(var val in users){
  //       id2 = val['id'];
  //       name2 = val['name'];
  //       ruteros = val['ruteros'];
  //       for(var val2 in ruteros){
  //         id3 = val2['id'];
  //         name3 = val2['name'];
  //         chasis = val2['chasis'];
  //         pmr = val2["PMR"];
  //         routeIndex = val2['routeIndex'];
  //         status = val2['status'];
  //         publicIP = val2['publicIP'];
  //         sharedIP = val2['sharedIP'];
  //         version2 = val2['version'];
  //         appVersion2 = val2['appVersion'];
  //         panic = val2['panic'];
  //         routes = val2['routes'];
  //         print(routes);

  //       }
  //     }
  //     change = false;

  //     if(version != "" && appVersion != "" && id2 != "" && name2 != "" && ruteros != "" && id3 != "" && name3 != "" && chasis != "" && pmr != "" && routeIndex != "" && status != "" && publicIP != "" && sharedIP != "" && version2 != "" && appVersion != "" && panic != "" && routes != ""){
  //       if(version != null && appVersion != null && id2 != null && name2 != null && ruteros != null && id3 != null && name3 != null && chasis != null && pmr != null && routeIndex != null && status != null && publicIP != null && sharedIP != null && version2 != null && appVersion != null && panic != null && routes != null){
  //         await globalCollServer.find().forEach((bus) { 
  //           id = bus['_id'];
  //           dynamic ident2, ident3;
  //           for(var value in bus['users']){

  //           }
  //         });
  //       }
  //       else{
  //         return Response.badRequest(body: {"Error": "un dato esta nulo, verifica nuevamente la informacion"});
  //       }
  //     }
  //     else{
  //       return Response.badRequest(body: {"Error": "un dato esta vacio, verifica nuevamente la informacion"});
  //     }

  //     // if(name != "" && routeInfo != "" && status != "" && publicIP != "" && sharedIP != "" && version != "" && appVersion != "" && panic != ""){
  //     //   if(name != null && routeInfo != null && status != null && publicIP != null && sharedIP != null && version != null && appVersion != null && panic != null){

  //     //     await globalCollServer.find().forEach((bus) {
  //     //       if(bus['name'] == name){
  //     //         change = true;
  //     //       }
  //     //     });

  //     //     if(change){
  //     //       return Response.badRequest(body: {"Error": "Ya existe un bus con el mismo nombre"});
  //     //     }
  //     //     else{
  //     //       await globalCollServer.insert(body);
  //     //       return Response.ok("info: los datos han sido guardados exitosamente");
  //     //     }
  //     //   }
  //     //   else{
  //     //     return Response.badRequest(body: {"Error": "un dato esta nulo, verifica nuevamente la informacion"});
  //     //   }
  //     // }
  //     // else{
  //     //   return Response.badRequest(body: {"Error": "un dato esta vacio, verifica nuevamente la informacion"});
  //     // }
  //   }
  //   catch(e){
  //     dev.debugger();
  //     return Response.badRequest(body: {"Error": e.toString()});
  //   }
  // }

  // @Operation.put('name')
  // Future<Response> updateDataBus(@Bind.path('name') String nm) async {
  //   try{
      
  //     final Map<String, dynamic> body = await request.body.decode();
  //     final name = body['name'];
  //     final routeInfo = body['routeInfo'];
  //     final status = body['status'];
  //     final publicIP = body['publicIP'];
  //     final sharedIP = body['sharedIP'];
  //     final version = body['version'];
  //     final appVersion = body['appVersion'];
  //     final panic = body['panic'];
  //     change = false;

  //     if(name != "" && routeInfo != "" && status != "" && publicIP != "" && sharedIP != "" && version != "" && appVersion != "" && panic != ""){
  //       if(name != null && routeInfo != null && status != null && publicIP != null && sharedIP != null && version != null && appVersion != null && panic != null){

  //         await globalCollServer.find().forEach((bus) { //verifica si existe la informacion ingresada por la URL
  //           if(bus['name'] == nm){
  //             change = true;
  //           }
  //         });
          
  //         if(change){
  //           await globalCollServer.update(await globalCollServer.findOne(where.eq('name', nm)), {
  //             r'$set': {
  //               'name': name,
  //               'routeInfo': routeInfo,
  //               'status': status,
  //               'publicIP': publicIP,
  //               'sharedIP': sharedIP,
  //               'version': version,
  //               'appVersion': appVersion,
  //               'panic': panic,
  //             },
  //           });
  //           return Response.ok("info: los datos han sido actualizados exitosamente");
  //         }
  //         else{
  //           return Response.badRequest(body: {"Error": "el nombre no existe en la base de datos"});
  //         }

  //       }
  //       else{
  //         return Response.badRequest(body: {"Error": "un dato esta nulo, verifica nuevamente la informacion"});
  //       }
  //     }
  //     else{
  //       return Response.badRequest(body: {"Error": "un dato esta vacio, verifica nuevamente la informacion"});
  //     }
  //   }
  //   catch(e){
  //     return Response.badRequest(body: {"Error": e.toString()});
  //   }
    
  // }

  // @Operation.delete('name')
  // Future<Response> deleteDataBus(@Bind.path('name') String nm) async {
  //   try{

  //     change = false;
  //     await globalCollServer.find().forEach((bus) { //verifica si existe la informacion ingresada por la URL
  //       if(bus['name'] == nm){
  //         change = true;
  //       }
  //     });

  //     if(change){
  //       await globalCollServer.remove(await globalCollServer.findOne(where.eq('name', nm)));
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

  // @Operation.delete('id')
  // Future<Response> deleteByID(@Bind.path('id') String id) async {
  //   try{
  //     change = false;
  //     await globalCollServer.find().forEach((bus) { //verifica si existe la informacion ingresada por la URL
  //       if(bus['_id'] == ObjectId.fromHexString(id)){
  //         change = true;
  //       }
  //     });
      
  //     if(change){
  //       await globalCollServer.remove(await globalCollServer.findOne(where.eq('_id', ObjectId.fromHexString(id))));
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


  
}