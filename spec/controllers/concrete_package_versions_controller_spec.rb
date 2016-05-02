require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

RSpec.describe ConcretePackageVersionsController, type: :controller do

  # This should return the minimal set of attributes required to create a valid
  # ConcretePackageVersion. As you add validations to ConcretePackageVersion, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    skip("Add a hash of attributes valid for your model")
  }

  let(:invalid_attributes) {
    skip("Add a hash of attributes invalid for your model")
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # ConcretePackageVersionsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #index" do
    it "assigns all concrete_package_versions as @concrete_package_versions" do
      concrete_package_version = ConcretePackageVersion.create! valid_attributes
      get :index, {}, valid_session
      expect(assigns(:concrete_package_versions)).to eq([concrete_package_version])
    end
  end

  describe "GET #show" do
    it "assigns the requested concrete_package_version as @concrete_package_version" do
      concrete_package_version = ConcretePackageVersion.create! valid_attributes
      get :show, {:id => concrete_package_version.to_param}, valid_session
      expect(assigns(:concrete_package_version)).to eq(concrete_package_version)
    end
  end

  describe "GET #new" do
    it "assigns a new concrete_package_version as @concrete_package_version" do
      get :new, {}, valid_session
      expect(assigns(:concrete_package_version)).to be_a_new(ConcretePackageVersion)
    end
  end

  describe "GET #edit" do
    it "assigns the requested concrete_package_version as @concrete_package_version" do
      concrete_package_version = ConcretePackageVersion.create! valid_attributes
      get :edit, {:id => concrete_package_version.to_param}, valid_session
      expect(assigns(:concrete_package_version)).to eq(concrete_package_version)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new ConcretePackageVersion" do
        expect {
          post :create, {:concrete_package_version => valid_attributes}, valid_session
        }.to change(ConcretePackageVersion, :count).by(1)
      end

      it "assigns a newly created concrete_package_version as @concrete_package_version" do
        post :create, {:concrete_package_version => valid_attributes}, valid_session
        expect(assigns(:concrete_package_version)).to be_a(ConcretePackageVersion)
        expect(assigns(:concrete_package_version)).to be_persisted
      end

      it "redirects to the created concrete_package_version" do
        post :create, {:concrete_package_version => valid_attributes}, valid_session
        expect(response).to redirect_to(ConcretePackageVersion.last)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved concrete_package_version as @concrete_package_version" do
        post :create, {:concrete_package_version => invalid_attributes}, valid_session
        expect(assigns(:concrete_package_version)).to be_a_new(ConcretePackageVersion)
      end

      it "re-renders the 'new' template" do
        post :create, {:concrete_package_version => invalid_attributes}, valid_session
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        skip("Add a hash of attributes valid for your model")
      }

      it "updates the requested concrete_package_version" do
        concrete_package_version = ConcretePackageVersion.create! valid_attributes
        put :update, {:id => concrete_package_version.to_param, :concrete_package_version => new_attributes}, valid_session
        concrete_package_version.reload
        skip("Add assertions for updated state")
      end

      it "assigns the requested concrete_package_version as @concrete_package_version" do
        concrete_package_version = ConcretePackageVersion.create! valid_attributes
        put :update, {:id => concrete_package_version.to_param, :concrete_package_version => valid_attributes}, valid_session
        expect(assigns(:concrete_package_version)).to eq(concrete_package_version)
      end

      it "redirects to the concrete_package_version" do
        concrete_package_version = ConcretePackageVersion.create! valid_attributes
        put :update, {:id => concrete_package_version.to_param, :concrete_package_version => valid_attributes}, valid_session
        expect(response).to redirect_to(concrete_package_version)
      end
    end

    context "with invalid params" do
      it "assigns the concrete_package_version as @concrete_package_version" do
        concrete_package_version = ConcretePackageVersion.create! valid_attributes
        put :update, {:id => concrete_package_version.to_param, :concrete_package_version => invalid_attributes}, valid_session
        expect(assigns(:concrete_package_version)).to eq(concrete_package_version)
      end

      it "re-renders the 'edit' template" do
        concrete_package_version = ConcretePackageVersion.create! valid_attributes
        put :update, {:id => concrete_package_version.to_param, :concrete_package_version => invalid_attributes}, valid_session
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested concrete_package_version" do
      concrete_package_version = ConcretePackageVersion.create! valid_attributes
      expect {
        delete :destroy, {:id => concrete_package_version.to_param}, valid_session
      }.to change(ConcretePackageVersion, :count).by(-1)
    end

    it "redirects to the concrete_package_versions list" do
      concrete_package_version = ConcretePackageVersion.create! valid_attributes
      delete :destroy, {:id => concrete_package_version.to_param}, valid_session
      expect(response).to redirect_to(concrete_package_versions_url)
    end
  end

end
