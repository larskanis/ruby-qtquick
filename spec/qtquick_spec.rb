# -*- coding: UTF-8 -*-
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

require 'qtquick'

describe QtQuick do
  before(:each) do
    $qapp ||= QtQuick::QApplication.new(['testprog'])
    @qquick_view = QtQuick::QQuickView.new
#     @qquick_view.show
    @qquick_view.setSource(File.expand_path('../application.qml', __FILE__))
  end

  after(:each) do
    @qquick_view.destroy
#     $qapp.destroy
  end

  it 'should provide property getter+setter' do
    @qquick_view.setProperty('resizeMode', 1).should be_true
    @qquick_view.property('resizeMode').should == 1

    qquick_item = @qquick_view.rootObject
    qquick_item.property("color").should == '#ff0000'
    qquick_item.setProperty("color", "blue").should be_true
    qquick_item.property("color").should == '#0000ff'
    qquick_item.setProperty("width", 120.3).should be_true
    qquick_item.property("width").should be_within(0.1).of(120.3)
  end

  it 'should allow receiving signals from QML to Ruby' do
    qquick_item = @qquick_view.rootObject

    args = nil
    qquick_item.onSignal 'qmlSignal(QString, int, double)' do |sender, msg, int, double|
      args = [msg, int, double]
    end
    qquick_item.setProperty("width", 10).should be_true
    args.should == ['Hello Ruby! 人', 234, 10.0]
  end

  it 'should allow sending signals from Ruby to QML' do
    qquick_item = @qquick_view.rootObject
    qquick_item.emit 'rubySignal(QString, int, double)', 'Hello QML! 人', 678, 345.2
    qquick_item.property("hello_string").should == 'Hello QML! 人'
    qquick_item.property("hello_int").should == 678
    qquick_item.property("hello_double").should be_within(0.1).of(345.2)
  end
end
