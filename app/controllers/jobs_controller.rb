class JobsController < ApplicationController
  before_action :set_job, only: [:show, :edit, :update, :destroy, :execute]

  # GET /jobs
  def index
    @jobs = Job.all
    @paginated_jobs = @jobs.paginate(:page => params[:page], :per_page => Settings.Pagination.NoOfEntriesPerPage)
  end

  # GET /jobs/1
  def show
    @tasks = Task.where(:job => @job)
  end

  def create_combo
    list = JSON.parse params[:list]
    filter = JSON.parse params[:filter]

    packages = list["packages"]
    task_state_pending = TaskState.where(name: "Pending")[0]
    cpv_state_queued = ConcretePackageState.where(name: "Queued for Installation")[0]

    if current_user
      @job = Job.new(user: current_user,
                     started_at: Time.new,
                     is_in_preview: true)
    end

    systems = []
    cpvs = []

    packages.each do |pkg|
      if pkg["pristine"] == true
        if Package.find( pkg["id"] )
          Package.find( pkg["id"] ).get_available_cpvs.each do |cpv|
            cpvs << cpv
          end
        end
      else
        pkg["cpvs"].each do |cpv|
          if ConcretePackageVersion.find( cpv["id"] )
            cpvs << ConcretePackageVersion.find( cpv["id"] )
          end
        end
      end

      cpvs.each do |cpv|
        # only take system in consideration if it's passed the optional filter
        valid = true

        if filter['text'] && filter['text'] != ""
          valid = (cpv.system.name.start_with? filter['text']) ||
                  (cpv.system.urn.start_with? filter['text'])
        end

        if valid && filter['group'] && filter['group'] != ""
          valid = cpv.system.system_group ? (cpv.system.system_group.id == filter['group']) : false
        end

        if valid
          systems << cpv.system
        end
      end
    end

    systems = systems.uniq

    systems.each do |sys|
      @task = Task.new(
        task_state: task_state_pending,
        tries: 0 )

      cpvs.each do |cpv|
        if cpv.system == sys
          @task.concrete_package_versions << cpv
          cpv.concrete_package_state = cpv_state_queued
          cpv.save()
        end
      end

      @task.save
      @job.tasks << @task
    end

    @job.save

    render text: job_path( @job )
  end

  def create_multiple
    systems = []
    task_state_pending = TaskState.where(name: "Pending")[0]
    cpv_state_queued = ConcretePackageState.where(name: "Queued for Installation")[0]

    if params[:all]
      # get all systems with available updates
      System.all.reject{ |s| s.get_installable_CPVs.count < 1 }.each do |sys|
        systems << sys
      end
    else
      # get system IDs from submitted array
      if params[:systems]
        params[:systems].each do |sysID|
          systems << System.find( sysID )
        end
      end
    end

    if current_user
      @job = Job.new(user: current_user,
                     started_at: Time.new,
                     is_in_preview: true)
    end

    # create a task for each system:
    systems.each do |sys|
      @task = Task.new(
        task_state: task_state_pending,
        tries: 0 )
      @task.concrete_package_versions << sys.get_installable_CPVs

      @task.concrete_package_versions.each do |update|
        update.concrete_package_state = cpv_state_queued
        update.save()
      end

      @task.save
      @job.tasks << @task
    end

    @job.save

    redirect_to @job
  end

  # POST /jobs
  def create
    @task = Task.new(
      task_state: TaskState.where(name: "Pending")[0],
      tries: 0 )

    if params[:all]
      # get task IDs from system, map to strings
      cpv_state_avail = ConcretePackageState.where(name: "Available")[0]
      @task.concrete_package_versions << System.find(params[:system_id]).concrete_package_versions.where(concrete_package_state: cpv_state_avail )
    else
      # get task IDs from submitted array
      if params[:updates]
        params[:updates].each do |updateID|
          @task.concrete_package_versions << ConcretePackageVersion.find( updateID )
        end
      end
    end

    if ( ConcretePackageState.exists?(name: "Queued for Installation") )
      cpv_state_queued = ConcretePackageState.where(name: "Queued for Installation")[0]
      @task.concrete_package_versions.each do |update|
        update.concrete_package_state = cpv_state_queued
        update.save()
      end
    end

    @task.save

    if current_user
      @job = Job.new(user: current_user,
                     started_at: Time.new,
                     is_in_preview: true)
      @job.tasks << @task
      @job.save

      redirect_to @job
    end

  end

  # PATCH/PUT /jobs/1
  def update
    if @job.update(job_params)
      redirect_to @job, success: 'Job was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /jobs/1
  def destroy
    if @job.tasks.length > 0
      @job.tasks.each do |t|
        t.destroy()
      end
    end

    @job.destroy
    redirect_to jobs_url, success: 'Job was successfully destroyed.'
  end

  def execute
    if params[:execute]
      @job.is_in_preview = false

      @job.update( job_params )

      @job.save()
      @job.tasks.each do |t|
        BackgroundSender.perform_async( t )
      end
      redirect_to @job, success: 'Job was successfully sent!'
    elsif params[:cancel]
      stateAvail = ConcretePackageState.where(name: "Available")[0]
      @job.tasks.each do |t|
        t.concrete_package_versions.each do |cpv|
          cpv.concrete_package_state = stateAvail
          cpv.task = nil
          cpv.save()
        end
        t.destroy
      end
      @job.destroy
      redirect_to root_path, success: 'Job was successfully cancelled.'
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_job
      @job = Job.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def job_params
      params.require(:job).permit(:started_at, :user_id, :note)
    end
end
