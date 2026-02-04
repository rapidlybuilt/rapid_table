class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include I18nSupport
  include MockTablesSupport

  driven_by :cuprite_desktop

  def refresh_page
    page.execute_script("window.location.reload()")
  end

  def remove_field(field_name)
    el = page.find_field(field_name)
    page.execute_script("arguments[0].remove()", el)
  end

  # Custom assertion to check if content appears before other content
  def assert_appears_before(earlier_content, later_content, msg = nil)
    earlier_index = page.body.index(earlier_content)
    later_index = page.body.index(later_content)

    if earlier_index.nil? && later_index.nil?
      flunk(msg || "Neither '#{earlier_content}' nor '#{later_content}' were found in the page")
    elsif earlier_index.nil?
      flunk(msg || "Expected content '#{earlier_content}' was not found in the page")
    elsif later_index.nil?
      flunk(msg || "Expected content '#{later_content}' was not found in the page")
    else
      assert earlier_index < later_index, msg || "Expected '#{earlier_content}' to appear before '#{later_content}' in the page"
    end
  end
end

class NoJsSystemTestCase < ActionDispatch::SystemTestCase
  include I18nSupport
  include MockTablesSupport

  driven_by :rack_test
end
