# RapidTable

A Ruby gem for building feature-rich data tables in Rails applications using ViewComponent. RapidTable provides a declarative DSL for defining columns, sorting, searching, exporting, pagination, and bulk actions.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "rapid_table"
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install rapid_table
```

Run the install generator to create the base table component:

```bash
rails generate rapid_table:install
```

## Requirements

- Ruby >= 3.1.0
- Rails >= 7.0
- ViewComponent >= 3.0

## Usage

Create a table class that inherits from `ApplicationTable`:

```ruby
class UsersTable < ApplicationTable
  columns do |t|
    t.integer :id
    t.string :name, label: "Full Name"
    t.string :email, sortable: true
    t.datetime :created_at, label: "Joined"
  end

  self.sort_column = :name
  self.sort_order = "asc"
end
```

Render the table in your view:

```erb
<%= render UsersTable.new(User.all) %>
```

Or pass records with options:

```erb
<%= render UsersTable.new(@users, only: [:name, :email]) %>
```

## Features

### Columns

Define columns using the `columns` block with typed column methods:

```ruby
class UsersTable < ApplicationTable
  columns do |t|
    t.integer :id, label: "ID"
    t.string :name, label: "Full Name"
    t.string :email
    t.datetime :created_at
  end

  # explicit logic for rendering the email column
  column_html :email do |record|
    link_to record.email, "mailto:#{record.email}"
  end
end
```

**Available column types:**

| Type | Description | Example Output |
|------|-------------|----------------|
| `string` | Basic string | `"Hello"` |
| `integer` | Number with thousands separators | `1,234,567` |
| `float` | Decimal with 2 places | `1,234.50` |
| `date` | Human-readable date | `January 15, 2024` |
| `datetime` | Date with time | `January 15, 2024 14:30` |
| `boolean` | Yes/No display | `Yes` or `No` |
| `currency` | Dollar format | `$1,234.50` |
| `percentage` | Percentage format | `75.00%` |

Define your own column types to reuse across all tables:

```ruby
class ApplicationTable < RapidTable::Base
  extend RapidTable::DSL

  # Define a custom type for email links
  column_type :email do |value|
    link_to value, "mailto:#{value}"
  end

  # Define a custom type for file sizes
  column_type :filesize do |value|
    number_to_human_size(value)
  end
end

class UsersTable < ApplicationTable
  columns do |t|
    t.string :name
    t.email :email          # Uses custom email type
    t.filesize :avatar_size # Uses custom filesize type
  end
end
```

The block receives the column value and has access to all Rails view helpers. Nil values are handled automatically and won't be passed to the block.

**Column options:**

- `label` - Display label for the column header (defaults to titleized id)
- `sortable` - Whether the column is sortable (default: false)
- `skip_export` - Exclude column from exports (default: false)

**Filter columns at runtime:**

```ruby
# Show only specific columns
UsersTable.new(@users, only: [:name, :email])

# Exclude specific columns
UsersTable.new(@users, except: [:id])
```

**Column groups:**

```ruby
class UsersTable < ApplicationTable
  columns do |t|
    t.integer :id
    t.string :name
    t.string :email
    t.string :phone
  end

  column_group :basic, [:name, :email]
  column_group :contact, [:email, :phone]
end

# Use a column group
UsersTable.new(@users, column_group_id: :basic)
```

### Export

Export table data to CSV or JSON formats:

```ruby
class UsersTable < ApplicationTable
  columns do |t|
    t.integer :id
    t.string :name
    t.string :secret, skip_export: true  # Excluded from exports
  end

  self.export_formats = [:csv, :json]
  self.csv_column_separator = ","
  self.export_batch_size = 1000
end
```

**Export methods:**

```ruby
table = UsersTable.new(User.all)

# JSON export
table.to_json  # => [{id: 1, name: "John"}, ...]

# CSV streaming
table.stream_csv(response.stream)
```

**Disable export:**

```ruby
class UsersTable < ApplicationTable
  self.skip_export = true
end

# Or at instance level
UsersTable.new(@users, skip_export: true)
```

### Search

Enable search functionality on your tables:

```ruby
class UsersTable < ApplicationTable
  self.search_param = :q  # URL parameter for search (default: :q)
end
```

The search query is read from `params[:q]` (or your configured param). For ActiveRecord adapters, this calls a `search` scope on your model. For Array adapters, mark columns as searchable:

```ruby
columns do |t|
  t.string :name, searchable: true
  t.string :email, searchable: true
