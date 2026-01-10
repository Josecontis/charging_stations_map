import 'package:charging_stations/data/controllers/charging_controller.dart';
import 'package:get/get.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ChargingController());
  }
}
