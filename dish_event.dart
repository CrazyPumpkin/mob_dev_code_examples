part of 'dish_bloc.dart';

@immutable
abstract class DishEvent {}

class FetchEvent extends DishEvent {}

class AddEvent extends DishEvent {
  final String name;
  final String subName;
  final String description;
  final String price;
  final DishCategoryName categoryName;

  AddEvent({
    this.description,
    this.name,
    this.price,
    this.subName,
    this.categoryName,
  });
}

class ChangedCategoryEvent extends DishEvent {
  final DishCategoryName categoryName;

  ChangedCategoryEvent(this.categoryName);
}

class UpdateEvent extends DishEvent {
  final String id;
  final String name;
  final String subName;
  final String description;
  final String price;
  final String dishUrl;
  final DishCategoryName categoryName;

  UpdateEvent({
    @required this.dishUrl,
    this.description,
    this.categoryName,
    this.id,
    this.name,
    this.price,
    this.subName,
  });
}

class OnClickEvent extends DishEvent {}

class OnClearPicEvent extends DishEvent {}

class DeleteEvent extends DishEvent {
  final String id;

  DeleteEvent(this.id);
}

class EditSetupEvent extends DishEvent {
  final Dish dish;

  EditSetupEvent(this.dish);
}
