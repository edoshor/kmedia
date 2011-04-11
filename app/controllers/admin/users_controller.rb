class Admin::UsersController < ApplicationController
  layout 'admin'

  before_filter :get_user, :only => [:index, :new, :edit]
  before_filter :accessible_roles, :only => [:new, :edit, :show, :update, :create]
  load_and_authorize_resource :only => [:show, :new, :destroy, :edit, :update]

  # GET /users
  # GET /users.xml
  # GET /users.json                                       HTML and AJAX
  #-----------------------------------------------------------------------
  def index
    @users = User.accessible_by(current_ability, :index).order(:id).page(params[:page])
  end

  # GET /users/new
  # GET /users/new.xml
  # GET /users/new.json                                    HTML AND AJAX
  #-------------------------------------------------------------------
  def new
  end

  # GET /users/1
  # GET /users/1.xml
  # GET /users/1.json                                     HTML AND AJAX
  #-------------------------------------------------------------------
  def show
  end

  # GET /users/1/edit
  # GET /users/1/edit.xml
  # GET /users/1/edit.json                                HTML AND AJAX
  #-------------------------------------------------------------------
  def edit
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  # DELETE /users/1.json                                  HTML AND AJAX
  #-------------------------------------------------------------------
  def destroy
    @user.destroy!

    redirect_to admin_users_url, :notice => "Successfully destroyed admin/user."
  end

  # POST /users
  # POST /users.xml
  # POST /users.json                                      HTML AND AJAX
  #-----------------------------------------------------------------
  def create
    @user = User.new(params[:user])
    authorize! :create, @user

    if @user.save
      redirect_to admin_user_path(@user), :notice => "Successfully created admin/user."
    else
      render :action => 'new'
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  # PUT /users/1.json                                            HTML AND AJAX
  #----------------------------------------------------------------------------
  def update
    @user = User.find(params[:id])
    authorize! :update, @user

    if params[:user][:password].blank?
      [:password, :password_confirmation, :current_password].collect { |p| params[:user].delete(p) }
    else
      @user.errors[:base] << "The password you entered is incorrect" unless @user.valid_password?(params[:user][:current_password])
    end

    if @user.errors[:base].empty?
      @user.send(:attributes=, params[:user], false)
      redirect_to admin_user_path(@user), :notice => "Your account has been updated"
    else
      render :action => 'edit'
    end
  end

  # Get roles accessible by the current user
  #----------------------------------------------------
  def accessible_roles
    @accessible_roles = Role.accessible_by(current_ability, :read)
  end

  # Make the current user object available to views
  #----------------------------------------
  def get_user
    @current_user = current_user
  end
end
