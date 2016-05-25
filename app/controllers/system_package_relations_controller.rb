class SystemPackageRelationsController < ApplicationController

  # GET /system_package_relations
  def index
    @filterrific = initialize_filterrific(
      SystemPackageRelation,
      params[:filterrific],
      select_options: {
        sorted_by: SystemPackageRelation.options_for_sorted_by,
        with_system_group_id: SystemGroup.options_for_select,
        with_package_group_id: PackageGroup.options_for_select
      }
    ) or return

    cp = params[:page]
    tmplist1 = @filterrific.find
    tmplist2 = tmplist1.select("pkg_id, pkg_name, pkg_section, COUNT(*) as sys_count").group("pkg_id, pkg_name, pkg_section")
    tot = tmplist2.length
    @system_package_relations = tmplist2.paginate(page: cp, total_entries: tot)
  end


  # GET /system_package_relations/id
  def show
    @system_package_relations = SystemPackageRelation.where( pkg_id: params['id'])
    if params['query']
        if params['query']['text']
            @system_package_relations = @system_package_relations.where( "sys_name like ?", "#{params['query']['text'].to_s}%" )
        end
        if params['query']['group']
            @system_package_relations = @system_package_relations.where( sys_grp_id: params['query']['group'] )
        end
    end
  end
end
