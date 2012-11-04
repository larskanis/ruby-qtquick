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

bool RubyQObject::connectRubySlot(QObject *obj, char *signal, RubySlotFunc func)
{
    QByteArray theSignal = QMetaObject::normalizedSignature(signal);
    int signalId = obj->metaObject()->indexOfSignal(theSignal);
    if (signalId < 0)
        return false;

    int slotId = slotList.size();
    struct RubySlotParams slotparams = {
      func,
      obj->metaObject()->method(signalId).parameterTypes()
    };
    slotList.append(slotparams);

    return QMetaObject::connect(obj, signalId, this, slotId + metaObject()->methodCount());
}

int RubyQObject::qt_metacall(QMetaObject::Call c, int gid, void **arguments)
{
  int id = QObject::qt_metacall(c, gid, arguments);
  if (id < 0 || c != QMetaObject::InvokeMetaMethod){
    return id;
  }
  Q_ASSERT(id < slotList.size());

  RubySlotParams slotparams = slotList[id];
  QList<QByteArray> list = slotparams.parameterTypes;
  QVector<const char*> vector(list.size());
  for (int i = 0; i < list.size(); ++i) {
    vector[i] = list.at(i).data();
  }
  (slotparams.func)(sender(), list.size(), vector.data(), arguments);

  return -1;
}
