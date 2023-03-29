import 'dart:io';

import 'package:admin_app/business_logic/dish_bloc/dish_bloc.dart';
import 'package:admin_app/categories.dart';
import 'package:admin_app/classes/dish_category.dart';
import 'package:admin_app/responsive_size.dart';
import 'package:admin_app/ui/main_menu_page/widgets/dish_card.dart';
import 'package:admin_app/ui/main_menu_page/widgets/name_block.dart';
import 'package:admin_app/ui/main_menu_page/widgets/categories_list.dart';
import 'package:admin_app/ui/main_menu_page/widgets/upper_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class MainMenuPage extends StatefulWidget {
  @override
  _MainMenuPageState createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  int _selectedIndex = 0;
  void _onCategoryChanged(int index) {
    _selectedIndex = index;
    BlocProvider.of<DishBloc>(context)
        .add(ChangedCategoryEvent(DishCategoryName.values[index]));
  }

  @override
  Widget build(BuildContext context) {
    final RefreshController _refreshController =
        RefreshController(initialRefresh: false);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: SafeArea(
        child: Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          floatingActionButton: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed(
                '/item_add',
              );
            },
            child: Text(
              "Добавить",
              style: TextStyle(fontSize: 12),
            ),
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          body: Column(
            children: [
              UpperIcons(),
              Expanded(
                child: SmartRefresher(
                  header: Platform.isAndroid
                      ? MaterialClassicHeader()
                      : ClassicHeader(
                          refreshingIcon: CupertinoActivityIndicator(),
                          refreshingText: '',
                          releaseIcon: CupertinoActivityIndicator(),
                          releaseText: '',
                          completeIcon: CupertinoActivityIndicator(),
                          completeText: '',
                          idleIcon: null,
                          idleText: '',
                        ),
                  controller: _refreshController,
                  onRefresh: () {
                    BlocProvider.of<DishBloc>(context).add(FetchEvent());
                    _refreshController.refreshCompleted();
                  },
                  child: CustomScrollView(
                    physics: BouncingScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        backgroundColor: Colors.white,
                        floating: true,
                        expandedHeight:
                            ResponsiveSize.responsiveHeight(240, context),
                        flexibleSpace: FlexibleSpaceBar(
                          background: Column(
                            children: [
                              SizedBox(
                                height: ResponsiveSize.responsiveHeight(
                                    25, context),
                              ),
                              const NameBlock(),
                              SizedBox(
                                height: ResponsiveSize.responsiveHeight(
                                    33, context),
                              ),
                              BlocBuilder<DishBloc, DishState>(
                                buildWhen: (prev, curr) => curr is FetchState,
                                builder: (context, state) {
                                  return CategoriesList(
                                    currentIndex: _selectedIndex,
                                    itemTapped: _onCategoryChanged,
                                    items: Categories.categories,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      BlocBuilder<DishBloc, DishState>(
                        buildWhen: (previous, current) =>
                            current is! ErrorState &&
                            current is! ClearImageState &&
                            current is! ImageChosenState,
                        builder: (context, state) {
                          if (state is FetchLoadingState) {
                            return SliverToBoxAdapter(
                              child: Container(
                                alignment: Alignment.center,
                                padding: EdgeInsets.only(
                                  top: ResponsiveSize.responsiveHeight(
                                      20, context),
                                ),
                                child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation(
                                        Theme.of(context).primaryColor)),
                              ),
                            );
                          } else if (state is FetchState) {
                            return SliverList(
                              delegate: SliverChildListDelegate.fixed(
                                state.dishes.length > 0
                                    ? state.dishes
                                        .map(
                                          (e) => Column(
                                            children: [
                                              DishCard(
                                                dish: e,
                                              ),
                                              SizedBox(
                                                height: ResponsiveSize
                                                    .responsiveHeight(
                                                  16,
                                                  context,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                        .toList()
                                    : [
                                        Padding(
                                          padding: EdgeInsets.only(
                                            top:
                                                ResponsiveSize.responsiveHeight(
                                                    50, context),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "Ничего не найдено",
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyText1
                                                    .color,
                                                fontFamily: Theme.of(context)
                                                    .textTheme
                                                    .bodyText1
                                                    .fontFamily,
                                                fontSize: ResponsiveSize
                                                    .responsiveHeight(
                                                  18,
                                                  context,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                              ),
                            );
                          }
                          return SliverToBoxAdapter(
                            child: Center(
                              child: Text('Упс'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
