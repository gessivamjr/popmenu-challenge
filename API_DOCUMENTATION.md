# API Documentation

This document describes all available API endpoints for the Restaurants platform MVP.

## Base URL
All endpoints are relative to your server's base URL (e.g., `http://localhost:3000`)

## Common Parameters
Most list endpoints support pagination:
- `page` (optional): Page number, defaults to 1
- `per_page` (optional): Items per page, defaults to 10

## Response Format
- Success responses return JSON data with appropriate HTTP status codes
- Error responses return JSON with an `error` or `errors` field
- Timestamps are in ISO 8601 format: `"2024-01-15T10:30:45.123Z"`

---

## Restaurant Controller

### GET /restaurant
Returns a paginated list of all restaurants with their associated menus and menu items.

**Parameters:**
- `page` (optional): Page number
- `per_page` (optional): Items per page

**Response Example:**
```json
[
  {
    "id": 1,
    "name": "The Great Eatery",
    "description": "Amazing food and atmosphere",
    "address_line_1": "456 Oak Avenue",
    "address_line_2": "Floor 2",
    "city": "San Francisco",
    "state": "CA",
    "zip_code": "94102",
    "phone_number": "(415) 555-0123",
    "email": "info@greateatery.com",
    "website_url": "https://www.greateatery.com",
    "logo_url": "https://example.com/logo.png",
    "cover_image_url": "https://example.com/cover.png",
    "created_at": "2024-01-15T10:30:45.123Z",
    "updated_at": "2024-01-15T10:30:45.123Z",
    "menus": [
      {
        "id": 1,
        "name": "Dinner Menu",
        "description": "Evening dining options",
        "category": "dinner",
        "active": true,
        "starts_at": 17,
        "ends_at": 22,
        "menu_menu_items": [
          {
            "id": 1,
            "name": "Grilled Salmon",
            "price": "24.99",
            "currency": "USD",
            "description": "Fresh Atlantic salmon with herbs",
            "category": "main_course",
            "available": true,
            "prep_time_minutes": 20,
            "image_url": "https://example.com/salmon.jpg"
          }
        ]
      }
    ]
  }
]
```

### GET /restaurant/:id
Returns a specific restaurant with all associated data.

**Parameters:**
- `id` (required): Restaurant ID

**Response Example:**
```json
{
  "id": 1,
  "name": "The Great Eatery",
  "description": "Amazing food and atmosphere",
  "address_line_1": "456 Oak Avenue",
  "address_line_2": "Floor 2",
  "city": "San Francisco",
  "state": "CA",
  "zip_code": "94102",
  "phone_number": "(415) 555-0123",
  "email": "info@greateatery.com",
  "website_url": "https://www.greateatery.com",
  "logo_url": "https://example.com/logo.png",
  "cover_image_url": "https://example.com/cover.png",
  "created_at": "2024-01-15T10:30:45.123Z",
  "updated_at": "2024-01-15T10:30:45.123Z",
  "menus": []
}
```

**Error Response (404):**
```json
{
  "error": "Restaurant not found"
}
```

### POST /restaurant
Creates a new restaurant.

**Required Parameters:**
- `name` (string): Restaurant name

**Optional Parameters:**
- `description` (string): Restaurant description
- `address_line_1` (string): Primary address line
- `address_line_2` (string): Secondary address line
- `city` (string): City
- `state` (string): State
- `zip_code` (string): ZIP code
- `phone_number` (string): Phone number
- `email` (string): Email address
- `website_url` (string): Website URL
- `logo_url` (string): Logo image URL
- `cover_image_url` (string): Cover image URL

**Request Example:**
```json
{
  "name": "The Great Eatery",
  "description": "Amazing food and atmosphere",
  "address_line_1": "456 Oak Avenue",
  "city": "San Francisco",
  "state": "CA",
  "email": "info@greateatery.com"
}
```

