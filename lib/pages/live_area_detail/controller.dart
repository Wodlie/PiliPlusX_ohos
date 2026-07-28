import 'dart:math';

import 'package:PiliPlus/http/live.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/live/live_area_list/area_item.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:flutter/material.dart';

class LiveAreaDetailController
    extends CommonListController<List<AreaItem>?, AreaItem> {
  LiveAreaDetailController(this.areaId, this.parentAreaId);
  final dynamic areaId;
  final dynamic parentAreaId;

  late int initialIndex = 0;
  TabController? tabController;
  bool showFirstFrame = false;

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  List<AreaItem>? getDataList(List<AreaItem>? response) {
    if (response?.isNotEmpty == true) {
      initialIndex = max(0, response!.indexWhere((e) => e.id == areaId));
    }
    return response;
  }

  @override
  Future<LoadingState<List<AreaItem>?>> customGetData() =>
      LiveHttp.liveRoomAreaList(parentid: parentAreaId);
}
