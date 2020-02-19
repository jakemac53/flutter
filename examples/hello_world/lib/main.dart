// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'version_fake.dart' if (dart.library.io) 'version_io.dart';

void main() => runApp(Center(child: Text('Hello, world!\nversion:$version', textDirection: TextDirection.ltr)));
