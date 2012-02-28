class Lesson < ActiveRecord::Base
  self.primary_key = :lessonid
  has_many :lessondesc_patterns, :foreign_key => :lessonid
  has_many :lesson_descriptions, :foreign_key => :lessonid do
    def by_language(code3)
      where(:lang => code3)
    end
  end
  belongs_to :lecturer, :foreign_key => :lecturerid
  belongs_to :container_type
  has_and_belongs_to_many :file_assets, :join_table => "lessonfiles", :foreign_key => "lessonid",
                          :association_foreign_key => "fileid", :order => "date(updated) DESC, filename ASC"
  has_and_belongs_to_many :catalogs, :join_table => "catnodelessons", :foreign_key => "lessonid",
                          :association_foreign_key => "catalognodeid", :order => "catalognodename"
  belongs_to :language, :foreign_key => :lang, :primary_key => :code3

  accepts_nested_attributes_for :lesson_descriptions

  attr_accessor :v_lessondate, :catalog_tokens, :rss

  validates :lessonname, :lang, :catalogs, :container_type_id, :presence => true

  class NonemptyValidator < ActiveModel::Validator
    #, :fields => [:lesson_descriptions]
    def validate(record)
      # At least ENG, RUS and HEB must be non-empty
      lds = {}
      record.lesson_descriptions.map { |x| lds[x.lang] = x.lessondesc }
      if lds['ENG'].blank? || lds['RUS'].blank? || lds['HEB'].blank?
        record.errors[:base] << "Empty Basic Description(s)"
        return
      end
    end
  end
  validates_with NonemptyValidator

  before_create :create_timestamps
  before_update :update_timestamps

  scope :ordered, order("date(created) DESC, lessonname ASC")
  scope :need_update, where("date(created) > '2011-03-01' and (lessondate is null or lang is null or lang = '' or (select count(1) from lessondesc where lessondesc.lessonid = lessons.lessonid and lang in('HEB', 'ENG', 'RUS') and length(lessondesc) > 0 ) = 0 or (select count(1) from catnodelessons where catnodelessons.lessonid = lessons.lessonid) = 0)")

  searchable do
    text :lessonname
    text :lessondesc, :as => :user_text do
      lesson_descriptions.select([:lessondesc, :descr]).map(&:lessondesc).join(' ')
    end
    text :descr, :as => :user_text do
      lesson_descriptions.select([:lessondesc, :descr]).map(&:descr).join(' ')
    end

    integer :secure
    integer :container_type_id

    string :file_language_ids, :multiple => true do
      file_assets.select('distinct filelang').map(&:filelang)
    end

    string :media_type_ids, :multiple => true do
      file_assets.select('distinct filetype').map(&:filetype)
    end

    integer :catalog_ids, :multiple => true

    time :lessondate
    time :created
    time :updated
  end

  def create_timestamps
    write_attribute :created, Time.now
    write_attribute :updated, Time.now
  end

  def update_timestamps
    write_attribute :updated, Time.now
  end

  # Virtual column to emulate varchar lessondate in db
  columns_hash["v_lessondate"] = ActiveRecord::ConnectionAdapters::Column.new("v_lessondate", nil, "date")

  def v_lessondate
    Date.strptime(lessondate.to_s, '%Y-%m-%d') rescue nil
  end

  def v_lessondate=(my_date)
    self.lessondate = my_date.to_s
  end

  def catalog_tokens=(ids)
    self.catalog_ids = ids.split(',')
  end

  def rss
    !(self.catalog_ids & RSS_CATEGORIES.map { |e| e[:id] }).empty?
  end

  def rss=(value)
    if value == "1" && (self.catalog_ids & RSS_CATEGORIES.map { |e| e[:id] }).empty?
      catalogs << Catalog.find(RSS_CATEGORIES[0][:id])
    end
  end

  # Register file(s) into a container.
  #
  # Both file(s) and container may exist and will be updated.
  # The file(s) will be assigned to container.
  # Non-existing file descriptions, according fo file extension + _96k,
  # will be updated - filedesc (fileid,lang,filedesc)
  #
  # The following tables/fields will be updated automatically:
  # container:  date, language, lecturer (if rav), container type, descriptions
  #
  # @param container - name of container (directory)
  # @param files - array of name-server-size-time objects
  def self.add_update(container_name, files)
    raise 'Container\'s name cannot be blank' if container_name.blank?

    # Create/update container
    container = Lesson.find_or_initialize_by_lessonname(container_name) { |c|
      # Try to update auto-fill-able fields
      # Only for new containers
      c.catalogs << Catalog.find_by_catalognodename('Video')
      sp = ::StringParser.new container_name
      c.lessondate = Date.new(sp.date[0], sp.date[1], sp.date[2]).to_s
      c.lang = sp.language.upcase
      c.lecturerid = Lecturer.rav.first.lecturerid if sp.lecturer_rav?
      sp.descriptions.each { |pattern|
        c.lesson_descriptions.build(:lang => pattern.lang, :lessondesc => pattern.description)
      }
      c.container_type_id = sp.container_type.id

      languages = Language.order('code3').all

      lang_codes = c.lesson_descriptions.map(&:lang)
      languages.each { |l|
        c.lesson_descriptions.build(:lang => l.code3) unless lang_codes.include?(l.code3)
      }
    }

    if !container.persisted? && !container.save
      raise 'Unable to create/update container'
    end

    files.each do |file|
      name = file['file']
      server = file['server'] || DEFAULT_FILE_SERVER
      size = file['filesize'] || 0 # TODO: read file size from server
      datetime = file['time'] ? Time.at(file['time']) : Time.now

      extension = File.extname(name)
      name =~ /^([^_]+)_/
      lang = Language.find_by_code3($1.upcase).code3
      raise "Unknown language: $1" if not lang

      file_asset = FileAsset.find_by_filename(name)
      if file_asset.nil?
        file_asset = FileAsset.new(filename: name, filelang: lang, filetype: extension, filedate: datetime, filesize: size,
                                   lastuser: 'system', servername: server)
        container.file_assets << file_asset
      else
        file_asset.update_attributes(filename: name, filelang: lang, filetype: extension, filedate: datetime, filesize: size,
                                    lastuser: 'system', servername: server)
      end
      raise "Unable to save/update file #{name}" unless file_asset.save

      # Update file description for non-existing UI languages
      file_desc = if name =~ /_draw_/
                    extension.downcase == 'zip' ? '<b>draw ZIP</b>' : '<b>draw</b>'
                  elsif name =~ /_scan_/
                    extension.downcase == 'zip' ? '<b>scan ZIP</b>' : '<b>scan</b>'
                  else
                    case extension.downcase.downcase
                      when '.zip'
                        '<b>ZIP FILE</b>'
                      when '.pdf'
                        '<b>pdf</b>'
                      when '.flv'
                        '<b>flv</b>'
                      when '.mp4'
                        '<b>mp4</b>'
                      else
                        if name =~ /_96k/
                          '2/2 <b>original 96K</b>'
                        end
                    end
                  end
      unless file_desc.blank?
        ui_langs = Language.all.map(&:lang) - container.file_assets.select('distinct filelang').map(&:filelang)
        ui_langs.each { |ui_lang|
          file_assets.file_asset_descriptions << FileAssetDescription.new(lang: ui_lang, filedesc: file_desc)
        }
      end
    end

    true
  end

end
