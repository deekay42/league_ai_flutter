// Copyright 2018-present the Flutter authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async' show Future;
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'item.dart';

class ItemsRepository
{
  Map<String, Item> _id2Item;

  static final ItemsRepository _singleton = new ItemsRepository._internal();

  factory ItemsRepository()
  {
    return _singleton;
  }

  ItemsRepository._internal();

  Future<String> _loadFile() {
    return rootBundle.loadString('assets/data/item2id.json');
  }

  init() async
  {
//    assert(_int2Item == null);
//    print("int2item aint null");
    var _fileContents = _loadFile();
    var id2String = jsonDecode(await _fileContents);

//    _id2Item = id2String.map((k,v) => MapEntry(k, Item(id: k, name: v)));
    _id2Item = Map<String, Item>();
    id2String.forEach((k,v) {_id2Item[v["id"].toString()] = Item(id: v["id"].toString(), name: v["name"]);});
  }

  Future<Item> getItem(String id) async
  {
    if(_id2Item == null)
      await init();
    assert(_id2Item is Map);
    assert(_id2Item['1'].name == 'Boots of Speed');

    if(_id2Item.containsKey(id))
      return _id2Item[id];
    else
      return Item(id: "unknown", name: "Unknown");
  }
}
