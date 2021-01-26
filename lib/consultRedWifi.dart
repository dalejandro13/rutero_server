import 'package:tuple/tuple.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rutero_server/adminDB.dart';
import 'package:rutero_server/rutero_server.dart';

class ConsultRedWifi extends ResourceController {
  DbCollection globalCollRedWifi;
  AdmonDB admon = AdmonDB();
  DbCollection globalCollServer, globalCollUser;

  ConsultRedWifi(){
    connectData();
  }

  void connectData() async {
    await admon.connectToRuteroServer().then((datab) {
      globalCollRedWifi = datab.collection('redWifi');
      
    });  
  }
}