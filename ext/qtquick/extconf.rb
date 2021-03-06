#!/bin/env ruby
require 'mkmf'

# This directive processes the "--with-qt-include" and "--with-qt-lib"
qt_inc, qt_lib = dir_config('qt', '/opt/qt5/include', '/opt/qt5/lib')

# Patch RbConfig to make have_header() use g++:
RbConfig::CONFIG['CPP'].gsub!( RbConfig::CONFIG['CC'], RbConfig::CONFIG['CXX'] )

[
  'QtWidgets/QApplication',
  'QtCore/QString',
  'QtQuick/QQuickView',
  'QtQml/QQmlContext'
].each do |header|
  have_header(header) || raise("header not found: #{header}")
end

['Qt5Core', 'Qt5Qml', 'Qt5Widgets', 'Qt5Gui', 'Qt5Quick'].each do |lib|
  have_library(lib) || raise("library not found: #{lib}")
end

# find_type of mkmf conflicts with FFI
class ::Object
  undef_method(:find_type)
end

ENV['CFLAGS'] = "-I#{qt_inc}"
ENV['LDFLAGS'] = "-Wl,-rpath,#{qt_lib} -L#{qt_lib}"
begin
  load File.expand_path('../../../lib/qtquick/c.rb', __FILE__)
rescue CompilationError => err
  $stderr.puts err.log
rescue LoadError => err
  $stderr.puts err
  $stderr.puts "Library loading failed. Please ensure that #{qt_lib} is in your system library paths or set LD_LIBRARY_PATH accordingly."
else
  # Generate dummy Makefile to avoid extconf error
  create_makefile("qtquick")
end
