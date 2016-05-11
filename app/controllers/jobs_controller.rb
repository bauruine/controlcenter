class JobsController < ApplicationController
  before_action :set_job, only: [:show, :edit, :update, :destroy]

  # GET /jobs
  # GET /jobs.json
  def index
    @jobs = Job.all
    @paginated_jobs = @jobs.paginate(:page => params[:page], :per_page => Settings.Pagination.NoOfEntriesPerPage)
  end

  # GET /jobs/1
  # GET /jobs/1.json
  def show
    @tasks = Task.where(:job => @job)
    @paginated_tasks = @tasks.paginate(:page => params[:page], :per_page => Settings.Pagination.NoOfEntriesPerPage)
  end

  # GET /jobs/new
  def new
    @job = Job.new
  end

  # GET /jobs/1/edit
  def edit
  end

  # POST /jobs
  # POST /jobs.json
  def create
    @task = Task.new(task_state: TaskState.where(name: "Pending")[0] )

    if params[:all]
      # get task IDs from system, map to strings
      @task.concrete_package_versions << System.find(params[:system_id]).concrete_package_versions.where(concrete_package_state: ConcretePackageState.first ) #TODO: centralised state manager
    else
      # get task IDs from submitted array
      if params[:updates]
        params[:updates].each do |updateID|
          @task.concrete_package_versions << ConcretePackageVersion.find( updateID )
        end
      end
    end

    if ( ConcretePackageState.exists?(name: "Queued for Installation") )
      stateQueued = ConcretePackageState.where(name: "Queued for Installation")[0]
      @task.concrete_package_versions.each do |update|
        update.concrete_package_state = stateQueued
        update.save()
      end
    end

    @task.tries = 0
    @task.save

    if current_user
      @job = Job.new(user: current_user,
                     started_at: Time.new)
      @job.tasks << @task
      @job.save

      BackgroundSender.perform_async( @task )

      redirect_to @job
    else
      #TODO: log!
    end

  end

  # PATCH/PUT /jobs/1
  # PATCH/PUT /jobs/1.json
  def update
    respond_to do |format|
      if @job.update(job_params)
        format.html { redirect_to @job, success: 'Job was successfully updated.' }
        format.json { render :show, status: :ok, location: @job }
      else
        format.html { render :edit }
        format.json { render json: @job.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /jobs/1
  # DELETE /jobs/1.json
  def destroy
    @job.destroy
    respond_to do |format|
      format.html { redirect_to jobs_url, success: 'Job was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_job
      @job = Job.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def job_params
      params.require(:job).permit(:started_at, :user_id)
    end
end
