import 'package:admin_app/classes/dish.dart';
import 'package:admin_app/classes/dish_category.dart';
import 'package:admin_app/classes/extensions.dart';
import 'package:admin_app/repos/fb_storage.dart';
import 'package:admin_app/services/id_generator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

part 'dish_event.dart';
part 'dish_state.dart';

class DishBloc extends Bloc<DishEvent, DishState> {
  final FirebaseFirestore _firebaseFirestore;
  DishCategoryName _selectedCategory = DishCategoryName.all;
  List<Dish> _dishes = [];
  String _selectedPicturePath;
  DishBloc(this._firebaseFirestore) : super(DishInitial()) {
    on<FetchEvent>(_onFetch);
    on<UpdateEvent>(_onUpdate);
    on<AddEvent>(_onAdd);
    on<ChangedCategoryEvent>(_onCategoryChanged);
    on<OnClickEvent>(_onClick);
    on<OnClearPicEvent>(_onClearPic);
    on<DeleteEvent>(_onDelete);
    on<EditSetupEvent>(_onEditSetup);
  }
  Future<void> _onFetch(FetchEvent event, Emitter emit) async {
    _dishes.clear();
    emit(FetchLoadingState());
    try {
      var rawDishes = await _firebaseFirestore.collection('dishes').get();
      for (var i = 0; i < rawDishes.docs.length; i++) {
        var item = rawDishes.docs[i];
        var data = item.data();
        var url = await FileStorage.downloadPath(item.id);
        data.addAll({
          'image_url': url,
        });
        final dish = Dish.fromJson(data, item.id);
        _dishes.add(dish);
      }

      if (_selectedCategory == DishCategoryName.all) {
        emit(FetchState(_dishes));
        return;
      }
      final dishes = _dishes
          .where((element) => element.category == _selectedCategory)
          .toList();
      emit(FetchState(dishes));
    } catch (e) {
      emit(ErrorState('Произошла ошибка при загрузке блюд'));
    }
  }

  void _onCategoryChanged(ChangedCategoryEvent event, Emitter emit) {
    _selectedCategory = event.categoryName;
    if (_selectedCategory == DishCategoryName.all) {
      emit(FetchState(_dishes));
      return;
    }

    final dishes =
        _dishes.where((element) => element.category == _selectedCategory);
    emit(FetchState(dishes.toList()));
  }

  Future<void> _onUpdate(UpdateEvent event, Emitter emit) async {
    final name = event.name;
    final subName = event.subName;
    final price = event.price;
    final description = event.description;
    if (!_validate(name, subName, description, price)) {
      emit(ErrorState('Заполните все поля'));
      return;
    }
    if (_selectedPicturePath == null) {
      emit(ErrorState('Добавьте фотографию'));
      return;
    }
    emit(FetchLoadingState());
    var map = Dish.toJson(
      name: name.trim(),
      subName: subName.trim(),
      price: price.trim(),
      description: description.trim(),
      categoryName: event.categoryName,
    );
    if (_selectedPicturePath != event.dishUrl) {
      await FileStorage.deleteCurrent(event.id);
      await FileStorage.uploadImage(path: _selectedPicturePath, name: event.id);
    }
    await _firebaseFirestore.collection('dishes').doc(event.id).update(map);
    _selectedPicturePath = null;
    add(FetchEvent());
  }

  Future<void> _onDelete(DeleteEvent event, Emitter emit) async {
    await _firebaseFirestore.collection('dishes').doc(event.id).delete();
    await FileStorage.deleteCurrent(event.id);
    add(FetchEvent());
  }

  Future<void> _onAdd(AddEvent event, Emitter emit) async {
    final name = event.name;
    final subName = event.subName;
    final price = event.price;
    final description = event.description;

    if (!_validate(name, subName, description, price)) {
      emit(ErrorState('Заполните все поля'));
      return;
    }
    if (_selectedPicturePath == null) {
      emit(ErrorState('Добавьте фотографию'));
      return;
    }
    emit(FetchLoadingState());
    var id = IdGenerator.getRandomString(length: 15);
    var map = Dish.toJson(
      add: true,
      name: name.trim(),
      subName: subName.trim(),
      price: price.trim(),
      description: description.trim(),
      categoryName: event.categoryName,
    );

    await FileStorage.uploadImage(path: _selectedPicturePath, name: id);
    await _firebaseFirestore.collection('dishes').doc(id).set(map);
    _selectedPicturePath = null;
    add(FetchEvent());
  }

  void _onEditSetup(EditSetupEvent event, Emitter emit) {
    _selectedPicturePath = event.dish.image;
  }

  Future<void> _onClick(OnClickEvent event, Emitter emit) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
    );
    if (result == null) {
      _selectedPicturePath = null;
      return;
    }
    final path = result.files.single.path;
    _selectedPicturePath = path;
    emit(ImageChosenState(path));
  }

  void _onClearPic(OnClearPicEvent event, Emitter emit) {
    _selectedPicturePath = null;
    emit(ClearImageState());
  }

  bool _validate(
      String name, String subName, String description, String price) {
    return !name.isNullOrEmpty &&
        !subName.isNullOrEmpty &&
        !description.isNullOrEmpty &&
        !price.isNullOrEmpty;
  }
}
