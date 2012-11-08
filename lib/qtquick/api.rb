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
module TypeConverter
  private
  def cpp_to_ruby(typeName, ptr)
    case typeName
      when 'QString' then QString.new(ptr, borrowed: true).to_str
      when 'int' then ptr.read_int
      when 'double' then ptr.read_double
      else raise "Type #{typeName} not implemented"
    end
  end
end

class CppObject
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

class QGuiApplication < CppObject
  def initialize(ptr_or_argv, params={})
    @ptr = if ptr_or_argv.kind_of?(FFI::Pointer)
      ptr_or_argv
    else
      @ary_ptr = FFI::MemoryPointer.new :pointer, ptr_or_argv.length+1
      @ary_strings = ptr_or_argv.map{|arg| FFI::MemoryPointer.from_string arg }
      @ary_ptr.write_array_of_pointer(@ary_strings)
      @argc_ptr = FFI::MemoryPointer.new :int
      @argc_ptr.write_int @ary_strings.length
      C.QGuiApplication_new(@argc_ptr, @ary_ptr)
    end
    on_delete(:QGuiApplication_delete) unless params[:borrowed]
  end

  def exec
    C.QGuiApplication_exec(@ptr)
  end
  def quit
    C.QGuiApplication_quit(@ptr)
  end
  def processEvents
    C.QGuiApplication_processEvents(@ptr)
  end
end

class QQuickView < CppObject
  def initialize(ptr=nil, params={})
    @ptr = if ptr.kind_of?(FFI::Pointer)
      ptr
    else
      C.QQuickView_new
    end
    on_delete(:QQuickView_delete) unless params[:borrowed]
  end

  def setSource(file)
    C.QQuickView_setSource(@ptr, file)
  end

  def show
    C.QQuickView_show(@ptr)
  end

  def rootObject
    QQuickItem.new C.QQuickView_rootObject(@ptr), borrowed: true
  end

  def rootContext
    QQmlContext.new C.QQuickView_rootContext(@ptr), borrowed: true
  end
end

class QQuickItem < CppObject
  include TypeConverter

  def initialize(ptr_or_parent=nil, params={})
    @ptr = if ptr_or_parent.kind_of?(FFI::Pointer)
      ptr_or_parent
    else
      C.QQuickItem_new(ptr_or_parent && ptr_or_parent.ptr)
    end
    on_delete(:QQuickItem_delete) unless params[:borrowed]
  end

  def setProperty(name, value)
    C.QQuickItem_setProperty(@ptr, name, value.to_s)
  end

  def property(name)
    qvar = QVariant.new C.QQuickItem_property(@ptr, name)
    case typename=qvar.typeName
      when 'QColor' then qvar.to_str
      else cpp_to_ruby(typename, qvar.ptr)
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

class QQmlContext < CppObject
  def initialize(ptr_or_engine, params={})
    @ptr = if ptr_or_parent.kind_of?(FFI::Pointer)
      ptr_or_parent
    else
      C.QQmlContext_new(ptr_or_engine.ptr)
    end
    on_delete(:QQmlContext_delete) unless params[:borrowed]
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

class QString < CppObject
  def initialize(ptr_or_string, params={})
    @ptr = if ptr_or_string.kind_of?(FFI::Pointer)
      ptr_or_string
    else
      C.QString_new ptr_or_string
    end
    on_delete(:QString_delete) unless params[:borrowed]
  end

  def to_str
    qcs = C.QString_toCharString(@ptr)
    qcs[:p].read_bytes(qcs[:l]*2).force_encoding(Encoding::UTF_16LE).encode!(Encoding::UTF_8)
  end
  alias to_s to_str
end

class QVariant < CppObject
  def initialize(ptr=nil, params={})
    @ptr = if ptr.kind_of?(FFI::Pointer)
      ptr
    else
      C.QVariant_new
    end
    on_delete(:QVariant_delete) unless params[:borrowed]
  end

  def typeName
    C.QVariant_typeName(@ptr)
  end

  def to_str
    QString.new(C.QVariant_toQString(@ptr)).to_str
  end
  alias to_s to_str

  def to_i
    C.QVariant_toInt(@ptr)
  end

  def to_f
    C.QVariant_toDouble(@ptr)
  end
end

class RubyQObject < CppObject
  include TypeConverter

  def initialize(ptr_or_parent=nil, params={})
    @ptr = if ptr_or_parent.kind_of?(FFI::Pointer)
      ptr_or_parent
    else
      C.RubyQObject_new(ptr_or_parent)
    end
    on_delete(:RubyQObject_delete) unless params[:borrowed]
    @procs = {}
  end

  def connectRubySlot(obj, signal)
    block = proc do |sender, argc, pargtypes, pargs|
      argtypes = pargtypes.get_array_of_string(0, argc)
      args = argtypes.map.with_index(1) do |argtype, argi|
        offset = argi * FFI.type_size(:pointer)
        cpp_to_ruby(argtype, pargs.get_pointer(offset))
      end
      yield QQuickItem.new(sender, borrowed: true), *args
    end
    @procs[[obj.ptr, signal]] = block
    C.RubyQObject_connectRubySlot(@ptr, obj.ptr, signal, block)
  end
end
end
