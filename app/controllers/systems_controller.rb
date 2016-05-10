class SystemsController < ApplicationController
  before_action :set_system, only: [:show, :edit, :update, :destroy]

  # GET /systems
  # GET /systems.json
  def index
    @filterrific = initialize_filterrific(
      System,
      params[:filterrific],
      :select_options => {
        sorted_by: System.options_for_sorted_by
      }
    ) or return
    @systems = @filterrific.find.page(params[:page])

    respond_to do |format|
      format.html
      format.js
    end
    #@systems = System.all
    #@paginated_systems = @systems.paginate(:page => params[:page], :per_page => Settings.Pagination.NoOfEntriesPerPage)
  end

  # GET /systems/1
  # GET /systems/1.json
  def show
    #@concrete_package_versions = ConcretePackageVersion.where(system: @system )
    @concrete_package_versions = ConcretePackageVersion.where(system: @system, concrete_package_state: ConcretePackageState.where(name: "Available")[0] )
    @paginated_concrete_package_versions = @concrete_package_versions.paginate(:page => params[:page], :per_page => Settings.Pagination.NoOfEntriesPerPage)
  end

  # GET /systems/new
  def new
    @system = System.new
  end

  # GET /systems/1/edit
  def edit
  end

  # POST /systems
  # POST /systems.json
  def create
    @system = System.new(system_params)

    respond_to do |format|
      if @system.save
        format.html { redirect_to @system, success: 'System was successfully created.' }
        format.json { render :show, status: :created, location: @system }
      else
        format.html { render :new }
        format.json { render json: @system.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /systems/1
  # PATCH/PUT /systems/1.json
  def update
    respond_to do |format|
      if @system.update(system_params)
        format.html { redirect_to @system, success: 'System was successfully updated.' }
        format.json { render :show, status: :ok, location: @system }
      else
        format.html { render :edit }
        format.json { render json: @system.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /systems/1
  # DELETE /systems/1.json
  def destroy
    @system.destroy
    respond_to do |format|
      format.html { redirect_to systems_url, success: 'System was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_system
      @system = System.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def system_params
      params.require(:system).permit(:name, :urn, :os, :reboot_required, :address, :last_seen, :system_group_id)
    end
end