end
```

**Disable search:**

```ruby
class UsersTable < ApplicationTable
  self.skip_search = true
end
```

### Sorting

Make columns sortable and configure default sort behavior:

```ruby
class UsersTable < ApplicationTable
  columns do |t|
    t.integer :id
    t.string :name, sortable: true, sort_order: "asc"
    t.datetime :created_at, sortable: true
  end

  self.sort_column = :name
  self.sort_order = "desc"
  self.sort_column_param = :sort  # URL parameter (default: :sort)
  self.sort_order_param = :dir    # URL parameter (default: :dir)
end
```

**Disable sorting:**

```ruby
class UsersTable < ApplicationTable
  self.skip_sorting = true
end
```

## Adapters

Adapters provide data source-specific implementations for filtering, sorting, searching, and pagination.

### ActiveRecord

For tables backed by ActiveRecord relations:

```ruby
class UsersTable < ApplicationTable
  include RapidTable::Adapters::ActiveRecord

  columns do |t|
    t.string :name, sortable: true, nulls_last: true
  end
end

# Usage
UsersTable.new(User.all)
UsersTable.new(User.where(active: true))
```

**Features:**

- Automatic sorting with `ORDER BY` (supports `nulls_last` option)
- Search integration via model's `search` scope
- Efficient batch iteration with `find_each`

### Array

For tables backed by plain Ruby arrays:

```ruby
class ItemsTable < ApplicationTable
  include RapidTable::Adapters::Array

  columns do |t|
    t.string :name, sortable: true, searchable: true
    t.currency :price, sortable: true
  end
end

# Usage with array of objects
items = [
  OpenStruct.new(name: "Item 1", price: 10),
  OpenStruct.new(name: "Item 2", price: 20)
]
ItemsTable.new(items)
```

**Features:**

- In-memory sorting with nil handling
- Case-insensitive search on `searchable` columns
- Built-in pagination via `PaginatedArray`

### Kaminari

For tables using Kaminari pagination:

```ruby
class UsersTable < ApplicationTable
  include RapidTable::Adapters::ActiveRecord
  include RapidTable::Adapters::Kaminari

  self.per_page = 25
end

# Usage
UsersTable.new(User.all)
```

**Features:**

- Integrates with Kaminari's `page` and `per` methods
- Provides `total_pages`, `current_page`, and `total_records_count`


## Ext

Extensions provide additional functionality that can be included in your tables.

### Pagination

Pagination is provided by adapters (Array, Kaminari) that include `RapidTable::Ext::Pagination`. Configure pagination options on your table:

```ruby
class UsersTable < ApplicationTable
  include RapidTable::Adapters::Kaminari  # Provides pagination

  self.per_page = 25
  self.available_per_pages = [10, 25, 50, 100]
  self.page_param = :page     # URL parameter (default: :page)
  self.per_page_param = :per  # URL parameter (default: :per)
end
```

**Pagination methods:**

```ruby
table.current_page      # Current page number
table.total_pages       # Total number of pages
table.total_records_count  # Total record count
table.only_ever_one_page?  # True if total records fit on one page
```

**Disable pagination:**

```ruby
self.skip_pagination = true
```

### BulkActions

Enable bulk selection and actions on table rows:

```ruby
class UsersTable < ApplicationTable
  include RapidTable::Ext::BulkActions

  bulk_action :delete, label: "Delete Selected"
  bulk_action :archive, label: "Archive Selected"
  bulk_action :export

  self.bulk_actions_param = :ids  # URL parameter (default: :ids)
end
```

**Bulk action methods:**

```ruby
table.bulk_actions                    # Array of defined bulk actions
table.selected_bulk_action_record_ids # IDs from params
table.selected_bulk_action_record?(record)  # Check if record is selected
```

**Disable bulk actions:**

```ruby
self.skip_bulk_actions = true
```

## Configuration

Configure class-level defaults that apply to all instances:

```ruby
class ApplicationTable < RapidTable::Base
  extend RapidTable::DSL

  # Export defaults
  self.csv_column_separator = ","
  self.export_batch_size = 1000
  self.export_formats = [:csv, :json]

  # Search defaults
  self.search_param = :q

  # Sorting defaults
  self.sort_column_param = :sort
  self.sort_order_param = :dir
end
```

Override at the instance level:

```ruby
UsersTable.new(@users,
  skip_export: true,
  skip_search: true,
  per_page: 50
)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RapidTable project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).