**Response Example (201):**
```json
{
  "id": 1,
  "name": "The Great Eatery",
  "description": "Amazing food and atmosphere",
  "address_line_1": "456 Oak Avenue",
  "address_line_2": null,
  "city": "San Francisco",
  "state": "CA",
  "zip_code": null,
  "phone_number": null,
  "email": "info@greateatery.com",
  "website_url": null,
  "logo_url": null,
  "cover_image_url": null,
  "created_at": "2024-01-15T10:30:45.123Z",
  "updated_at": "2024-01-15T10:30:45.123Z",
  "menus": []
}
```

**Error Response (422):**
```json
{
  "errors": ["Name can't be blank"]
}
```

### PATCH /restaurant/:id
Updates an existing restaurant.

**Parameters:**
- `id` (required): Restaurant ID
- All optional parameters from POST (any subset can be provided)

**Request Example:**
```json
{
  "name": "Updated Restaurant Name",
  "city": "Los Angeles"
}
```

**Response Example (200):**
```json
{
  "id": 1,
  "name": "Updated Restaurant Name",
  "description": "Amazing food and atmosphere",
  "address_line_1": "456 Oak Avenue",
  "city": "Los Angeles",
  "state": "CA",
  "updated_at": "2024-01-15T11:30:45.123Z"
}
```

### DELETE /restaurant/:id
Deletes a restaurant and all associated menus and menu items.

**Parameters:**
- `id` (required): Restaurant ID

**Response Example (200):**
```json
{
  "message": "Restaurant deleted successfully"
}
```

---

## Menu Controller

### GET /restaurant/:restaurant_id/menu
Returns all menus for a specific restaurant.

**Parameters:**
- `restaurant_id` (required): Restaurant ID
- `page` (optional): Page number
- `per_page` (optional): Items per page

**Response Example:**
```json
[
  {
    "id": 1,
    "name": "Breakfast Menu",
    "description": "Fresh morning delights",
    "category": "breakfast",
    "active": true,
    "starts_at": 6,
    "ends_at": 11,
    "restaurant_id": 1,
    "created_at": "2024-01-15T10:30:45.123Z",
    "updated_at": "2024-01-15T10:30:45.123Z",
    "menu_menu_items": []
  }
]
```

### GET /restaurant/:restaurant_id/menu/:id
Returns a specific menu with its items.

**Parameters:**
- `restaurant_id` (required): Restaurant ID
- `id` (required): Menu ID

**Response Example:**
```json
{
  "id": 1,
  "name": "Breakfast Menu",
  "description": "Fresh morning delights",
  "category": "breakfast",
  "active": true,
  "starts_at": 6,
  "ends_at": 11,
  "restaurant_id": 1,
  "created_at": "2024-01-15T10:30:45.123Z",
  "updated_at": "2024-01-15T10:30:45.123Z",
  "menu_menu_items": [
    {
      "id": 1,
      "name": "Grilled Salmon",
      "price": "24.99",
      "currency": "USD",
      "description": "Fresh Atlantic salmon with herbs",
      "category": "main_course",
      "available": true,
      "prep_time_minutes": 20,
      "image_url": "https://example.com/salmon.jpg"
    }
  ]
}
```

### POST /restaurant/:restaurant_id/menu
Creates a new menu for a restaurant.

**Required Parameters:**
- `restaurant_id` (required): Restaurant ID
- `name` (string): Menu name

**Optional Parameters:**
- `description` (string): Menu description
- `category` (string): Menu category
- `active` (boolean): Whether menu is active
- `starts_at` (integer): Start hour (0-23)
- `ends_at` (integer): End hour (0-23)

**Request Example:**
```json
{
  "name": "Breakfast Menu",
  "description": "Fresh morning delights",
  "category": "breakfast",
  "active": true,
  "starts_at": 6,
  "ends_at": 11
}
```

**Response Example (201):**
```json
{
  "id": 1,
  "name": "Breakfast Menu",
  "description": "Fresh morning delights",
  "category": "breakfast",
  "active": true,
  "starts_at": 6,
  "ends_at": 11,
  "restaurant_id": 1,
  "created_at": "2024-01-15T10:30:45.123Z",
  "updated_at": "2024-01-15T10:30:45.123Z",
  "menu_menu_items": []
}
```

