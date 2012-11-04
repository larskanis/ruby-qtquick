# This file is part of QtQuick for Ruby.
#
# QtQuick for Ruby is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# QtQuick for Ruby is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with QtQuick for Ruby.  If not, see <http://www.gnu.org/licenses/>.

require 'ffi'
require 'ffi/inline'

module QtQuick
module C
  extend FFI::Inline

  inline 'C++' do |cpp|
    cpp.include 'QtWidgets/QApplication'
    cpp.include 'QtCore/QString'
    cpp.include 'QtQuick/QQuickView'
    cpp.include 'QtQuick/QQuickItem'
    cpp.include 'QtQml/QQmlContext'

    cpp.libraries 'QtCore', 'QtQml', 'QtWidgets', 'QtGui', 'QtQuick'

    cpp.raw IO.read(File.expand_path('../RubyQObject.h', __FILE__))
    cpp.raw IO.read(File.expand_path('../RubyQObject.cpp', __FILE__))

    cpp.function %{
      QApplication *QApplication_new(int *argc, char **argv) {
        return new QApplication(*argc, argv);
      }
    }
    cpp.function %{
      void QApplication_delete(QApplication *qapp) {
        delete qapp;
      }
    }
    cpp.function %{
      int QApplication_exec(QApplication *qapp){
        return qapp->exec();
      }
    }, :blocking => true
    cpp.function %{
      void QApplication_quit(QApplication *qapp){
        qapp->quit();
      }
    }
    cpp.function %{
      void QApplication_processEvents(QApplication *qapp){
        qapp->processEvents();
      }
    }


    cpp.function %{
      QQuickView *QQuickView_new(){
        return new QQuickView();
      }
    }
    cpp.function %{
      void QQuickView_delete(QQuickView *view){
        delete view;
      }
    }
    cpp.function %{
      void QQuickView_setSource(QQuickView *view, char *file){
        view->setSource(QUrl::fromLocalFile(file));
      }
    }
    cpp.function %{
      void QQuickView_show(QQuickView *view){
        view->show();
      }
    }
    cpp.function %{
      QQuickItem *QQuickView_rootObject(QQuickView *view){
        return view->rootObject();
      }
    }
    cpp.function %{
      QQmlContext *QQuickView_rootContext(QQuickView *view){
        return view->rootContext();
      }
    }

    cpp.function %{
      void QQuickItem_delete(QQuickItem *item){
        delete item;
      }
    }
    cpp.function %{
      bool QQuickItem_setProperty(QQuickItem *item, char *key, char *value){
        return item->setProperty(key, value);
      }
    }
    cpp.function %{
      QVariant *QQuickItem_property(QQuickItem *item, char *key){
        return new QVariant(item->property(key));
      }
    }
    cpp.function %{
      bool QQuickItem_emitSignal(QQuickItem *item, char *signal, RubySignalFunc func){
        QByteArray theSignal = QMetaObject::normalizedSignature(signal);
        int signalId = item->metaObject()->indexOfSignal(theSignal);
        if (signalId >= 0) {
            QList<QByteArray> list = item->metaObject()->method(signalId).parameterTypes();
            QVector<const char*> vector(list.size());
            for (int i = 0; i < list.size(); ++i) {
              vector[i] = list.at(i).data();
            }
            void **arguments = (func)(list.size(), vector.data());

            QMetaObject::activate(item, signalId, arguments);
            return true;
        } else {
            return false;
        }
      }
    }

    cpp.function %{
      void QQmlContext_delete(QQmlContext *item){
        delete item;
      }
    }
    cpp.function %{
      void QQmlContext_setContextProperty(QQmlContext *item, char *key, QObject *value){
        return item->setContextProperty(key, value);
      }
    }
    cpp.function %{
      QVariant *QQmlContext_contextProperty(QQmlContext *item, char *key){
        return new QVariant(item->contextProperty(key));
      }
    }

    cpp.function %{
      void QVariant_delete(QVariant *var){
        delete var;
      }
    }
    cpp.function %{
      const char *QVariant_typeName(QVariant *var){
        return var->typeName();
      }
    }, :return=>:string
    cpp.function %{
      const char *QVariant_toString(QVariant *var){
        return var->toString().toUtf8().constData();
      }
    }, :return=>:string
    cpp.function %{
      int QVariant_toInt(QVariant *var){
        return var->toInt();
      }
    }
    cpp.function %{
      double QVariant_toDouble(QVariant *var){
        return var->toDouble();
      }
    }

    cpp.function %{
      QString *QString_new(char *string){
        new QString(string);
      }
    }
    cpp.function %{
      void QString_delete(QString *string){
        delete string;
      }
    }
    cpp.function %{
      const char *QString_toUtf8(QString *string){
        return string->toUtf8().constData();
      }
    }, :return=>:string

    cpp.function %{
      RubyQObject *RubyQObject_new(QObject *parent) {
        return new RubyQObject(parent);
      }
    }
    cpp.function %{
      void RubyQObject_delete(RubyQObject *obj){
        delete obj;
      }
    }
    cpp.eval do
      callback :ruby_slot_callback, [:pointer, :int, :pointer, :pointer], :void
      callback :ruby_signal_callback, [:int, :pointer], :pointer
    end
    cpp.map 'RubySlotFunc' => :ruby_slot_callback
    cpp.map 'RubySignalFunc' => :ruby_signal_callback
    cpp.function %{
      bool RubyQObject_connectRubySlot(RubyQObject *obj, QObject *signalObj, char *signal, RubySlotFunc func){
        return obj->connectRubySlot(signalObj, signal, func);
      }
    }
  end
end
end
