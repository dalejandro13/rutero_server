import 'package:aqueduct/aqueduct.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rutero_server/adminDB.dart';

class ConsultServer extends ResourceController {
  DbCollection globalCollUser, globalCollServer, globalCollDevice;
  AdmonDB admon = AdmonDB();
  int numVer, numVer2, numAppVer, numAppVer2, step;
  int numBun, numBun2, numAppBun, numAppBun2;
  int numCom, numCom2, numAppCom, numAppCom2;
  String version, appVersion;
  int point = 0, point2 = 0;
  String getVersionBody = "";
  String getVersionDB = "";
  String getAppVersionBody = "";
  String getAppVersionDB = "";
  bool st = false;

  ConsultServer(){
    connectRuteros();
  }

  void connectRuteros() async {
    await admon.connectToRuteroServer().then((datab) {
      globalCollUser = datab.collection('user');
      globalCollServer = datab.collection('serverApp');
      globalCollDevice = datab.collection('device');
    });   
  }

  @Operation.get() //consulta todo el servidor o consulta todos los usuarios
  Future<Response> getAllUsers() async {//@Bind.path('num') String number) async {
    try{
      var busesList = [];
      await globalCollServer.find().forEach(busesList.add);
      
      if(busesList.length > 0){
        await admon.close();
        return Response.ok(busesList);
      }
      else{
        await admon.close();
        return Response.badRequest(body: {"ERROR": "No hay informacion la base de datos"});
      }
    }
    catch(e){
      await admon.close();
      return Response.badRequest(body: {"ERROR": e.toString()});
    }
  }

