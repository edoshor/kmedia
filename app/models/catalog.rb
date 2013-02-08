class Catalog < ActiveRecord::Base
  self.table_name = :catalognode
  self.primary_key = :catalognodeid
  acts_as_tree :foreign_key => 'parentnodeid', :order => 'catorder'
  has_and_belongs_to_many :lessons, :join_table => "catnodelessons", :foreign_key => "catalognodeid",
                          :association_foreign_key => "lessonid", :order => "lessonname ASC, date(updated) DESC"

  has_and_belongs_to_many :lessondesc_patterns, :join_table => "lessondesc_patterns_catalogs", :uniq => true
  has_many :catalog_descriptions, :foreign_key => :catalognodeid, :dependent => :destroy
  accepts_nested_attributes_for :catalog_descriptions, :reject_if => proc { |attributes| attributes['catalognodename'].blank? }

  attr_accessor :has_children

  searchable do
    text :catalognodename
    boolean :secure
  end

  scope :secure, lambda { |level| where("secure <= ?", level) }
  scope :open_matching_string, lambda { |string| where("catalognodename like ? AND open = ?", "%#{string}%", true )}

  before_create :create_timestamps
  before_update :update_timestamps

  validates :label, :uniqueness => true, :format => { :with => /^[a-zA-Z0-9_-]*$/ }

  class ParentValidator < ActiveModel::Validator
    def validate(catalog)
      catalog.errors[:parentnodeid] << "Catalog can't be an ancestor of himself" if catalog.ancestors.include? catalog
    end
  end

  validates_with ParentValidator

  def create_timestamps
    write_attribute :created, Time.now
    write_attribute :updated, Time.now
  end

  def update_timestamps
    write_attribute :updated, Time.now
  end

  # returns children catalogs for the given catalog id
  # will return roots catalogs if the provided id is nil or empty
  def self.children_catalogs(id, secure)
    if id.blank?
      children_catalogs = Catalog.secure(secure).roots
    else
      catalog = Catalog.secure(secure).where(catalognodeid: id).first
      children_catalogs = catalog.children
    end
  end
end
