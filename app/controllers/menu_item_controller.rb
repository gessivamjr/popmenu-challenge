class MenuItemController < ApplicationController
  before_action :set_menu, only: %i[index show create]
  before_action :set_menu_item, only: %i[show update destroy]

  def index
    menu_items = @menu.menu_items
    render json: menu_items, status: :ok
  end

  def show
    render json: @menu_item, status: :ok
  end

  def create
    menu_item = MenuItem.new(menu_item_params)
    menu_item.menu = @menu

    unless menu_item.valid?
      return render json: { errors: menu_item.errors.full_messages }, status: :unprocessable_content
    end

    menu_item.save!

    render json: menu_item, status: :created
  end

  def update
    unless @menu_item.update(menu_item_params)
      return render json: { errors: @menu_item.errors.full_messages }, status: :unprocessable_content
    end

    render json: @menu_item, status: :ok
  end

  def destroy
    @menu_item.destroy!

    render json: { message: "Menu item deleted successfully" }, status: :ok
  end

  private

  def menu_item_params
    params.permit(:name, :description, :category, :price, :currency, :available, :image_url, :prep_time_minutes)
  end

  def set_menu
    @menu = Menu.includes(:menu_items).find_by(id: params[:menu_id])

    if @menu.nil?
      return render json: { error: "Menu not found" }, status: :not_found
    end
  end

  def set_menu_item
    @menu_item = MenuItem.includes(:menu).find_by(id: params[:id], menu_id: params[:menu_id])

    if @menu_item.nil?
      return render json: { error: "Menu item not found" }, status: :not_found
    end

    @menu = @menu_item.menu

    if @menu.nil?
      return render json: { error: "Menu not found" }, status: :not_found
    end
  end
end
