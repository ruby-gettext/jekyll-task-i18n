# Copyright (C) 2014-2023  The ruby-gettext project
# Copyright (C) 2013-2014  Droonga Project
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License version 2.1 as published by the Free Software Foundation.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

require "pathname"
require "rake/clean"

require "yard"
require "gettext/tools"


module Jekyll
  module Task
    class I18n
      class << self
        def define(&block)
          task = new
          yield(task) if block_given?
          task.define
        end
      end

      include Rake::DSL

      attr_accessor :locales
      attr_accessor :files
      attr_accessor :translator_name
      attr_accessor :translator_email
      attr_accessor :custom_translator
      def initialize
        @po_dir_path = Pathname.new("_po")
        @base_dir_path = Pathname.new(".")
        @locales = []
        @files = []
        @translator_name = nil
        @translator_email = nil
        @yard_locales = {}
        @custom_translator = nil
      end

      def define
        namespace :jekyll do
          namespace :i18n do
            namespace :internal do
              task :force
            end

            namespace :po do
              namespace :edit do
                define_edit_po_update_task
              end

              define_po_update_task
            end

            define_translate_task
          end
        end
      end

      private
      def define_edit_po_update_task
        @locales.each do |locale|
          namespace locale do
            define_edit_po_locale_update_task(locale)
          end
        end
      end

      def define_edit_po_locale_update_task(locale)
        edit_po_files = []
        @files.each do |target_file|
          path = Path.new(@po_dir_path, locale, Pathname(target_file))
          edit_po_file = path.edit_po_file.to_s
          edit_po_files << edit_po_file
          CLEAN << edit_po_file if path.edit_po_file.exist?

          po_dir = path.po_dir.to_s
          directory po_dir
          dependencies = [target_file, po_dir]
          dependencies << "i18n:internal:force" if po_file_is_updated?(path)
          file edit_po_file => dependencies do
            relative_base_path = @base_dir_path.relative_path_from(path.po_dir)
            generator = YARD::I18n::PotGenerator.new(relative_base_path.to_s)
            yard_file = YARD::CodeObjects::ExtraFileObject.new(target_file)
            generator.parse_files([yard_file])
            path.source_pot_file.open("w") do |output|
              output.puts(generator.generate)
            end
            msgcat("--no-all-comments",
                   "--no-update-po-revision-date",
                   "--output", path.pot_file.to_s,
                   "--remove-header-field=Language-Team",
                   "--remove-header-field=Last-Translator",
                   "--remove-header-field=POT-Creation-Date",
                   "--remove-header-field=Report-Msgid-Bugs-To",
                   "--sort-by-file",
                   path.source_pot_file.to_s)
            if po_file_is_updated?(path)
              rm_f(path.edit_po_file.to_s)
              rm_f(path.all_po_file.to_s)
            end
            unless path.edit_po_file.exist?
              if path.po_file.exist?
                msgcat("--no-update-po-revision-date",
                       "--output", path.edit_po_file.to_s,
                       path.po_file.to_s)
              else
                msginit("--input", path.source_pot_file.to_s,
                        "--locale", locale,
                        "--output", path.edit_po_file.to_s)
              end
            end

            edit_po_file_mtime = path.edit_po_file.mtime
            msgmerge("--sort-by-file",
                     "--update",
                     path.edit_po_file.to_s,
                     path.source_pot_file.to_s)
            if path.po_file.exist? and path.po_file.mtime > edit_po_file_mtime
              msgmerge("--no-obsolete-entries",
                       "--output", path.edit_po_file.to_s,
                       "--sort-by-file",
                       path.po_file.to_s,
                       path.edit_po_file.to_s)
              msgcat("--no-update-po-revision-date",
                     "--output", path.edit_po_file.to_s,
                     path.edit_po_file.to_s)
            end
            if path.all_po_file.exist?
              msgmerge("--no-fuzzy-matching",
                       "--no-obsolete-entries",
                       "--output", path.edit_po_file.to_s,
                       "--sort-by-file",
                       path.all_po_file.to_s,
                       path.edit_po_file.to_s)
              msgcat("--no-update-po-revision-date",
                     "--output", path.edit_po_file.to_s,
                     path.edit_po_file.to_s)
            end
          end
        end

        desc "Update .edit.po files for [#{locale}] locale"
        task :update => edit_po_files
      end

      def po_file_is_updated?(path)
        return false unless path.po_file.exist?
        return false unless path.time_stamp_file.exist?
        path.po_file.mtime > path.time_stamp_file.mtime
      end

      def define_po_update_task
        @locales.each do |locale|
          namespace locale do
            define_po_locale_update_task(locale)
          end
        end

        all_update_tasks = @locales.collect do |locale|
          "i18n:po:#{locale}:update"
        end
        desc "Update .po files for all locales"
        task :update => all_update_tasks
      end

      def define_po_locale_update_task(locale)
        po_files = []
        @files.each do |target_file|
          path = Path.new(@po_dir_path, locale, Pathname(target_file))
          po_file = path.po_file.to_s
          po_files << po_file

          CLEAN << path.time_stamp_file.to_s if path.time_stamp_file.exist?
          file po_file => [path.edit_po_file.to_s] do
            msgcat("--no-fuzzy",
                   "--no-location",
                   "--no-obsolete-entries",
                   "--no-report-warning",
                   "--no-update-po-revision-date",
                   "--output", po_file,
                   "--remove-header-field=POT-Creation-Date",
                   "--sort-by-file",
                   path.edit_po_file.to_s)
            touch(path.time_stamp_file.to_s)
          end
        end

        all_po_file_path = Path.new(@po_dir_path, locale).all_po_file
        all_po_file = all_po_file_path.to_s
        CLEAN << all_po_file if all_po_file_path.exist?
        file all_po_file => po_files do
          sorted_po_files = po_files.sort_by do |po_file|
            -File.mtime(po_file).to_f
          end
          msgcat("--no-all-comments",
                 "--no-fuzzy",
                 "--no-obsolete-entries",
                 "--output", all_po_file,
                 "--sort-by-msgid",
                 *sorted_po_files)
        end

        desc "Update .po files for [#{locale}] locale"
        task :update => all_po_file
      end

      def define_translate_task
        @locales.each do |locale|
          namespace locale do
            define_locale_translate_task(locale)
          end
        end

        all_translate_tasks = @locales.collect do |locale|
          "i18n:#{locale}:translate"
        end
        desc "Translate files for all locales"
        task :translate => all_translate_tasks
      end

      def define_locale_translate_task(locale)
        translated_files = []
        @files.each do |target_file|
          path = Path.new(@po_dir_path, locale, Pathname(target_file))
          translated_file = path.translated_file.to_s
          translated_files << translated_file

          translated_file_dir = path.translated_file.parent.to_s
          directory translated_file_dir
          dependencies = [
            target_file,
            "i18n:po:#{locale}:update",
            translated_file_dir,
          ]
          file translated_file => dependencies do
            File.open(target_file) do |input|
              text = translate(input, locale, path)
              File.open(translated_file, "w") do |output|
                output.puts(text)
              end
            end
          end
        end

        desc "Translate files for [#{locale}] locale"
        task :translate => translated_files
      end

      def translate(input, locale, path)
        text = YARD::I18n::Text.new(input)
        translated_text = text.translate(yard_locale(locale))
        if @custom_translator
          translated_text = @custom_translator.call(input, translated_text, path)
        end
        translated_text
      end

      def yard_locale(locale)
        @yard_locales[locale] ||= create_yard_locale(locale)
      end

      def create_yard_locale(locale)
        yard_locale = YARD::I18n::Locale.new(locale)
        messages = GetText::MO.new
        po_parser = GetText::POParser.new
        po_parser.parse_file(@po_dir_path + "#{locale}.po", messages)
        yard_locale.instance_variable_get("@messages").merge!(messages)
        yard_locale
      end

      def msginit(*arguments)
        GetText::Tools::MsgInit.run(*(msginit_options + arguments))
      end

      def msginit_options
        options = []
        if @translator_name or @translator_email
          if @translator_name
            options.concat(["--translator-name", @translator_name])
          end
          if @translator_email
            options.concat(["--translator-email", @translator_email])
          end
        else
          options << "--no-translator"
        end
        options
      end

      def msgmerge(*arguments)
        GetText::Tools::MsgMerge.run(*arguments)
      end

      def msgcat(*arguments)
        GetText::Tools::MsgCat.run(*arguments)
      end

      class Path
        attr_reader :locale
        def initialize(po_dir_path, locale, target_file_path=nil)
          @po_dir_path = po_dir_path
          @locale = locale
          @target_file_path = target_file_path
        end

        def target_file
          @target_file_path
        end

        def base_po_dir
          @po_dir_path + @locale
        end

        def all_po_file
          @po_dir_path + "#{@locale}.po"
        end

        def target_file_base
          @target_file_path.basename(".*")
        end

        def po_dir
          base_po_dir + @target_file_path.dirname
        end

        def po_file
          po_dir + "#{target_file_base}.po"
        end

        def time_stamp_file
          po_dir + "#{target_file_base}.time_stamp"
        end

        def edit_po_file
          po_dir + "#{target_file_base}.edit.po"
        end

        def pot_file
          po_dir + "#{target_file_base}.pot"
        end

        def source_pot_file
          po_dir + "#{target_file_base}.source.pot"
        end

        def translated_file
          Pathname(@locale) + @target_file_path
        end

        def translated_file_dir
          Pathname(@locale) + @target_file_path
        end
      end
    end
  end
end
