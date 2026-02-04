Rails.application.routes.draw do
  get "mocked_table", to: "mocked_tables#show", as: :mocked_table
  post "mocked_table/bulk_action", to: "mocked_tables#bulk_action", as: :mocked_table_bulk_action
end
