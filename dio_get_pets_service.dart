import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pet911/network/exceptions/api_request_exception.dart';
import 'package:pet911/network/models/response/pet.dart';

const PAGE_SIZE = 15;
class DioGetPetsService {
  final Dio dio;

  DioGetPetsService(this.dio);

  ///Send a request to server to get pets from user with [userId].
  ///
  ///If it is succeeded - returns a List of [ResponsePet]
  ///
  ///In case of failure `throws` an instance of [ApiRequestException]
  ///
  ///In case of timeout (no matter, server or client issue) - `throws` a [TimeoutException]
  Future<List<ResponsePet>> getUserPets(BuildContext context, int userId, int pageSize) async {
    try {
      final jsonData = {
        "filters": {
          "user": userId,
          "sortBy": "created_at",
        },
        "pagination": {
          "pageSize": pageSize,
          "page": 0,
          "end": false,
        }
      };

      var res = await dio.post(
        '/pets',
        data: jsonData,
      );
      var body = (res.data as Map);

      final List<ResponsePet> rawPets = [];
      for (var jsonPet in body['pets']) {
        var rawPet = ResponsePet.fromMap(jsonPet);
        rawPets.add(rawPet);
      }

      filterOnNotDisabled(rawPets);
      return rawPets;
    } on DioError catch (e) {
      if (e.type == DioErrorType.connectTimeout ||
          e.type == DioErrorType.sendTimeout ||
          e.type == DioErrorType.receiveTimeout) {
        throw TimeoutException('connection or sending timeout');
      } else if (e.type == DioErrorType.response) {
        throw PetNotExists();
      } else if (e.type == DioErrorType.other) {
        throw OtherException(context);
      } else {
        throw Exception();
      }
    }
  }

  void filterOnNotDisabled(List<ResponsePet> pets) {
    pets.retainWhere((element) => element.status != 4);
  }

  ///Send a request to server to get pets around [latitude], [longitude] with [radius]
  ///
  ///If it is succeeded - returns a List of [ResponsePet]
  ///
  ///In case of failure `throws` an instance of [ApiRequestException]
  ///
  ///In case of timeout (no matter, server or client issue) - `throws` a [TimeoutException]
  Future<List<ResponsePet>> getPetsAround({
    required BuildContext context,
    required double latitude,
    required double longitude,
    int? radius,
    int? animal,
    int? type,
    int? page,
  }) async {
    print(latitude);
    print(longitude);
    try {
      final jsonData = {
        "filters": {
          "latitude": latitude,
          "longitude": longitude,
          "radius": radius ?? 11,
          "sortBy": "date",
          "animal": animal,
          "type": type,
        },
        "pagination": {
          "pageSize": PAGE_SIZE,
          "page": page ?? 0,
          "end": false,
        }
      };

      var res = await dio.post(
        '/pets',
        data: jsonData,
      );

      var body = (res.data as Map);

      final List<ResponsePet> rawPets = [];
      for (var jsonPet in body['pets']) {
        var rawPet = ResponsePet.fromMap(jsonPet);
        rawPets.add(rawPet);
      }
      return rawPets;
    } on DioError catch (e) {
      if (e.type == DioErrorType.connectTimeout ||
          e.type == DioErrorType.sendTimeout ||
          e.type == DioErrorType.receiveTimeout) {
        throw TimeoutException('connection or sending timeout');
      } else if (e.type == DioErrorType.response) {
        throw PetNotExists();
      } else if (e.type == DioErrorType.other) {
        throw OtherException(context);
      } else {
        throw Exception();
      }
    }
  }
}
