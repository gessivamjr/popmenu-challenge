class MenuController < ApplicationController
  before_action :set_menu, only: %i[show update destroy]

  def index
    menus = Menu.all
    render json: menus, status: :ok
  end

  def show
    render json: @menu, status: :ok
  end

  def create
    menu = Menu.new(menu_params)

    unless menu.valid?
      return render json: { errors: menu.errors.full_messages }, status: :unprocessable_content
    end

    menu.save!

    render json: menu, status: :created
  end

  def update
    unless @menu.update(menu_params)
      return render json: { errors: @menu.errors.full_messages }, status: :unprocessable_content
    end

    render json: @menu, status: :ok
  end

  def destroy
    @menu.destroy!

    render json: { message: "Menu deleted successfully" }, status: :ok
  end

  private

  def menu_params
    params.permit(:name, :description, :category, :active, :starts_at, :ends_at)
  end

  def set_menu
    @menu = Menu.includes(:menu_items).find_by(id: params[:id])

    if @menu.nil?
      return render json: { error: "Menu not found" }, status: :not_found
    end
  end
end
