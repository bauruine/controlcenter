require "net/https"
require "uri"

class BackgroundSender
  include SuckerPunch::Job

  def perform(task)
    packageArray = []
    task.concrete_package_versions.each do |pkgVersion|
      packageArray << { pkg_name: pkgVersion.package_version.package.name, pkg_version: pkgVersion.package_version.version}
    end

    system = task.concrete_package_versions.first().system
    taskData = { task_id: task.id.to_s, urn: system.name, packages: packageArray }
    task.tries = task.tries.to_i + 1

    #url = 'https:' + system.address                 #will work when Agent is ready
    #url = 'https://upd89-01.nine.ch:8080'           #already works hardcoded
    url = "https://" + system.name + ".nine.ch:8080" #workaround for now

    begin
      connection = Faraday::Connection.new url, :ssl => {
        #      :ca_path => '/usr/lib/ssl/certs',  #original SSL dir
        #      :ca_path => '/opt/upd89/ca/keys',  #original upd89 cert dir
        :ca_path => 'config/certs',         #relative dir
        :verify => true
      }

      #TODO: remove debug logging
      logger.debug( "------------CONN---------" )
      logger.debug( connection )

      result = connection.post '/task', taskData.to_json

      logger.debug( "------------BODY---------" )
      logger.debug( result.body )

      if ( result.body == "OK")
        task.task_state = TaskState.where(name: "Queued")[0]
      end
    rescue Faraday::Error::ConnectionFailed => e #TODO: other possible errors
      logger.debug( "Connection failed: #{e}" ) #TODO: log exception!
      if task.tries.to_i < Settings.BackgroundTask.MaximumAmountOfTries
        logger.debug( "RESTARTING TASK " + task.tries.to_s )
        BackgroundSender.perform_in(Settings.BackgroundTask.SecondsBetweenTries, task )
      else
        task.task_state = TaskState.where(name: "Not Delivered")[0]
      end
    ensure
      task.save()
    end
  end
end