  @Operation.put() //actuliza Version y appVersion
  Future<Response> updateVersion() async { //@Bind.path('Version') String getVersion) async {

    await globalCollServer.find().forEach((data) async {
      if(data['version'] != "" && data['appVersion'] != "" && data['version'] != null && data['appVersion'] != null){
        st = true;
      }
    });

    if(st){

      Map<String, dynamic> ver;
      Map<String, dynamic> appVer;
      dynamic vs = null, appVs = null;
      bool gotVersion = false, gotAppVersion = false;
      
      final Map<String, dynamic> body = await request.body.decode();
      vs = body['version'];
      appVs = body['appVersion'];

      if(vs != null){
        version = vs.trim().toString();
        if(version != ""){
          point = ".".allMatches(version).length;
        }
      }

      if(appVs != null){
        appVersion = appVs.trim().toString();
        if(appVersion != ""){
          point2 = ".".allMatches(appVersion).length;
        }
      }

      if(point == 2){
        String acum = "", numVersion = "", numBundle = "", numCompilado = ""; //numero de version . numero de bundle . numero de compilado
        String numVersion2 = "", numBundle2 = "", numCompilado2 = "";
        try{
          if(version != "" && version != null && point == 2){
            await globalCollServer.find().forEach((data) async {
              String versionDB = data['version'].toString();
              String versionBody = version.toString();
              for(int i = 0; i < versionDB.length; i++){
                if(versionDB[i] == "."){
                  if(numVersion == ""){
                    numVersion = acum;
                    acum = "";
                  }
                  else if(numBundle == "" && numVersion != ""){
                    numBundle = acum;
                    acum = "";
                  }
                }
                else{
                  acum += versionDB[i];
                }
              }
              if(numCompilado == "" && numVersion != "" && numBundle != ""){
                numCompilado = acum;
                acum = "";
              }

              for(int j = 0; j < versionBody.length; j++){
                if(versionBody[j] == "."){
                  if(numVersion2 == ""){
                    numVersion2 = acum;
                    acum = "";
                  }
                  else if(numBundle2 == "" && numVersion2 != ""){
                    numBundle2 = acum;
                    acum = "";
                  }
                }
                else{
                  acum += versionBody[j];
                }
              }
              if(numCompilado2 == "" && numVersion2 != "" && numBundle2 != ""){
                numCompilado2 = acum;
                acum = "";
              }
              step = 0;
              //viene de la base de datos
              numVer = int.parse(numVersion);
              numBun = int.parse(numBundle);
              numCom = int.parse(numCompilado);

              //viene de Body
              numVer2 = int.parse(numVersion2);
              numBun2 = int.parse(numBundle2);
              numCom2 = int.parse(numCompilado2);

              if(numCom2 > numCom){
                step++;
              }
              if(numBun2 > numBun){
                step++;
              }
              if(numVer2 > numVer){
                step++;
              }
            });

            if(step >= 1 && step <= 3){
              step = 0;
              getVersionBody = "$numVer2.$numBun2.$numCom2";
              getVersionDB = "$numVer.$numBun.$numCom";
              await changeVersion(1, getVersionBody, getVersionDB);
            }

            if(getVersionBody != ""){
              gotVersion = true;
            }
          }
          else{
            await admon.close();
            return Response.badRequest(body: {"ERROR": "falta informacion en la Version"});
          }
        }
        catch(e){
          print(e);
          await admon.close();
          return Response.badRequest(body: {"ERROR": "intentalo nuevamente"});
        }
      }

      if(point2 == 2){
        String acum = "", numAppVersion = "", numAppBundle = "", numAppCompilado = ""; //numero de version . numero de bundle . numero de compilado
        String numAppVersion2 = "", numAppBundle2 = "", numAppCompilado2 = "";

        try{

        if(appVersion != "" && appVersion != null && point2 == 2){
          await globalCollServer.find().forEach((data) async {
            String appVersionDB = data['appVersion'].toString();
            String appVersionBody = appVersion.toString();

            for(int i = 0; i < appVersionDB.length; i++){
              if(appVersionDB[i] == "."){
                if(numAppVersion == ""){
                  numAppVersion = acum;
                  acum = "";
                }
                else if(numAppBundle == "" && numAppVersion != ""){
                  numAppBundle = acum;
                  acum = "";
                }
              }
              else{
                acum += appVersionDB[i];
              }
            }
            if(numAppCompilado == "" && numAppVersion != "" && numAppBundle != ""){
              numAppCompilado = acum;
              acum = "";
            }

            for(int j = 0; j < appVersionBody.length; j++){
              if(appVersionBody[j] == "."){
                if(numAppVersion2 == ""){
                  numAppVersion2 = acum;
                  acum = "";
                }
                else if(numAppBundle2 == "" && numAppVersion2 != ""){
                  numAppBundle2 = acum;
                  acum = "";
                }
              }
              else{
                acum += appVersionBody[j];
              }
            }
            if(numAppCompilado2 == "" && numAppVersion2 != "" && numAppBundle2 != ""){
              numAppCompilado2 = acum;
              acum = "";
            }
            step = 0;

            //viene de la base de datos
            numAppVer = int.parse(numAppVersion);
            numAppBun = int.parse(numAppBundle);
            numAppCom = int.parse(numAppCompilado);

            //viene del Body
            numAppVer2 = int.parse(numAppVersion2);
            numAppBun2 = int.parse(numAppBundle2);
            numAppCom2 = int.parse(numAppCompilado2);

            if(numAppCom2 > numAppCom){
              step++;
            }
            if(numAppBun2 > numAppBun){
              step++;
            }
            if(numAppVer2 > numAppVer){
              step++;
            }
          });

          if(step >= 1 && step <= 3){
            step = 0;
            getAppVersionBody = "$numAppVer2.$numAppBun2.$numAppCom2";
            getAppVersionDB = "$numAppVer.$numAppBun.$numAppCom";
            await changeVersion(2, getAppVersionBody, getAppVersionDB);
          }

          if(getAppVersionBody != ""){
            gotAppVersion = true;
          }
        }
      }
      catch(e){
        print(e);
        await admon.close();
        return Response.badRequest(body: {"ERROR": "intentalo nuevamente"});
      }
    }

    if(gotVersion == true && gotAppVersion == false){
      await admon.close();
      var body = {"OK":"version: ${getVersionBody}"};
      return Response.ok(body);
    }
    else if(gotVersion == false && gotAppVersion == true){
      await admon.close();
      var body = {"OK":"appVersion: ${getAppVersionBody}"};
      return Response.ok(body);
    }
    else if(gotVersion == false && gotAppVersion == false){
      await admon.close();
      return Response.badRequest(body: {"ERROR": "no se actualizo Version y appVersion"});
    }
    else{
      await admon.close();
      var body = {
        "OK1":"version: ${getVersionBody}",
        "OK2":"appVersion: ${getAppVersionBody}"
      };
      return Response.ok(body);    
    }
  }
  else{
    await admon.close();
    return Response.badRequest(body: {"ERROR": "no se puede guardar la informacion, intentalo nuevamente"});
  }
}


  Future<void> changeVersion(int whatVersion, String getVersionBody, String getVersionDB) async {
    if(whatVersion == 1){
      try{
        var v1 = await globalCollServer.findOne({"version": getVersionDB});
        v1["version"] = getVersionBody;
        await globalCollServer.save(v1);
      }
      catch(e){
        print(e);
      }
    }
    else if(whatVersion == 2){
      try{
        var v1 = await globalCollServer.findOne({"appVersion": getVersionDB});
        v1["appVersion"] = getVersionBody;
        await globalCollServer.save(v1);
      }
      catch(e){
        print(e);
      }
    }
  }

}