#!/bin/env ruby

require 'fileutils'
require 'mkmf'

# This directive processes the "--with-fox-include" and "--with-fox-lib"
# command line switches and modifies the CFLAGS and LDFLAGS accordingly.

dir_config('qt', '/opt/qt5/include', '/opt/qt5/lib')

[
  'QtWidgets/QApplication',
  'QtWidgets/QApplication',
  'QtCore/QString',
  'QtQuick/QQuickView',
  'QtQuick/QQuickItem',
].each do |header|
#   have_header(header) || raise("header not found: #{header}")
end

['QtCore', 'QtQml', 'QtWidgets', 'QtGui', 'QtQuick'].each do |lib|
  have_library( lib ) && append_library( $libs, lib )
end

# Last step: build the makefile
create_makefile("qtquick")
