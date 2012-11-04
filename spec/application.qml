/* This file is part of QtQuick for Ruby.
 *
 * QtQuick for Ruby is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * QtQuick for Ruby is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with QtQuick for Ruby.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0

Rectangle {
  width: 100; height: 100; color: "red"
  id: item
  property string hello_string
  property int hello_int
  property double hello_double

  signal qmlSignal(string msg, int bb, double aa)
  signal rubySignal(string msg, int bb, double aa)

  onRubySignal: {
    hello_string = msg
    hello_int = bb
    hello_double = aa
  }
  onWidthChanged: item.qmlSignal("Hello Ruby!", 234, width)
}
