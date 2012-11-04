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

module QtQuick
class ManagedPtr
  attr_accessor :ptr
  alias to_ptr ptr

  def destroy
    C.send(@delete_method, @ptr)
    ObjectSpace.undefine_finalizer(self)
  end

  private
  def on_delete(method)
    class << @ptr
      attr_accessor :delete_method
      def delete(id)
        C.send(@delete_method, self)
#         puts "deleted #{id} by #{@delete_method}"
      end
    end
    @ptr.delete_method = @delete_method = method
    ObjectSpace.define_finalizer(self, @ptr.method(:delete))
  end
end

class QApplication < ManagedPtr
  def initialize(argv)
    @ary_ptr = FFI::MemoryPointer.new :pointer, argv.length+1
    @ary_strings = argv.map{|arg| FFI::MemoryPointer.from_string arg }
    @ary_ptr.write_array_of_pointer(@ary_strings)
    @argc_ptr = FFI::MemoryPointer.new :int
    @argc_ptr.write_int @ary_strings.length
    @ptr = C.QApplication_new(@argc_ptr, @ary_ptr)
    on_delete(:QApplication_delete)
  end

  def exec
    C.QApplication_exec(@ptr)
  end
  def quit
    C.QApplication_quit(@ptr)
  end
  def processEvents
    C.QApplication_processEvents(@ptr)
  end
end

class QQuickView < ManagedPtr
  def initialize
    @ptr = C.QQuickView_new
    on_delete(:QQuickView_delete)
  end

  def setSource(file)
    C.QQuickView_setSource(@ptr, file)
  end

  def show
    C.QQuickView_show(@ptr)
  end

  def rootObject
    QQuickItem.new C.QQuickView_rootObject(@ptr)
  end

  def rootContext
    QQmlContext.new C.QQuickView_rootContext(@ptr)
  end
end

class QQuickItem < ManagedPtr
  def initialize(ptr)
    @ptr = ptr
#     on_delete(:QQuickItem_delete)
  end

  def setProperty(name, value)
    C.QQuickItem_setProperty(@ptr, name, value.to_s)
  end

  def property(name)
    qvar = C.QQuickItem_property(@ptr, name)
    case typeName=C.QVariant_typeName( qvar )
      when 'QString' then C.QVariant_toString( qvar )
      when 'QColor' then C.QVariant_toString( qvar )
      when 'int' then C.QVariant_toInt( qvar )
      when 'double' then C.QVariant_toDouble( qvar )
      else raise "QVariant type #{typeName} not implemented"
    end
  end

  def onSignal(signal, &block)
    rqo = RubyQObject.new
    rqo.connectRubySlot self, signal, &block
  end

  def emit(signal, *args)
    pargs = nil
    ptrs = nil
    block = proc do |argc, pargtypes|
      pargs = FFI::MemoryPointer.new :pointer, argc+1
      argtypes = pargtypes.get_array_of_string(0, argc)
      ptrs = argtypes.map.with_index do |argtype, argi|
        case argtype
          when 'QString' then
            ptr = QString.new(args[argi])
          when 'int' then
            ptr = FFI::MemoryPointer.new :int
            ptr.write_int args[argi]
          when 'double' then
            ptr = FFI::MemoryPointer.new :double
            ptr.write_double args[argi]
          else raise "Parameter type #{argtype} not implemented"
          ptr
        end
      end
      pargs.put_array_of_pointer(FFI.type_size(:pointer), ptrs)
      pargs
    end
    C.QQuickItem_emitSignal(@ptr, signal, block)
  end
end

class QQmlContext < ManagedPtr
  def initialize(ptr)
    @ptr = ptr
#     on_delete(:QQmlContext_delete)
  end

  def setContextProperty(name, value)
    C.QQmlContext_setContextProperty(@ptr, name, value.ptr)
  end

  def contextProperty(name)
    qvar = C.QQmlContext_contextProperty(@ptr, name)
    case typeName=C.QVariant_typeName( qvar )
    when ""
    else raise "QVariant type #{typeName} not implemented"
    end
  end
end

class QString < ManagedPtr
  def initialize(string)
    if string.kind_of?(FFI::Pointer)
      @ptr = string
    else
      @ptr = C.QString_new string
      on_delete(:QString_delete)
    end
  end

  def to_str
    C.QString_toUtf8(@ptr)
  end
  alias to_s to_str
end

class RubyQObject < ManagedPtr
  def initialize(parent=nil)
    @ptr = C.RubyQObject_new(parent)
    on_delete(:RubyQObject_delete)
    @procs = {}
  end

  def connectRubySlot(obj, signal)
    block = proc do |sender, argc, pargtypes, pargs|
      argtypes = pargtypes.get_array_of_string(0, argc)
      args = argtypes.map.with_index(1) do |argtype, argi|
        offset = argi * FFI.type_size(:pointer)
        case argtype
          when 'QString' then QString.new(pargs.get_pointer(offset)).to_str
          when 'int' then pargs.get_pointer(offset).read_int
          when 'double' then pargs.get_pointer(offset).read_double
          else raise "Parameter type #{argtype} not implemented"
        end
      end
      yield QQuickItem.new(sender), *args
    end
    @procs[[obj.ptr, signal]] = block
    C.RubyQObject_connectRubySlot(@ptr, obj.ptr, signal, block)
  end
end
end
