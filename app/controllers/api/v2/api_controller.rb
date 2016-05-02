module Api::V2
  class ApiController < ApplicationController
    protect_from_forgery with: :null_session

    before_action :require_valid_json

    def require_valid_json
      unless JSON.parse( request.body.read)
        render json: { status: "ERROR" }
        return
      end
    end

    def check_mandatory_json_params( data, params=[""] )
      error = false
      params.each do |param|
        error = true unless data.keys.include?(param)
      end
      return error
    end

    def apply_system_properties( sys, data )
      sys.name = data["name"] if data["name"]
      sys.urn = data["urn"] if data["urn"]
      sys.os = data["os"] if data["os"]
      sys.address = data["address"] if data["address"]
      sys.reboot_required = data["rebootRequired"] if data["rebootRequired"]
      sys.last_seen = DateTime.now
    end

    # v2/register
    def register
      data = JSON.parse request.body.read

      if check_mandatory_json_params(data, ["name", "urn", "os", "address", "certificate"]) || System.exists?(:urn => data["urn"])
        render json: { status: "ERROR" }
        return
      end

      newSys = System.new
      apply_system_properties( newSys, data )
      newSys.system_group = SystemGroup.first
      newSys.last_seen = DateTime.now

      if newSys.save()
        render json: { status: "OK" }
      else
        render json: { status: "ERROR" }
      end
    end

    # v2/system/:urn/notify-hash
    def updateSystemHash
      data = JSON.parse request.body.read

      if check_mandatory_json_params(data, ["updCount", "packageUpdates"]) || !System.exists?(urn: params[:urn])
        render json: { status: "ERROR" }
        return
      end

      currentSys = System.where(urn: params[:urn])[0]

      unknownPackages = []
      knownPackages = []
      stateAvailable = ConcretePackageState.first

      data["packageUpdates"].each do |updHash|
        if PackageVersion.exists?( sha256: updHash )
          knownPackages.push( updHash )

          pkgVersion = PackageVersion.where( sha256: updHash )[0]

          # only create new CPV if it doesn't already exist!
	  if ConcretePackageVersion.exists?( package_version: pkgVersion, system: currentSys )
 	    # If it exists, set its state to Available
       	    assoc = ConcretePackageVersion.where( package_version: pkgVersion, system: currentSys )[0]
            assoc.concrete_package_state = stateAvailable
            assoc.save()
	  else
            assoc = ConcretePackageVersion.new
            assoc.system = currentSys
            assoc.concrete_package_state = stateAvailable
            assoc.package_version = pkgVersion
            assoc.save()

            currentSys.concrete_package_versions << assoc
          end
        else
          unknownPackages.push( updHash )
        end
      end
      currentSys.save()

      if unknownPackages.length > 0
        render json: { status: "infoIncomplete", knownPackages: knownPackages }
      else
        if currentSys.concrete_package_versions.count != data["updCount"]
          render json: { status: "countMismatch", knownPackages: knownPackages }
        else
          render json: { status: "OK", knownPackages: knownPackages  }
        end
      end
    end

    # v2/system/:urn/notify
    def updateSystem
      data = JSON.parse request.body.read

      if check_mandatory_json_params(data, ["updCount", "packageUpdates"]) || !System.exists?(urn: params[:urn])
        render json: { status: "ERROR" }
        return
      end

      stateAvailable = ConcretePackageState.first
      error = false
      unknownPackages = false

      currentSys = System.where(urn: params[:urn])[0]
      apply_system_properties( currentSys, data )
      error = true unless currentSys.save()


      data["packageUpdates"].each do |update|
	# best case: CC already knows the version that's available
        if PackageVersion.exists?( sha256: update['hash'] )
          pkgVersion = PackageVersion.where( sha256: update['hash'] )[0]

          assoc = ConcretePackageVersion.new
          assoc.system = currentSys
          assoc.concrete_package_state = stateAvailable
          assoc.package_version = pkgVersion
          error = true unless assoc.save()

          currentSys.concrete_package_versions << assoc
          error = true unless currentSys.save()
        else
	  # 2nd best option: specific version is unknown, but package itself is known
          if Package.exists?( name: update['name'] )
            pkg = Package.where( name: update['name'] )[0]

            pkgVersion = PackageVersion.new
            pkgVersion.sha256 = update['sha256'] if update['sha256']
            pkgVersion.version = update['version'] if update['version']
            pkgVersion.architecture = update['architecture'] if update['architecture']
            pkgVersion.package = pkg

            if update['sha256'] == update['baseVersion']
              # this is a base_version
            elsif PackageVersion.exists?( sha256: update['baseVersion'] )
              pkgVersion.base_version = PackageVersion.where( sha256: update['baseVersion'] )[0]
            else
              # send pkgUnknown!
              unknownPackages = true
            end

            if update['repository']
              rep = update['repository']
              if Repository.exists?( archive: rep['archive'], origin: rep['origin'], component: rep['component'] )
                newRepo = Repository.where( archive: rep['archive'], origin: rep['origin'], component: rep['component'] )[0]
              else
                newRepo = Repository.create(archive: rep['archive'], origin: rep['origin'], component: rep['component'] )
              end
              pkgVersion.repository = newRepo
            end

	    # TODO: refactor distro handling
	    if currentSys.os
   	      if Distribution.exists?(name: currentSys.os)
  		dist = Distribution.where(name: currentSys.os)[0]
                pkgVersion.distribution = dist
              end
            end
            error = true unless pkgVersion.save()

            pkg.package_versions << pkgVersion
            error = true unless pkg.save()

            # only create new CPV if it doesn't already exist!
            if ConcretePackageVersion.exists?( package_version: pkgVersion, system: currentSys )
              # If it exists, set its state to Available
              assoc = ConcretePackageVersion.where( package_version: pkgVersion, system: currentSys )[0]
              assoc.concrete_package_state = stateAvailable
              error = true unless assoc.save()
 	    else
	      assoc = ConcretePackageVersion.new
              assoc.system = currentSys
              assoc.concrete_package_state = stateAvailable
              assoc.package_version = pkgVersion
              error = true unless assoc.save()

              currentSys.concrete_package_versions << assoc
              error = true unless currentSys.save()
            end

          else
            # send pkgUnknown!
            unknownPackages = true
          end
        end
      end

      if error
        render json: { status: "ERROR" }
      elsif unknownPackages
        render json: { status: "pkgUnknown" }
      elsif currentSys.concrete_package_versions.count != data["updCount"]
        render json: { status: "countMismatch" }
      else
        render json: { status: "OK" }
      end
    end

    # v2/system/:urn/refresh-installed-hash
    def refreshInstalledHash
      data = JSON.parse request.body.read

      if check_mandatory_json_params(data, ["pkgCount", "packages"]) || !System.exists?(:urn => data["urn"])
        render json: { status: "ERROR" }
        return
      end

      unknownPackages = []
      knownPackages = []
      error = false
      stateInstalled = ConcretePackageState.last

      currentSys = System.where(urn: params[:urn])[0]
      error = true unless currentSys.save()

      data["packages"].each do |pkgHash|
        if PackageVersion.exists?( sha256: pkgHash )
          pkgVersion = PackageVersion.where( sha256: pkgHash )[0]

          assoc = ConcretePackageVersion.create({
            :system => currentSys,
            :concrete_package_state => stateInstalled,
            :package_version => pkgVersion
          })

          currentSys.concrete_package_versions << assoc
          error = true unless currentSys.save()

          knownPackages.push( pkgHash )
        else
          unknownPackages.push( pkgHash )
        end
      end

      if error
        render json: { status: "ERROR" }
      elsif unknownPackages.length > 0
        render json: { status: "infoIncomplete", knownPackages: knownPackages }
      elsif currentSys.current_package_versions.count == data["pkgCount"]
        render json: { status: "countMismatch", knownPackages: knownPackages  }
      else
        render json: { status: "OK", knownPackages: knownPackages  }
      end
    end

    # v2/system/:urn/refresh-installed
    def refreshInstalled
      data = JSON.parse request.body.read

      if check_mandatory_json_params(data, ["pkgCount", "packages"]) || !System.exists?(:urn => data["urn"])
        render json: { status: "ERROR" }
        return
      end

      currentSys = System.where(urn: params[:id])[0]

      data["packages"].each do |package|

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

        if PackageVersion.exists?(:system => currentSys, :package => currentPkg)
          # updating link system <=> package
          currentInstall = PackageVersion.where(:system => currentSys, :package => currentPkg)[0]
          currentInstall.installed_version = package['version']
          currentInstall.save
        else
          # creating link system <=> package
          PackageVersion.create({
                 :system            => currentSys,
                 :package           => currentPkg,
                 :installed_version => package['version']
          })
        end
      end
      render json: { status: "OK" }
    end

    # v2/task/:id/notify
    def updateTask
      data = JSON.parse request.body.read

      if check_mandatory_json_params(data, ["state", "log"]) || !Task.exists?(params[:id])
        render json: { status: "ERROR" }
        return
      end

      task = Task.find(params[:id])
      state = TaskState.where(:name => data["state"] ).first
      if state
        task.task_state = state
        # TODO + log
        if task.save()
          render json: { status: "OK" }
          return
        end
      end
      render json: { status: "ERROR" }
    end
  end
end
