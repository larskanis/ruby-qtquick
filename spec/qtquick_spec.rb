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
  before(:all) do
    @qapp = QtQuick::QApplication.new(['testprog'])
  end

  describe QtQuick::QQuickView do
    before(:each) do
      @qquick_view = QtQuick::QQuickView.new
  #     @qquick_view.show
    end

    after(:each) do
      @qquick_view.destroy
    end

    it 'should return nil if no source is loaded' do
      @qquick_view.rootObject.should be_nil
    end

    it 'should provide property getter+setter' do
      @qquick_view.setProperty('resizeMode', 1).should be_true
      @qquick_view.property('resizeMode').should == 1
    end

    describe QtQuick::QQuickItem do
      before(:each) do
        @qquick_view.setSource(File.expand_path('../application.qml', __FILE__))
        @qi = @qquick_view.rootObject
      end

      it 'should provide property getter+setter' do
        @qi.property("color").should == '#ff0000'
        @qi.setProperty("color", "blue").should be_true
        @qi.property("color").should == '#0000ff'
        @qi.setProperty("width", 120.3).should be_true
        @qi.property("width").should be_within(0.1).of(120.3)

        @qi.property("non_existent").should be_nil
        @qi.setProperty("new_int", 42).should be_false
        @qi.property("new_int").should == 42
        @qi.setProperty("new_string", '42').should be_false
        @qi.property("new_string").should == '42'
      end

      it 'should allow receiving signals from QML to Ruby' do
        args = nil
        @qi.onSignal 'qmlSignal(QString, int, double)' do |sender, msg, int, double|
          args = [msg, int, double]
        end
        @qi.setProperty("width", 10).should be_true
        args.should == ['Hello Ruby! 人', 234, 10.0]
      end

      it 'should allow sending signals from Ruby to QML' do
        @qi.emit 'rubySignal(QString, int, double)', 'Hello QML! 人', 678, 345.2
        @qi.property("hello_string").should == 'Hello QML! 人'
        @qi.property("hello_int").should == 678
        @qi.property("hello_double").should be_within(0.1).of(345.2)
      end
    end
  end
end
