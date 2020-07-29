import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';

class AdmonDB{
  Db db;
  DbCollection  collBus;

  Future<Db> connectToDataBase() async {
    db = Db('mongodb://localhost:27017/test');
    await db.open();
    //print('Consultando con mongoDB');
    return db;
  }

  void close() async {
    await db.close();
  }

}