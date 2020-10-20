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

import 'champion.dart';

class ChampionRepository
{
  Map<String, Champion> _id2Champion;

  static final ChampionRepository _singleton = new ChampionRepository._internal();

  factory ChampionRepository()
  {
    return _singleton;
  }

  ChampionRepository._internal()
  {
    init();
  }

  Future<String> _loadFile() {
    return rootBundle.loadString('assets/data/champ2id.json');
  }

  init() async
  {
//    assert(_int2Item == null);
//    print("int2item aint null");
    var _fileContents = _loadFile();
    var id2String = jsonDecode(await _fileContents);

//    _id2Item = id2String.map((k,v) => MapEntry(k, Item(id: k, name: v)));
    _id2Champion = Map<String, Champion>();
    id2String.forEach((k,v) {_id2Champion[v["id"].toString()] = Champion(id: v["id"].toString(), name: v["name"]);});
  }

  Future<Champion> getChamp(String id) async
  {
    if(_id2Champion == null)
      await init();
    assert(_id2Champion is Map);
    assert(_id2Champion["0"].name == "Empty");

    if(_id2Champion.containsKey(id))
      return _id2Champion[id];
    else
      return Champion(id: "0", name: "No champ");
  }
}
