import 'package:mongo_dart/mongo_dart.dart';
import 'package:rutero_server/adminDB.dart';
import 'package:rutero_server/rutero_server.dart';
//import 'package:rutero_server/busConsult.dart';

class BusConsult extends ResourceController {
  
  DbCollection collBus;
  AdmonDB admon = AdmonDB();
  DbCollection globalColl;
  bool change = false;
  // ignore: sort_constructors_first
  BusConsult(){
    connectDB();
  }

  void connectDB() async {
    await admon.connectToDataBase().then((datab) {
      globalColl = datab.collection('Buses');
    });   
  }

  @Operation.get('id')
  Future<Response> getData(@Bind.path('id') String id) async {
    try{
      final busesList = [];
      await globalColl.find().forEach((bus) {
        if(bus['_id'] == ObjectId.fromHexString(id)){
          busesList.add(bus);
        }
      });
      return Response.ok(busesList);
    }
    catch(e){
      return Response.badRequest(body: {"Error": e.toString()});
    }
  }

  @Operation.get('name')
  Future<Response> getByName(@Bind.path('name') String name) async {
    try{
      final busesList = [];
      await globalColl.find().forEach((bus) {
        if(bus['name'] == name){
          busesList.add(bus);
        }
      });
      return Response.ok(busesList);
    }
    catch(e){
      return Response.badRequest(body: {"Error": e.toString()});
    }
  }
  
  @Operation.get()
  Future<Response> getAllBuses() async {
    try{
      final busesList = [];
      await globalColl.find().forEach(busesList.add);
      return Response.ok(busesList);
    }
    catch(e){
      return Response.badRequest(body: {"Error": e.toString()});
    }
  }

  @Operation.get('publicIP')
  Future<Response> getByPublicIP(@Bind.path('publicIP') String ip) async {
    try{
      final busesList = [];
      await globalColl.find().forEach((bus) {
        if(bus['publicIP'] == ip){
          busesList.add(bus);
        }
      });
      return Response.ok(busesList);
    }
    catch(e){
      return Response.badRequest(body: {"Error": e.toString()});
    }
  }

  @Operation.get('sharedIP')
  Future<Response> getBySharedIP(@Bind.path('sharedIP') String ip) async {
    try{
      final busesList = [];
      await globalColl.find().forEach((bus) { 
        if(bus['sharedIP'] == ip){
          busesList.add(bus);
        }
      });
      return Response.ok(busesList);
    }
    catch(e){
      return Response.badRequest(body: {"Error": e.toString()});
    }
  }

  @Operation.post()
  Future<Response> createBus() async{
    try{
      final Map<String, dynamic> body = await request.body.decode();
      final name = body['name'];
      final routeInfo = body['routeInfo'];
      final status = body['status'];
      final publicIP = body['publicIP'];
      final sharedIP = body['sharedIP'];
      final version = body['version'];
      final appVersion = body['appVersion'];
      final panic = body['panic'];
      change = false;

      if(name != "" && routeInfo != "" && status != "" && publicIP != "" && sharedIP != "" && version != "" && appVersion != "" && panic != ""){
        if(name != null && routeInfo != null && status != null && publicIP != null && sharedIP != null && version != null && appVersion != null && panic != null){

          await globalColl.find().forEach((bus) {
            if(bus['name'] == name){
              change = true;
            }
          });

          if(change){
            return Response.badRequest(body: {"Error": "Ya existe un bus con el mismo nombre"});
          }
          else{
            await globalColl.insert(body);
            return Response.ok("info: los datos han sido guardados exitosamente");
          }
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
  }

  @Operation.put('name')
  Future<Response> updateDataBus(@Bind.path('name') String nm) async {
    try{
      
      final Map<String, dynamic> body = await request.body.decode();
      final name = body['name'];
      final routeInfo = body['routeInfo'];
      final status = body['status'];
      final publicIP = body['publicIP'];
      final sharedIP = body['sharedIP'];
      final version = body['version'];
      final appVersion = body['appVersion'];
      final panic = body['panic'];
      change = false;

      if(name != "" && routeInfo != "" && status != "" && publicIP != "" && sharedIP != "" && version != "" && appVersion != "" && panic != ""){
        if(name != null && routeInfo != null && status != null && publicIP != null && sharedIP != null && version != null && appVersion != null && panic != null){

          await globalColl.find().forEach((bus) { //verifica si existe la informacion ingresada por la URL
            if(bus['name'] == nm){
              change = true;
            }
          });
          
          if(change){
            await globalColl.update(await globalColl.findOne(where.eq('name', nm)), {
              r'$set': {
                'name': name,
                'routeInfo': routeInfo,
                'status': status,
                'publicIP': publicIP,
                'sharedIP': sharedIP,
                'version': version,
                'appVersion': appVersion,
                'panic': panic,
              },
            });
            return Response.ok("info: los datos han sido actualizados exitosamente");
          }
          else{
            return Response.badRequest(body: {"Error": "el nombre no existe en la base de datos"});
          }

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
    
  }

  @Operation.delete('name')
  Future<Response> deleteDataBus(@Bind.path('name') String nm) async {
    try{

      change = false;
      await globalColl.find().forEach((bus) { //verifica si existe la informacion ingresada por la URL
        if(bus['name'] == nm){
          change = true;
        }
      });

      if(change){
        await globalColl.remove(await globalColl.findOne(where.eq('name', nm)));
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

  @Operation.delete('id')
  Future<Response> deleteByID(@Bind.path('id') String id) async {
    try{
      
      change = false;
      await globalColl.find().forEach((bus) { //verifica si existe la informacion ingresada por la URL
        if(bus['_id'] == ObjectId.fromHexString(id)){
          change = true;
        }
      });
      
      if(change){
        await globalColl.remove(await globalColl.findOne(where.eq('_id', ObjectId.fromHexString(id))));
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
}