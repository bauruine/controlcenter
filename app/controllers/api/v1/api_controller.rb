module Api::V1
  class ApiController < ApplicationController
    protect_from_forgery with: :null_session

    # /register
    def register
      if JSON.parse( request.body.read )
        sys = JSON.parse request.body.read
        if sys["urn"] && sys["os"] && sys["address"]
          if System.exists?(:urn => sys["urn"])
            render json: { status: "ERROR", message: "System already found", code: 3 }
          else
            newSys = System.new
            newSys.name = sys["name"] if sys["name"]
            newSys.urn = sys["urn"]
            newSys.os = sys["os"]
            newSys.address = sys["address"]
            newSys.system_group = SystemGroup.first
            newSys.last_seen = DateTime.now
            newSys.save()
            render json: { status: "OK" }
          end
        else
          render json: { status: "ERROR", message: "Missing Params", code: 1 }
        end
      else
        render json: { status: "ERROR", message: "No JSON Body", code: 0 }
      end
    end

    # /system/:id/notify
    def updateSystem
      if System.exists?(urn: params[:id])
        currentSys = System.where(urn: params[:id])[0]
        if JSON.parse( request.body.read )
          sysUpdate = JSON.parse request.body.read
          if sysUpdate["urn"] && sysUpdate["os"]
            currentSys.name = sysUpdate["name"] if sysUpdate["name"]
            currentSys.urn = sysUpdate["urn"]
            currentSys.address = sysUpdate["address"] if sysUpdate["address"]
            currentSys.os = sysUpdate["os"]
            currentSys.reboot_required = sysUpdate["reboot_required"] if sysUpdate["reboot_required"]
            currentSys.last_seen = DateTime.now
            currentSys.save()
            sysUpdate["packageupdates"].each do |update|
              if Package.exists?(name: update['name'], base_version: update['baseversion'])
                currentPkg = Package.where(name: update['name'], base_version: update['baseversion'])[0]
                if PackageUpdate.exists?(:package => currentPkg, :candidate_version => update['version'])
                  currentUpdate = PackageUpdate.where(:package => currentPkg, :candidate_version => update['version'])[0]
                else
                  # creating update
                  currentUpdate = PackageUpdate.create( {
                         :package           => currentPkg,
                         :candidate_version => update['version'],
                         :repository        => update['repository']
                  } )
                end
                if ! SystemUpdate.exists?(:system => currentSys, :package_update => currentUpdate)
                  # linking update
                  SystemUpdate.create( {
                         :system              => currentSys,
                         :package_update      => currentUpdate,
                         :system_update_state => SystemUpdateState.first
                  } )
                end
                render json: { status: "OK" }
              else
                # TODO: package not found... what to do now?
                render json: { status: "ERROR", message: "Couldn't find package", code: 30 }
              end
            end
          else
            render json: { status: "ERROR", message: "Missing Params", code: 1 }
          end
        else
          render json: { status: "ERROR", message: "No JSON Body", code: 0 }
        end
      else
        render json: { status: "ERROR", message: "System doesn't exist", code: -1 }
      end
    end

    # /task/:id/notify
    def updateTask
      if Task.exists?(params[:id])
        task = Task.find(params[:id])
        if JSON.parse( request.body.read )
          taskUpdate = JSON.parse request.body.read
          if taskUpdate["state"]
            state = TaskState.where(:name => taskUpdate["state"] ).first
            if state
              task.task_state = state
              # TODO + log
              if task.save()
                render json: { status: "OK" }
              else
                render json: { status: "ERROR", message: "Couldn't save task", code: 20 }
              end
            else
              render json: { status: "ERROR", message: "State not valid", code: 10 }
            end
          else
            render json: { status: "ERROR", message: "Missing Params", code: 1 }
          end
        else
          render json: { status: "ERROR", message: "No JSON Body", code: 0 }
        end
      else
        render json: { status: "ERROR", message: "Task doesn't exist", code: -1 }
      end
    end

    # /system/:id/updateInstalled
    def updateInstalled
      if System.exists?(urn: params[:id])
        currentSys = System.where(urn: params[:id])[0]

        if JSON.parse(request.body.read)
          sysUpdate = JSON.parse request.body.read
          if sysUpdate["packages"]

            sysUpdate["packages"].each do |package|

              if Package.exists?(name: package['name'], base_version: package['baseversion'])
                currentPkg = Package.where(name: package['name'], base_version: package['baseversion'])[0]
              else
                # creating package
                currentPkg = Package.create( {
                       :name         =>  package['name'],
                       :base_version =>  package['baseversion'],
                       :architecture =>  package['architecture'],
                       :section      =>  package['section'],
                       :repository   =>  package['repository'],
                       :homepage     =>  package['homepage'],
                       :summary      =>  package['summary']
                } )
              end

              if PackageInstallation.exists?(:system => currentSys, :package => currentPkg)
                # updating link system <=> package
                currentInstall = PackageInstallation.where(:system => currentSys, :package => currentPkg)[0]
                currentInstall.installed_version = package['version']
                currentInstall.save
              else
                # creating link system <=> package
                PackageInstallation.create({
                       :system            => currentSys,
                       :package           => currentPkg,
                       :installed_version => package['version']
                })
              end
            end
            render json: { status: "OK" }
          else
            render json: { status: "ERROR", message: "Missing Params", code: 1 }
          end
        else
          render json: { status: "ERROR", message: "No JSON Body", code: 0 }
        end
      else
        render json: { status: "ERROR", message: "System doesn't exist", code: -1 }
      end
    end
  end
end
