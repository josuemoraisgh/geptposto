import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'modelsView/home_build_navegator.dart';
import 'modelsView/home_build_tag_page.dart';
import 'home_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final controller = Modular.get<HomeController>();
  @override
  void initState() {
    controller.ctrl.addListener(() {
      int? next = controller.ctrl.page?.round();
      if (controller.currentPage != next) {
        setState(() {
          controller.currentPage = next!;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            "assets/images/background.png",
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: ValueListenableBuilder(
          valueListenable: controller.listaTelas,
          builder: (BuildContext context, List<Map<String, dynamic>> slideList,
              Widget? child) {
            return PageView.builder(
                controller: controller.ctrl,
                itemCount: slideList.length + 1,
                itemBuilder: (context, int currentIdx) {
                  if ((currentIdx == 0) || (slideList.length < currentIdx)) {
                    return BuildTagPage(
                      activeTagButtom: controller.activeTagButtom,
                      listaTelas: controller.listaTelas,
                    );
                  } else {
                    slideList[currentIdx - 1]['active'] =
                        currentIdx == controller.currentPage ? 1 : 0;
                    return BuildNavegatorPage(
                      data: slideList[currentIdx - 1],
                      state: controller.state,
                    );
                  }
                });
          }),
    ));
  }
}
