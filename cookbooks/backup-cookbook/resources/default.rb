#
# Copyright (C) 2013 Dan Fruehauf <malkodan@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#

actions :add, :remove

# Name of the backup
attribute :backup_name, :kind_of => String, :name_attribute => true
attribute :cookbook,    :kind_of => String, :default => nil
attribute :template,    :kind_of => String, :default => nil
attribute :params,      :kind_of => Hash,   :default => nil

def initialize(*args)
  super
  @action = :add
end

