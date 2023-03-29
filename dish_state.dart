part of 'dish_bloc.dart';

@immutable
abstract class DishState {}

class DishInitial extends DishState {}

class FetchState extends DishState {
  final List<Dish> dishes;
  FetchState(this.dishes);
}

class FetchLoadingState extends DishState {}

class ErrorState extends DishState {
  final String message;

  ErrorState(this.message);
}

class ImageChosenState extends DishState {
  final String path;

  ImageChosenState(this.path);
}

class ClearImageState extends DishState{}
