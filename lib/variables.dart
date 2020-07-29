class Variables{

  String nm, ipAdrr; 
  bool isConn;
  int connScreen;

  int actualRtIn;
  bool isPendCh, isChg;
  List<int> newRtInx = [];

  bool availUpdate, updateReq;
  List<bool> updt = [];

  double lat, long, vel;

  String get name => nm;
  set name(String val){
    nm = val;
  }

  String get ip => ipAdrr;
  set ip(String val){
    ipAdrr = val;
  }

  bool get isConnected => isConn;
  set isConnected(bool val){
    isConn = val;
  }

  int get connectedScreen => connScreen;
  set connectedScreen(int val){
    connScreen = val;
  }

  int get actualRouteIndex => actualRtIn;
  set actualRouteIndex(int val){
    actualRtIn = val;
  }

  bool get isPendingChange => isPendCh;
  set isPendingChange(bool val){
    isPendCh = val;
  }

  List<int> get newRouteIndex => newRtInx;
  set newRouteIndex(List<int> val){
    newRtInx = val;
  }

  bool get isChange => isChg;
  set isChange(bool val){
    isChg = val;
  }

  bool get availableUpdate => availUpdate;
  set availableUpdate(bool val){
    availUpdate = val;
  }

  bool get updateRequired => updateReq;
  set updateRequired(bool val){
    updateReq = val;
  }

  List<bool> get updated => updt;
  set updated(List<bool> val){
    updt = val;
  }

  double get latitude => lat;
  set latit(double val) {
    lat = val;
  }

  double get longitude => long;
  set longit(double val){
    long = val;
  }

  double get velocity => vel;
  set velocity(double val){
    vel = val;
  }

}