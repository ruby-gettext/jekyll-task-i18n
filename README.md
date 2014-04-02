# jekyll-task-i18n - Preprocessor for Jekyll to support i18n

jekyll-task-i18n is a preprocessor for Jekyll to support i18n.

There are some i18n softwares for Jekyll that are implemented as
Jekyll plugin such as
[jekyll-localization](http://rubygems.org/gems/jekyll-localization)
and
[jekyll-i18n](http://rubygems.org/gems/jekyll-i18n). jekyll-task-i18n
uses preprocessor approach instead of Jekyll plugin. This approach has
the following advantages:

  * You can use i18n feature on GitHub pages.
  * You don't mark translate target texts up in your source.

You can't use Jekyll plugins on GitHub Pages. So you can't use Jekyll
plugin based approaches too.

jekyll-localization uses `{{ 'translate target content | t:
'translated content' }}` markup. jekyll-i18n uses `{%t Your translated
content %}` markup.

jekyll-task-i18n extracts translate target content from source as
preprocessor. So you don't need to mark your source up.

## How to work

TODO

## Installation

Create the following `Gemfile`:

    source "https://rubygems.org/"

    gem "jekyll-task-i18n"

Create the following `Rakefile`:

    require "bundler/setup"
    require "jekyll/task/i18n"

    Jekyll::Task::I18n.define do |task|
      # Set translate target locales.
      task.locales = ["ja", "fr"]
      # Set all *.md texts as translate target contents.
      task.files = Rake::FileList["**/*.md"]
      # Remove internal files from target contents.
      task.files -= Rake::FileList["_*/**/*.md"]
      # Remove translated files from target contents.
      task.locales.each do |locale|
        task.files -= Rake::FileList["#{locale}/**/*.md"]
      end
    end

Add the following line to `_config.yml`:

    exclude: ["Gemfile", "Gemfile.lock", "Rakefile"]

Install dependency softwares:

    % bundle

## Work-flow

Here is a work-flow to translate one documentation in English:

  1. Run `rake`.
  2. Translate `_po/${YOUR_LOCALE}/${PATH_TO_TARGET_FILE}.edit.po`.
  3. Run `rake`.
  4. Run `jekyll server`.
  5. Confirm `_site/${YOUR_LOCALE}/${PATH_TO_TARGET_FILE}.html`.
  6. Commit `_po/${YOUR_LOCALE}/${PATH_TO_TARGET_FILE}.po` (not
     `.edit.po`) and `${YOUR_LOCALE}/${PATH_TO_TARGET_FILE}.md`.

## Example

Here is an example to translate `overview/index.md` into Japanese.

Run `rake`:

    % rake

Translate `_po/ja/overview/index.edit.po`:

    % gedit _po/ja/overview/index.edit.po

Note: You can use PO editor instead of text editor. For example,
Emacs's po-mode, Vim,
[Gtranslator](https://wiki.gnome.org/Apps/Gtranslator),
[Lokalize](http://userbase.kde.org/Lokalize) and so on.

Run `rake`:

    % rake

Run `jekyll server`:

    % jekyll server &

Confirm `_site/ja/overview/index.html`:

    % firefox http://localhost:4000/ja/overview/index.html

Commit `_po/ja/overview/index.po` and `ja/overview/index.md`:

    % git add _po/ja/overview/index.po
    % git add ja/overview/index.md
    % git commit
    % git push

## License

LGPLv2 only. See LICENSE.txt for detail.
