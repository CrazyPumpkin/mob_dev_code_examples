import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pet911/entities/declaration_list_params.dart';
import 'package:pet911/entities/map_marker_mode.dart';
import 'package:pet911/main.dart';
import 'package:pet911/network/dio_get_pets_service.dart';
import 'package:pet911/services/dio_service.dart';
import 'package:pet911/services/geo_service.dart';
import 'package:pet911/services/location_service.dart';
import 'package:pet911/services/user_wrapper.dart';
import 'package:pet911/ui/common_widgets/google_map/map_controller_factory.dart';
import 'package:pet911/ui/common_widgets/google_map/pet_map_controller.dart';
import 'package:pet911/ui/map_with_declarations/map_camera_position_cubit/map_camera_position_cubit.dart';
import 'package:pet911/ui/map_with_declarations/map_with_declarations_page_view.dart';
import 'package:pet911/ui/map_with_declarations/widgets/scrollbar_controller.dart';
import 'package:pet911/ui/map_with_filters/provider/aggregate_filter_data.dart';
import 'package:pet911/utils/map_helper.dart';
import 'package:pet911/utils/responsive_size.dart';
import 'package:provider/provider.dart';

import 'declarations_list_cubit/declarations_list_cubit.dart';

class MapWithDeclarationsPage extends StatefulWidget {
  final AggregateFilterData data;
  final bool containsLeading;
  final Widget? title;
  final LatLng? initialCameraPosition;
  final Widget filterTitle;
  final bool searching;
  final double? zoom;

  MapWithDeclarationsPage({
    this.title,
    required this.data,
    this.containsLeading = false,
    this.initialCameraPosition,
    required this.filterTitle,
    this.searching = false,
    this.zoom,
  });

  @override
  _MapWithDeclarationsPageState createState() =>
      _MapWithDeclarationsPageState();
}

class _MapWithDeclarationsPageState extends State<MapWithDeclarationsPage>
    with MapHelper {
  @override
  void initState() {
    geoService = getIt<GeoService>();
    super.initState();
  }

  late double currentPullerPosition;

  late double initialPullerPosition;

  @protected
  @mustCallSuper
  void didChangeDependencies() {
    initialPullerPosition = 527.height;
    currentPullerPosition = 527.height;

    super.didChangeDependencies();
  }

  Future<String> getLocationAddress(LatLng location) async {
    var place = await geoService.getAddressFromLatLng(location);
    return '${place.address}, ${place.city}';
  }

  late GeoService geoService;
  @override
  Widget build(BuildContext context) {
    var locationService = getIt<LocationService>();

    return ChangeNotifierProvider(
      create: (context) => ScrollbarController(0.25),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<DeclarationsListBloc>(
            create: (context) => DeclarationsListBloc(
              //data: widget.data,
              petService: DioGetPetsService(getIt<DioService>().client),
              userService: getIt.get<UserService>(),
            ),
          ),
          BlocProvider<MapCameraPositionCubit>(
            create: (context) => MapCameraPositionCubit(
              petService: DioGetPetsService(getIt<DioService>().client),
              userService: getIt.get<UserService>(),
              locationService: locationService,
            )..setInitialCameraPosition(context),
          ),
        ],
        child: Builder(
          builder: (context) => ChangeNotifierProvider(
            create: (_) => MapControllerFactory().getController(
              mode: MapMarkerMode.Pets,
              declarations: [],
              locationService: getIt<LocationService>(),
              geoService: geoService,
              onMapCreated: onMapCreated,
            ) as PetMapController,
            child: BlocBuilder<MapCameraPositionCubit, MapCameraPositionState>(
              builder: (context, state) {
                if (state is MapCameraPositionReceived) {
                  LatLng position;
                  // по объявлению
                  if (widget.searching) {
                    position = widget.initialCameraPosition!;
                  } else {
                    if (state.position != locationService.currentLocation) {
                      position = state.position;
                    }
                    // по поиску
                    else if (state.position ==
                            locationService.currentLocation &&
                        widget.initialCameraPosition != null) {
                      position = widget.initialCameraPosition!;
                    }
                    // по местоположению
                    else {
                      position = locationService.currentLocation;
                    }
                  }
                  final data = widget.data;

                  final freshData = data.copyWith(
                    location: position,
                    radius: data.radius,
                    animal: data.animal,
                    declarationType: data.declarationType,
                  );

                  context.read<DeclarationsListBloc>().add(
                        FetchDeclarationEvent(
                            context, freshData, widget.searching),
                      );

                  return Provider<DeclarationListParams>(
                    create: (_) =>
                        DeclarationListParams(freshData, widget.searching),
                    child: MapWithDeclarationsPageView(
                      zoom: widget.zoom,
                      filterTitle: widget.filterTitle,
                      currentPullerPosition: currentPullerPosition,
                      initialPullerPosition: initialPullerPosition,
                      containsLeading: widget.containsLeading,
                      title: widget.title ??
                          Container(
                            width: 280.width,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: FutureBuilder<String>(
                                  future:
                                      getLocationAddress(freshData.location),
                                  builder: (context, snap) {
                                    return Text(
                                      snap.data ?? '',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 19.height,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  }),
                            ),
                          ),
                      initialCameraPosition: position,
                    ),
                  );
                }
                return Container();
              },
            ),
          ),
        ),
      ),
    );
  }
}