**Error Response (422):**
```json
{
  "errors": [
    "Name can't be blank",
    "Starts at must be a valid hour (0-23)",
    "Start time must be before end time"
  ]
}
```

### PATCH /restaurant/:restaurant_id/menu/:id
Updates an existing menu.

**Parameters:**
- `restaurant_id` (required): Restaurant ID
- `id` (required): Menu ID
- All optional parameters from POST (any subset can be provided)

**Response Example (200):**
```json
{
  "id": 1,
  "name": "Breakfast Menu",
  "description": "Fresh morning delights",
  "category": "breakfast",
  "active": true,
  "starts_at": 6,
  "ends_at": 11,
  "restaurant_id": 1,
  "created_at": "2024-01-15T10:30:45.123Z",
  "updated_at": "2024-01-15T10:30:45.123Z",
  "menu_menu_items": []
}
```

### DELETE /restaurant/:restaurant_id/menu/:id
Deletes a menu and removes all associated menu item relationships.

**Response Example (200):**
```json
{
  "message": "Menu deleted successfully"
}
```

### POST /restaurant/:restaurant_id/menu/:id/add_menu_item
Adds a menu item to a specific menu.

**Required Parameters:**
- `restaurant_id` (required): Restaurant ID
- `id` (required): Menu ID
- `name` (string): Menu item name
- `price` (decimal): Price

**Optional Parameters:**
- `currency` (string): Currency code
- `description` (string): Item description
- `category` (string): Item category
- `available` (boolean): Item availability
- `prep_time_minutes` (integer): Preparation time
- `image_url` (string): Item image URL

**Request Example:**
```json
{
  "name": "Grilled Salmon",
  "description": "Fresh Atlantic salmon with herbs",
  "category": "main_course",
  "price": 24.99,
  "currency": "USD",
  "available": true,
  "image_url": "https://example.com/salmon.jpg",
  "prep_time_minutes": 20
}
```

**Response Example (201):**
```json
{
  "message": "Menu item added successfully"
}
```

### PATCH /restaurant/:restaurant_id/menu/:id/update_menu_item
Updates a menu item on a specific menu.

**Required Parameters:**
- `restaurant_id` (required): Restaurant ID
- `id` (required): Menu ID
- `menu_item_id` (integer): Menu item ID to update

**Optional Parameters:**
- `description` (string): Item description
- `category` (string): Item category
- `price` (decimal): Price
- `currency` (string): Currency code
- `available` (boolean): Item availability
- `prep_time_minutes` (integer): Preparation time
- `image_url` (string): Item image URL

**Request Example:**
```json
{
  "menu_item_id": 1,
  "description": "Updated description with new details",
  "price": 29.99,
  "available": false
}
```

**Response Example (200):**
```json
{
  "message": "Menu item updated successfully"
}
```

### DELETE /restaurant/:restaurant_id/menu/:id/remove_menu_item
Removes a menu item from a specific menu.

**Required Parameters:**
- `restaurant_id` (required): Restaurant ID
- `id` (required): Menu ID
- `menu_item_id` (integer): Menu item ID to remove

**Response Example (200):**
```json
{
  "message": "Menu item removed successfully"
}
```

---

## Menu Item Controller

### GET /menu_item
Returns a paginated list of all menu items with their associated menus.

**Parameters:**
- `page` (optional): Page number
- `per_page` (optional): Items per page

**Response Example:**
```json
[
  {
    "id": 1,
    "name": "Grilled Salmon",
    "created_at": "2024-01-15T10:30:45.123Z",
    "updated_at": "2024-01-15T10:30:45.123Z",
    "menus": [
      {
        "id": 1,
        "name": "Dinner Menu",
        "restaurant_id": 1
      }
    ]
  }
]
```

### GET /menu_item/:id
Returns a specific menu item with its associated menus.

**Parameters:**
- `id` (required): Menu item ID

