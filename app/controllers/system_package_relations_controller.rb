class SystemPackageRelationsController < ApplicationController

  # GET /system_package_relations
  def index
    @filterrific = initialize_filterrific(
      SystemPackageRelationGrouped,
      params[:filterrific],
      select_options: {
        sorted_by: SystemPackageRelationGrouped.options_for_sorted_by,
        with_system_group_id: SystemGroup.options_for_select,
        with_package_group_id: PackageGroup.options_for_select
      }
    ) or return

    @system_package_relations = @filterrific.find.page(params[:page])
  end


  # GET /system_package_relations/id
  def show
    @system_package_relations = SystemPackageRelation.where(:pkg_id => params['id'])
    if params['query']
        if params['query']['text']
            @system_package_relations = @system_package_relations.where(:sys_name => params['query']['text'].to_s)
        end
        if params['query']['group']
            @system_package_relations = @system_package_relations.where(:sys_grp_id => params['query']['group'])
        end
    end
  end
end
