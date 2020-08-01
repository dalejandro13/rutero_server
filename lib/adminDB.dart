import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';

class AdmonDB{
  Db db;
  Db dbRutero;
  Db dbUsuarios;
  DbCollection collBus;

  Future<Db> connectToDataBase() async {
    // var info = {
    //   "version": "2.1.1",
    //   "users": [{
    //     "name": "rp8w-r3", 
    //     "chasis": "Reparbus", 
    //     "PMR": true,
    //     "routeIndex": 4, 
    //     "status": "Active", 
    //     "publicIP": "192.168.1.100", 
    //     "sharedIP": "192.168.1.200", 
    //     "version": "1.2.2", 
    //     "appVersion": "2.2.3", 
    //     "panic": true, 
    //     "routes":[{"Route1", "Route2"}]
    //   }],
    // };
    db = Db('mongodb://localhost:27017/Servidor_Ruteros');
    await db.open();
    //await db.createIndex("hola");
    //print('Consultando con mongoDB');
    return db;
  }



  // Future<Db> connectToRuteroServer() async {
  //   dbRutero = Db('mongodb://localhost:27017/Servidor_Ruteros');
  //   await dbRutero.open();
  // }

  // Future<Db> connectToUsuarios() async {
  //   dbUsuarios = Db('mongodb://localhost:27017/Servidor_Ruteros');
  // }

  // void closeRutero() async {
  //   await dbRutero.close();
  // }

  // void closeUsuarios() async {
  //   await dbUsuarios.close();
  // }

  void close() async {
    await db.close();
  }

}