**Response Example:**
```json
{
  "id": 1,
  "name": "Grilled Salmon",
  "created_at": "2024-01-15T10:30:45.123Z",
  "updated_at": "2024-01-15T10:30:45.123Z",
  "menus": [
    {
      "id": 1,
      "name": "Dinner Menu",
      "restaurant_id": 1
    }
  ]
}
```

### POST /menu_item
Creates a new menu item.

**Required Parameters:**
- `menu_item` (object): Container object
  - `name` (string): Menu item name (must be unique)

**Request Example:**
```json
{
  "menu_item": {
    "name": "Grilled Salmon"
  }
}
```

**Response Example (201):**
```json
{
  "id": 1,
  "name": "Grilled Salmon",
  "created_at": "2024-01-15T10:30:45.123Z",
  "updated_at": "2024-01-15T10:30:45.123Z",
  "menus": []
}
```

**Error Response (422):**
```json
{
  "errors": ["Name has already been taken"]
}
```

**Error Response (400):**
```json
{
  "error": "Missing required parameter: menu_item"
}
```

### PATCH /menu_item/:id
Updates an existing menu item.

**Required Parameters:**
- `id` (required): Menu item ID
- `menu_item` (object): Container object
  - `name` (string): Updated menu item name

**Request Example:**
```json
{
  "menu_item": {
    "name": "Updated Menu Item Name"
  }
}
```

**Response Example (200):**
```json
{
  "id": 1,
  "name": "Updated Menu Item Name",
  "created_at": "2024-01-15T10:30:45.123Z",
  "updated_at": "2024-01-15T11:30:45.123Z",
  "menus": []
}
```

### DELETE /menu_item/:id
Deletes a menu item and removes all associated menu relationships.

**Parameters:**
- `id` (required): Menu item ID

**Response Example (200):**
```json
{
  "message": "Menu item deleted successfully"
}
```

---

## Restaurant Import Controller

### POST /restaurant/import
Schedules the import of restaurant data from a JSON file.

**Required Parameters:**
- `file` (file): JSON file containing restaurant data

**File Requirements:**
- Must have `.json` extension (case insensitive)
- Must have valid JSON content type (`application/json`, `text/json`, or `text/plain`)
- Must contain valid JSON content

**Request Example:**
```bash
curl -X POST http://localhost:3000/restaurant/import \
  -F "file=@restaurants.json"
```

**Response Example (200):**
```json
{
  "message": "Import scheduled to be processed"
}
```

**Error Responses:**

**Missing file (400):**
```json
{
  "error": "Missing required parameter: file"
}
```

**Invalid file extension (422):**
```json
{
  "error": "File must be a JSON file (.json extension required)"
}
```

**Invalid content type (422):**
```json
{
  "error": "File must have a valid JSON content type"
}
```

**Invalid JSON content (422):**
```json
{
  "error": "File must contain valid JSON content"
}
```

---

## Common Error Responses

### Validation Errors (422 Unprocessable Content)
```json
{
  "errors": [
    "Name can't be blank",
    "Price must be greater than or equal to 0"
  ]
}
```

### Resource Not Found (404)
```json
{
  "error": "Restaurant not found"
}
```

### Missing Parameter (400 Bad Request)
```json
{
  "error": "Missing required parameter: menu_item"
}
```

---

## Notes

1. **Menu Items**: Menu items are created globally but associated with specific menus through the `menu_menu_items` join table. The same menu item can appear on multiple menus with different prices and attributes.

2. **Pagination**: All list endpoints support pagination. If no pagination parameters are provided, defaults to page 1 with 10 items per page.

3. **Time Fields**: Menu `starts_at` and `ends_at` fields represent hours (0-23). Both must be provided together or both can be nil.

4. **Cascading Deletes**: 
   - Deleting a restaurant removes all associated menus and menu item relationships
   - Deleting a menu removes all associated menu item relationships
   - Deleting a menu item removes all associated menu relationships

5. **File Upload**: The import endpoint accepts JSON files and schedules background processing. File validation happens synchronously, but the actual import is processed asynchronously.
