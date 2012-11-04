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
#ifndef RUBYQOBJECT_H
#define RUBYQOBJECT_H

#include <QtCore/QList>
#include <QtCore/QMetaObject>
#include <QtCore/QObject>

typedef void (*RubySlotFunc)(QObject *, int, const char **, void **);
typedef void **(*RubySignalFunc)(int, const char **);

struct RubySlotParams
{
  RubySlotFunc func;
  QList<QByteArray> parameterTypes;
};

class RubyQObject: public QObject
{
public:
    RubyQObject(QObject *parent = 0) : QObject(parent) { }

    virtual int qt_metacall(QMetaObject::Call c, int id, void **arguments);
    bool connectRubySlot(QObject *obj, char *signal, RubySlotFunc func);

private:
    QList<RubySlotParams> slotList;
};

#endif
