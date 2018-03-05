# Copyright (C) 2014-2018  The ruby-gettext project
#
# This library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation, either version 2.1 of the
# License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this program.  If not, see
# <http://www.gnu.org/licenses/>.

base_dir = File.dirname(__FILE__)
lib_dir = File.join(base_dir, "lib")
$LOAD_PATH.unshift(lib_dir)

require "jekyll/task/i18n/version"

Gem::Specification.new do |spec|
  spec.name = "jekyll-task-i18n"
  spec.version = Jekyll::Task::I18n::VERSION.dup

  spec.authors = ["Kouhei Sutou"]
  spec.email = ["kou@clear-code.com"]

  readme_path = File.join(base_dir, "README.md")
  spec.summary = "Preprocessor for Jekyll to support i18n"
  spec.description =
    "jekyll-task-i18n is GitHub pages ready i18n approach for Jekyll."

  spec.files = [
    "README.md",
    "Rakefile",
    "Gemfile",
    "LICENSE.txt",
    ".yardopts",
    "#{spec.name}.gemspec",
  ]
  spec.files += Dir.glob("lib/**/*.rb")
  spec.homepage = "https://github.com/ruby-gettext/jekyll-task-i18n"
  spec.licenses = ["LGPLv2"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency("gettext", ">= 3.2.8")
  spec.add_runtime_dependency("yard")

  spec.add_development_dependency("rake")
  spec.add_development_dependency("bundler")
  spec.add_development_dependency("packnga")
  spec.add_development_dependency("kramdown")
end
