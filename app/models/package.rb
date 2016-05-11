class Package < ActiveRecord::Base
  has_many :package_versions
  has_many :concrete_package_versions, -> { distinct }, through: :package_versions

  has_many :group_assignments
  has_many :package_groups, through: :group_assignments

  validates_presence_of :urn

  filterrific(
    default_filter_params: { sorted_by: 'name_desc' },
    available_filters: [
      :sorted_by,
      :search_query,
      :with_package_group_id
    ]
  )

  scope :search_query, lambda { |query|
    return nil  if query.blank?
    # condition query, parse into individual keywords
    terms = query.downcase.split(/\s+/)
    # replace "*" with "%" for wildcard searches,
    # append '%', remove duplicate '%'s
    terms = terms.map { |e|
      (e.gsub('*', '%') + '%').gsub(/%+/, '%')
    }

    num_or_conditions = 3
    where(
      terms.map {
        or_clauses = [
          "LOWER(packages.name) LIKE ?",
          "LOWER(packages.summary) LIKE ?",
          "LOWER(packages.section) LIKE ?"
        ].join(' OR ')
        "(#{ or_clauses })"
      }.join(' AND '),
      *terms.map { |e| [e] * num_or_conditions }.flatten
    )
  }
  scope :sorted_by, lambda { |sort_option|
    direction = (sort_option =~ /desc$/) ? 'desc' : 'asc'
    case sort_option.to_s
      when /^created_at_/
        order("packages.created_at #{ direction }")
      when /^name_/
        order("LOWER(packages.name) #{ direction }")
      when /^section_/
        order("LOWER(packages.section) #{ direction }")
      when /^website_/
        order("LOWER(packages.website) #{ direction }")
      when /^summary_/
        order("LOWER(packages.summary) #{ direction }")
      else
        raise(ArgumentError, "Invalid sort option: #{ sort_option.inspect }")
    end
  }
  scope :with_package_group_id, lambda { |package_group_id|
    where(
      'EXISTS (SELECT 1 from group_assignments WHERE packages.id = group_assignments.package_id AND group_assignments.package_group_id = ?)', package_group_id.to_s
    )
  }

  def self.options_for_sorted_by
    [
      ['Name (a-z)', 'name_asc']
    ]
  end

  self.per_page = Settings.Pagination.NoOfEntriesPerPage


  def decorated_created_at
      created_at.to_formatted_s(:short)
  end

  def get_group_names
    package_groups.all.map{ |p| p.name }.join(', ')
  end
end
