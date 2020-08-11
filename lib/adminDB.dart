import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';

class AdmonDB{
  Db dbRuteroServ;
  // Db dbUsuarios;
  // DbCollection collBus;

  Future<Db> connectToRuteroServer() async {
    dbRuteroServ = Db('mongodb://localhost:27017/RuterosDB');
    await dbRuteroServ.open();
    return dbRuteroServ;
  }

  Future<void> close() async {
    await dbRuteroServ.close();
  }

}