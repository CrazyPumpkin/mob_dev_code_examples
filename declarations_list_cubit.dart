import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:pet911/entities/animal.dart';
import 'package:pet911/entities/declaration.dart';
import 'package:pet911/entities/declaration_type.dart';
import 'package:pet911/entities/promotion_status.dart';
import 'package:pet911/network/dio_get_pets_service.dart';
import 'package:pet911/network/models/response/pet.dart';
import 'package:pet911/services/user_wrapper.dart';
import 'package:pet911/ui/map_with_filters/provider/aggregate_filter_data.dart';
import 'package:pet911/utils/declaration_from_response_parser.dart';
import 'package:rxdart/rxdart.dart';

part 'declarations_list_state.dart';

class DeclarationsListBloc
    extends Bloc<FetchDeclarationEvent, DeclarationsListState> {
  final DioGetPetsService petService;
  final UserService userService;
  int currentPage = -1;

  @override
  Stream<Transition<FetchDeclarationEvent, DeclarationsListState>>
      transformEvents(Stream<FetchDeclarationEvent> events, transitionFn) {
    return super.transformEvents(
      events.debounceTime(const Duration(milliseconds: 500)),
      transitionFn,
    );
  }

  DeclarationsListBloc({
    required this.userService,
    required this.petService,
  }) : super(DeclarationsListInitial());
  @override
  Stream<DeclarationsListState> mapEventToState(
      FetchDeclarationEvent event) async* {
    currentPage++;
    List<ResponsePet> responsePets = [];
    if (event.searching) {
      var animal =
          event.data.animal != null ? event.data.animal!.toApiValue() : null;
      var type = event.data.declarationType != null
          ? event.data.declarationType!.toApiValue()
          : null;
      responsePets = await petService.getPetsAround(
        context: event.context,
        latitude: event.data.location.latitude,
        longitude: event.data.location.longitude,
        radius: event.data.radius,
        animal: animal,
        type: type,
        page: currentPage,
      );
    } else {
      try {
        final user = userService.user;
        if (user != null) {
          final lastResponsePet =
              await petService.getUserPets(event.context, user.id, 20);
          final lastDeclaration = lastResponsePet
              .map(
                (e) => DeclarationFromResponsePetParser.fromResponsePet(
                  e,
                  isMy: false,
                ),
              )
              .toList();
          if (lastDeclaration.isNotEmpty) {
            responsePets = await petService.getPetsAround(
              context: event.context,
              latitude: event.data.location.latitude,
              longitude: event.data.location.longitude,
              radius: event.data.radius,
              animal: lastDeclaration.first.pet.animal.toApiValue(),
              type: lastDeclaration.first.type.invert().toApiValue(),
              page: currentPage,
            );
          } else if (event.data.animal != null ||
              event.data.declarationType != null) {
            var animal = event.data.animal != null
                ? event.data.animal!.toApiValue()
                : null;
            var type = event.data.declarationType != null
                ? event.data.declarationType!.toApiValue()
                : null;
            responsePets = await petService.getPetsAround(
              context: event.context,
              latitude: event.data.location.latitude,
              longitude: event.data.location.longitude,
              radius: event.data.radius,
              animal: animal,
              type: type,
              page: currentPage,
            );
          } else {
            responsePets = await petService.getPetsAround(
              context: event.context,
              latitude: event.data.location.latitude,
              longitude: event.data.location.longitude,
              radius: event.data.radius,
              page: currentPage,
            );
          }
        } else {
          if (event.data.animal != null || event.data.declarationType != null) {
            var animal = event.data.animal != null
                ? event.data.animal!.toApiValue()
                : null;
            var type = event.data.declarationType != null
                ? event.data.declarationType!.toApiValue()
                : null;
            responsePets = await petService.getPetsAround(
              context: event.context,
              latitude: event.data.location.latitude,
              longitude: event.data.location.longitude,
              radius: event.data.radius,
              animal: animal,
              type: type,
              page: currentPage,
            );
          } else {
            responsePets = await petService.getPetsAround(
              context: event.context,
              latitude: event.data.location.latitude,
              longitude: event.data.location.longitude,
              radius: event.data.radius,
              page: currentPage,
            );
          }
        }
      } on Exception catch (e) {
        emit(DeclarationsListFailed(errorMessage: e.toString()));
      }
    }
    final declarations = responsePets
        .map(
          (e) => DeclarationFromResponsePetParser.fromResponsePet(
            e,
            isMy: false,
          ),
        )
        .toList();
    final oldDeclarations = state is DeclarationsListInitial
        ? <Declaration>[]
        : (state as DeclarationsListReceived).declarations;
    final allDeclarations = oldDeclarations + declarations;
    List<Declaration> promotedThenNotPromoted = [];
    List<Declaration> notPromoted = [];
    allDeclarations.forEach((element) {
      if (element.promotionStatus == PromotionStatus.None) {
        notPromoted.add(element);
      } else {
        promotedThenNotPromoted.add(element);
      }
    });
    promotedThenNotPromoted.addAll(notPromoted);
    emit(
        DeclarationsListReceived(declarations: promotedThenNotPromoted, hasReachedEnd: declarations.length < PAGE_SIZE));
  }
}

class FetchDeclarationEvent {
  final BuildContext context;
  final AggregateFilterData data;
  final bool searching;

  FetchDeclarationEvent(this.context, this.data, this.searching);
}
